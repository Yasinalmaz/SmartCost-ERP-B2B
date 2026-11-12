"""SmartCost ERP & B2B Portalı - FastAPI sunucusu.

Çalıştırma (backend klasöründeyken):  python -m uvicorn main:app --reload
Dokümantasyon / test ekranı:          http://127.0.0.1:8000/docs

Demo hesaplar:
    Yönetici : admin@smartcost.com       / admin123
    Müşteri  : satinalma@yildizotel.com  / 123456
"""
import hashlib
import hmac
from collections import defaultdict
from datetime import datetime
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel, Field
from sqlalchemy import func
from sqlalchemy.orm import Session

from database import (SIPARIS_DURUMLARI, Kullanici, SessionLocal, TeklifArsivi,
                      TeklifKalemi, Urun, get_db, sifre_ozeti, veritabanini_hazirla)
from nlp import Ayristirici

# ------------------------------------------------------------------ iş kuralları
OPERASYON_ORANI = 0.15   # işçilik / operasyon gideri
KAR_ORANI = 0.20         # şirket kâr marjı
KRITIK_STOK = 20
GIZLI_ANAHTAR = b"smartcost-gedik-2026"   # oturum anahtarlarını imzalamak için

app = FastAPI(title="SmartCost ERP & B2B Portalı", version="2.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

veritabanini_hazirla()
_db = SessionLocal()
ayristirici = Ayristirici(_db.query(Urun).all())
_db.close()


# ------------------------------------------------------------------ şemalar
class GirisIstegi(BaseModel):
    eposta: str
    sifre: str


class KayitIstegi(BaseModel):
    eposta: str
    sifre: str = Field(min_length=6)
    ad_soyad: str
    firma: str


class MetinIstegi(BaseModel):
    talep: str


class SepetKalemi(BaseModel):
    urun_id: int
    adet: int = Field(gt=0)


class SepetIstegi(BaseModel):
    kalemler: list[SepetKalemi]
    talep: str = ""          # akıllı siparişten geldiyse orijinal metin


class UrunGuncelle(BaseModel):
    birim_fiyati: Optional[float] = Field(default=None, gt=0)
    stok_adedi: Optional[int] = Field(default=None, ge=0)


class DurumGuncelle(BaseModel):
    durum: str


class TalepIstegi(BaseModel):     # eski (tek adımlı) uç noktalar için
    musteri_adi: str
    talep: str


# ------------------------------------------------------------------ oturum
def _imza(kullanici_id: int) -> str:
    return hmac.new(GIZLI_ANAHTAR, str(kullanici_id).encode(), hashlib.sha256).hexdigest()[:32]


def _token(k: Kullanici) -> str:
    return f"{k.id}.{_imza(k.id)}"


def aktif_kullanici(authorization: str = Header(default=""), db: Session = Depends(get_db)) -> Kullanici:
    try:
        kid, imza = authorization.removeprefix("Bearer ").split(".")
        assert hmac.compare_digest(imza, _imza(int(kid)))
        k = db.get(Kullanici, int(kid))
        assert k is not None
        return k
    except Exception:
        raise HTTPException(401, "Oturum geçersiz, lütfen tekrar giriş yapın.")


def yonetici(k: Kullanici = Depends(aktif_kullanici)) -> Kullanici:
    if k.rol != "yonetici":
        raise HTTPException(403, "Bu işlem için yönetici yetkisi gerekir.")
    return k


def _kullanici_json(k: Kullanici) -> dict:
    return {"id": k.id, "eposta": k.eposta, "ad_soyad": k.ad_soyad, "firma": k.firma, "rol": k.rol}


# ------------------------------------------------------------------ yardımcılar
def _urun_json(u: Urun) -> dict:
    return {"id": u.id, "kategori": u.kategori, "model": u.model, "ebat": u.ebat,
            "urun_adi": u.urun_adi, "liste_fiyati": u.birim_fiyati,
            "indirimli_fiyat": u.indirimli_fiyat, "fiyat": u.gecerli_fiyat, "stok": u.stok_adedi}


def _hesapla(kalemler: list[tuple[int, int]], db: Session) -> dict:
    """(urun_id, adet) listesinden maliyet dökümü üretir. Veritabanını değiştirmez."""
    birlesik: dict[int, int] = defaultdict(int)
    for urun_id, adet in kalemler:
        birlesik[urun_id] += adet

    satirlar, stok_hatalari = [], []
    for urun_id, adet in birlesik.items():
        u = db.get(Urun, urun_id)
        if not u:
            raise HTTPException(404, f"Ürün bulunamadı: {urun_id}")
        tutar = round(u.gecerli_fiyat * adet, 2)
        satirlar.append({**_urun_json(u), "urun_id": u.id, "adet": adet,
                         "birim_fiyat": u.gecerli_fiyat, "tutar": tutar})
        if adet > u.stok_adedi:
            stok_hatalari.append(f"{u.urun_adi}: istenen {adet}, stokta {u.stok_adedi}")

    malzeme = round(sum(s["tutar"] for s in satirlar), 2)
    operasyon = round(malzeme * OPERASYON_ORANI, 2)
    ara_toplam = round(malzeme + operasyon, 2)
    kar = round(ara_toplam * KAR_ORANI, 2)
    return {
        "kalemler": satirlar, "stok_hatalari": stok_hatalari,
        "malzeme_toplami": malzeme, "operasyon_gideri": operasyon, "ara_toplam": ara_toplam,
        "kar_marji": kar, "genel_toplam": round(ara_toplam + kar, 2),
        "operasyon_orani": OPERASYON_ORANI, "kar_orani": KAR_ORANI,
    }


def _siparis_olustur(hesap: dict, musteri_adi: str, talep: str, kullanici_id, db: Session) -> TeklifArsivi:
    if not hesap["kalemler"]:
        raise HTTPException(422, "Sepet boş.")
    if hesap["stok_hatalari"]:
        raise HTTPException(409, {"mesaj": "Yetersiz stok", "detay": hesap["stok_hatalari"]})
    t = TeklifArsivi(
        kullanici_id=kullanici_id, musteri_adi=musteri_adi, talep=talep or "Sepet siparişi",
        malzeme_toplami=hesap["malzeme_toplami"], operasyon_gideri=hesap["operasyon_gideri"],
        kar_marji=hesap["kar_marji"], toplam_tutar=hesap["genel_toplam"],
    )
    for k in hesap["kalemler"]:
        db.get(Urun, k["urun_id"]).stok_adedi -= k["adet"]
        t.kalemler.append(TeklifKalemi(urun_id=k["urun_id"], urun_adi=k["urun_adi"], adet=k["adet"],
                                       birim_fiyat=k["birim_fiyat"], tutar=k["tutar"]))
    db.add(t)
    db.flush()
    t.seri_no = f"SYN-{datetime.now().year}-{t.id:04d}"
    db.commit()
    return t


def _siparis_json(t: TeklifArsivi, detay: bool = False) -> dict:
    d = {"id": t.id, "seri_no": t.seri_no, "musteri_adi": t.musteri_adi, "durum": t.durum,
         "toplam_tutar": t.toplam_tutar, "kalem_sayisi": len(t.kalemler),
         "urun_adedi": sum(k.adet for k in t.kalemler),
         "tarih": t.tarih.isoformat(timespec="seconds")}
    if detay:
        d.update({
            "talep": t.talep, "malzeme_toplami": t.malzeme_toplami,
            "operasyon_gideri": t.operasyon_gideri, "kar_marji": t.kar_marji,
            "kalemler": [{"urun_id": k.urun_id, "urun_adi": k.urun_adi, "adet": k.adet,
                          "birim_fiyat": k.birim_fiyat, "tutar": k.tutar} for k in t.kalemler],
        })
    return d


# ================================================================== GENEL
@app.get("/")
def ana_sayfa():
    return {"mesaj": "SmartCost ERP çalışıyor. Test için /docs adresine gidin."}


@app.post("/giris")
def giris(istek: GirisIstegi, db: Session = Depends(get_db)):
    k = db.query(Kullanici).filter(Kullanici.eposta == istek.eposta.strip().lower()).first()
    if not k or k.sifre_hash != sifre_ozeti(istek.sifre):
        raise HTTPException(401, "E-posta veya şifre hatalı.")
    return {"token": _token(k), "kullanici": _kullanici_json(k)}


@app.post("/kayit")
def kayit(istek: KayitIstegi, db: Session = Depends(get_db)):
    eposta = istek.eposta.strip().lower()
    if db.query(Kullanici).filter(Kullanici.eposta == eposta).first():
        raise HTTPException(409, "Bu e-posta ile kayıtlı bir hesap var.")
    k = Kullanici(eposta=eposta, sifre_hash=sifre_ozeti(istek.sifre), ad_soyad=istek.ad_soyad,
                  firma=istek.firma, rol="musteri")
    db.add(k)
    db.commit()
    return {"token": _token(k), "kullanici": _kullanici_json(k)}


@app.get("/kategoriler")
def kategoriler(db: Session = Depends(get_db)):
    rows = db.query(Urun.kategori, func.count(func.distinct(Urun.model))).group_by(Urun.kategori).all()
    return sorted([{"kategori": k, "model_sayisi": n} for k, n in rows], key=lambda x: -x["model_sayisi"])


@app.get("/katalog")
def katalog(kategori: str = "", q: str = "", siralama: str = "onerilen", db: Session = Depends(get_db)):
    """Ürünleri model bazında gruplar; her modelin ebat seçenekleri 'varyantlar' içindedir."""
    sorgu = db.query(Urun)
    if kategori:
        sorgu = sorgu.filter(Urun.kategori == kategori.upper())
    if q:
        for kelime in q.upper().split():
            sorgu = sorgu.filter(Urun.urun_adi.like(f"%{kelime}%"))

    gruplar: dict[tuple, dict] = {}
    for u in sorgu.order_by(Urun.id).all():
        anahtar = (u.kategori, u.model)
        g = gruplar.setdefault(anahtar, {"anahtar": f"{u.kategori}|{u.model}", "kategori": u.kategori,
                                         "model": u.model, "varyantlar": []})
        g["varyantlar"].append({"id": u.id, "ebat": u.ebat, "urun_adi": u.urun_adi,
                                "liste_fiyati": u.birim_fiyati, "indirimli_fiyat": u.indirimli_fiyat,
                                "fiyat": u.gecerli_fiyat, "stok": u.stok_adedi})
    sonuc = []
    for g in gruplar.values():
        fiyatlar = [v["fiyat"] for v in g["varyantlar"]]
        g["min_fiyat"], g["max_fiyat"] = min(fiyatlar), max(fiyatlar)
        g["kampanyali"] = any(v["indirimli_fiyat"] for v in g["varyantlar"])
        g["toplam_stok"] = sum(v["stok"] for v in g["varyantlar"])
        sonuc.append(g)
    if siralama == "artan":
        sonuc.sort(key=lambda g: g["min_fiyat"])
    elif siralama == "azalan":
        sonuc.sort(key=lambda g: -g["min_fiyat"])
    elif siralama == "ad":
        sonuc.sort(key=lambda g: g["model"])
    return sonuc


@app.get("/urunler")
def urunler(q: str = "", kategori: str = "", limit: int = 50, db: Session = Depends(get_db)):
    sorgu = db.query(Urun)
    if kategori:
        sorgu = sorgu.filter(Urun.kategori == kategori.upper())
    if q:
        sorgu = sorgu.filter(Urun.urun_adi.like(f"%{q.upper()}%"))
    return [_urun_json(u) for u in sorgu.limit(limit).all()]


# ================================================================== MÜŞTERİ
@app.post("/metin-ayristir")
def metin_ayristir(istek: MetinIstegi, db: Session = Depends(get_db)):
    """Akıllı sipariş: serbest metni sepete eklenebilir kalemlere çevirir."""
    sonuc = ayristirici.ayristir(istek.talep)
    kalemler = []
    for k in sonuc["kalemler"]:
        u = db.get(Urun, k["urun_id"])
        kalemler.append({**_urun_json(u), "adet": k["adet"], "kaynak_metin": k["kaynak_metin"]})
    return {"kalemler": kalemler, "anlasilmayan": sonuc["anlasilmayan"]}


@app.post("/sepet/teklif")
def sepet_teklif(istek: SepetIstegi, db: Session = Depends(get_db)):
    """1. aşama: ön izleme. Stoktan hiçbir şey düşmez."""
    return _hesapla([(k.urun_id, k.adet) for k in istek.kalemler], db)


@app.post("/sepet/onayla")
def sepet_onayla(istek: SepetIstegi, k: Kullanici = Depends(aktif_kullanici), db: Session = Depends(get_db)):
    """2. aşama: stok düşülür, sipariş arşive yazılır."""
    hesap = _hesapla([(x.urun_id, x.adet) for x in istek.kalemler], db)
    t = _siparis_olustur(hesap, k.firma or k.ad_soyad, istek.talep, k.id, db)
    return _siparis_json(t, detay=True)


@app.get("/siparislerim")
def siparislerim(k: Kullanici = Depends(aktif_kullanici), db: Session = Depends(get_db)):
    q = db.query(TeklifArsivi).filter(TeklifArsivi.kullanici_id == k.id).order_by(TeklifArsivi.id.desc())
    return [_siparis_json(t, detay=True) for t in q.all()]


# ---- eski tek adımlı uç noktalar (Swagger testleri ve rapordaki tanımlar için korunuyor)
@app.post("/teklif-hazirla/")
def teklif_hazirla(istek: TalepIstegi, db: Session = Depends(get_db)):
    sonuc = ayristirici.ayristir(istek.talep)
    if not sonuc["kalemler"]:
        raise HTTPException(422, "Metinde tanınan ürün bulunamadı.")
    hesap = _hesapla([(k["urun_id"], k["adet"]) for k in sonuc["kalemler"]], db)
    return {**hesap, "anlasilmayan": sonuc["anlasilmayan"], "musteri_adi": istek.musteri_adi}


@app.post("/siparis-onayla/")
def siparis_onayla(istek: TalepIstegi, db: Session = Depends(get_db)):
    sonuc = ayristirici.ayristir(istek.talep)
    if not sonuc["kalemler"]:
        raise HTTPException(422, "Metinde tanınan ürün bulunamadı.")
    hesap = _hesapla([(k["urun_id"], k["adet"]) for k in sonuc["kalemler"]], db)
    t = _siparis_olustur(hesap, istek.musteri_adi, istek.talep, None, db)
    return {"mesaj": "Sipariş onaylandı", "siparis_id": t.id, "seri_no": t.seri_no,
            "genel_toplam": t.toplam_tutar}


@app.get("/arsiv-pdf-indir/{siparis_id}")
def arsiv_pdf_indir(siparis_id: int, token: str = "", db: Session = Depends(get_db)):
    """PDF tarayıcıda yeni sekmede açıldığı için oturum anahtarı ?token= ile gelir."""
    from pdf_olustur import teklif_pdf
    k = aktif_kullanici(f"Bearer {token}", db)
    t = db.get(TeklifArsivi, siparis_id)
    if not t:
        raise HTTPException(404, "Sipariş bulunamadı")
    if k.rol != "yonetici" and t.kullanici_id != k.id:
        raise HTTPException(403, "Bu siparişi görüntüleme yetkiniz yok.")
    return Response(teklif_pdf(t), media_type="application/pdf",
                    headers={"Content-Disposition": f'inline; filename="{t.seri_no}.pdf"'})


# ================================================================== YÖNETİCİ
@app.get("/admin/ozet")
def admin_ozet(_: Kullanici = Depends(yonetici), db: Session = Depends(get_db)):
    siparisler = db.query(TeklifArsivi).filter(TeklifArsivi.durum != "İptal").all()
    ciro = round(sum(t.toplam_tutar for t in siparisler), 2)

    kategori_satis: dict[str, float] = defaultdict(float)
    urun_satis: dict[str, int] = defaultdict(int)
    gunluk: dict[str, float] = defaultdict(float)
    for t in siparisler:
        gunluk[t.tarih.strftime("%Y-%m-%d")] += t.toplam_tutar
        for k in t.kalemler:
            u = db.get(Urun, k.urun_id)
            kategori_satis[u.kategori if u else "DIGER"] += k.tutar
            urun_satis[k.urun_adi] += k.adet

    kritik = db.query(Urun).filter(Urun.stok_adedi < KRITIK_STOK).order_by(Urun.stok_adedi).all()
    son = db.query(TeklifArsivi).order_by(TeklifArsivi.id.desc()).limit(8).all()
    stok_degeri = db.query(func.sum(Urun.birim_fiyati * Urun.stok_adedi)).scalar() or 0
    return {
        "toplam_ciro": ciro,
        "siparis_sayisi": len(siparisler),
        "ortalama_sepet": round(ciro / len(siparisler), 2) if siparisler else 0,
        "musteri_sayisi": db.query(Kullanici).filter(Kullanici.rol == "musteri").count(),
        "urun_sayisi": db.query(Urun).count(),
        "stok_degeri": round(stok_degeri, 2),
        "bekleyen_siparis": sum(1 for t in siparisler if t.durum in ("Onaylandı", "Hazırlanıyor")),
        "kritik_stok": [_urun_json(u) for u in kritik[:50]],
        "kritik_stok_sayisi": len(kritik),
        "kategori_satis": sorted([{"kategori": k, "tutar": round(v, 2)} for k, v in kategori_satis.items()],
                                 key=lambda x: -x["tutar"]),
        "en_cok_satan": sorted([{"urun_adi": k, "adet": v} for k, v in urun_satis.items()],
                               key=lambda x: -x["adet"])[:5],
        "gunluk_ciro": [{"gun": g, "tutar": round(v, 2)} for g, v in sorted(gunluk.items())][-14:],
        "son_siparisler": [_siparis_json(t) for t in son],
    }


@app.get("/admin/siparisler")
def admin_siparisler(durum: str = "", q: str = "", _: Kullanici = Depends(yonetici), db: Session = Depends(get_db)):
    sorgu = db.query(TeklifArsivi)
    if durum:
        sorgu = sorgu.filter(TeklifArsivi.durum == durum)
    if q:
        sorgu = sorgu.filter((TeklifArsivi.musteri_adi.like(f"%{q}%")) | (TeklifArsivi.seri_no.like(f"%{q}%")))
    return [_siparis_json(t, detay=True) for t in sorgu.order_by(TeklifArsivi.id.desc()).all()]


@app.patch("/admin/siparisler/{siparis_id}")
def admin_siparis_durum(siparis_id: int, istek: DurumGuncelle, _: Kullanici = Depends(yonetici),
                        db: Session = Depends(get_db)):
    if istek.durum not in SIPARIS_DURUMLARI:
        raise HTTPException(422, f"Geçerli durumlar: {', '.join(SIPARIS_DURUMLARI)}")
    t = db.get(TeklifArsivi, siparis_id)
    if not t:
        raise HTTPException(404, "Sipariş bulunamadı")
    if istek.durum == "İptal" and t.durum != "İptal":          # iptalde stok geri eklenir
        for k in t.kalemler:
            db.get(Urun, k.urun_id).stok_adedi += k.adet
    t.durum = istek.durum
    db.commit()
    return _siparis_json(t, detay=True)


@app.get("/admin/siparis-durumlari")
def siparis_durumlari():
    return SIPARIS_DURUMLARI


@app.get("/admin/urunler")
def admin_urunler(q: str = "", kategori: str = "", sadece_kritik: bool = False, sayfa: int = 1,
                  boyut: int = 25, _: Kullanici = Depends(yonetici), db: Session = Depends(get_db)):
    sorgu = db.query(Urun)
    if kategori:
        sorgu = sorgu.filter(Urun.kategori == kategori.upper())
    if q:
        for kelime in q.upper().split():
            sorgu = sorgu.filter(Urun.urun_adi.like(f"%{kelime}%"))
    if sadece_kritik:
        sorgu = sorgu.filter(Urun.stok_adedi < KRITIK_STOK)
    toplam = sorgu.count()
    satirlar = sorgu.order_by(Urun.kategori, Urun.model, Urun.id).offset((sayfa - 1) * boyut).limit(boyut).all()
    return {"toplam": toplam, "sayfa": sayfa, "boyut": boyut, "urunler": [_urun_json(u) for u in satirlar]}


@app.patch("/admin/urunler/{urun_id}")
def admin_urun_guncelle(urun_id: int, istek: UrunGuncelle, _: Kullanici = Depends(yonetici),
                        db: Session = Depends(get_db)):
    u = db.get(Urun, urun_id)
    if not u:
        raise HTTPException(404, "Ürün bulunamadı")
    if istek.birim_fiyati is not None:
        u.birim_fiyati = istek.birim_fiyati
        u.indirimli_fiyat = None
    if istek.stok_adedi is not None:
        u.stok_adedi = istek.stok_adedi
    db.commit()
    return _urun_json(u)
