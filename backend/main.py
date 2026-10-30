from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from sqlalchemy.orm import Session
from pydantic import BaseModel
from fpdf import FPDF
import datetime
import re

from backend import database

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class HammaddeEkle(BaseModel):
    isim: str
    birim_fiyati: float
    stok_adedi: int = 50

class SiparisMetni(BaseModel):
    musteri_adi: str
    metin: str

class TeklifVerisi(BaseModel):
    musteri_adi: str
    orijinal_talep: str
    hesaplanan_detaylar: list
    maliyetler: dict
    genel_toplam: float

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- ÇOKLU ÜRÜN VE DOĞAL DİL ALGILAMA MOTORU ---
def coklu_metin_analiz_et(metin: str, tum_stoklar: list):
    def tr_kucuk(m: str):
        harfler = {'I': 'ı', 'İ': 'i', 'Ç': 'ç', 'Ş': 'ş', 'Ö': 'ö', 'Ü': 'ü', 'Ğ': 'ğ'}
        for b, k in harfler.items():
            m = m.replace(b, k)
        return m.lower().strip()

    temiz_metin = tr_kucuk(metin)
    bulunan_kalemler = []

    sirali_stoklar = sorted(tum_stoklar, key=lambda x: len(x.isim), reverse=True)
    
    for stok in sirali_stoklar:
        stok_adi = tr_kucuk(stok.isim)
        if not stok_adi:
            continue

        desen1 = rf'(\d+)\s*(?:adet|tane|kg|mt|metre|paket|kutu|koli)?\s*{re.escape(stok_adi)}\b'
        desen2 = rf'\b{re.escape(stok_adi)}\s*(\d+)\s*(?:adet|tane|kg|mt|metre|paket|kutu|koli)?'

        for desen in [desen1, desen2]:
            for eslesme in list(re.finditer(desen, temiz_metin)):
                bas, son = eslesme.span()
                if temiz_metin[bas:son].strip():
                    adet = int(eslesme.group(1))
                    bulunan_kalemler.append({
                        "isim": stok.isim,
                        "adet": adet,
                        "db_stok": stok,
                        "pozisyon": bas
                    })
                    temiz_metin = temiz_metin[:bas] + (" " * (son - bas)) + temiz_metin[son:]

    gereksiz_kelimeler = {
        'adet', 'tane', 'kg', 'mt', 'metre', 'paket', 'kutu', 'koli',
        've', 'ile', 'veya', 'lazım', 'lazim', 'istiyorum', 'isterim',
        'acil', 'şantiyeye', 'santiyeye', 'patron', 'istedi', 'için',
        'icin', 'bir', 'de', 'da', 'lütfen', 'lutfen', 'gönderin'
    }
    genel_desen = r'(\d+)\s*(?:adet|tane|kg|mt|metre|paket|kutu|koli)?\s+([a-zçğıöşü0-9]+(?:\s+[a-zçğıöşü0-9]+)?)'
    
    for m in re.finditer(genel_desen, temiz_metin):
        adet = int(m.group(1))
        aday_kelimeler = [k for k in m.group(2).split() if k not in gereksiz_kelimeler]
        if aday_kelimeler:
            aday_isim = " ".join(aday_kelimeler)
            bulunan_kalemler.append({
                "isim": aday_isim,
                "adet": adet,
                "db_stok": None,
                "pozisyon": m.start()
            })

    bulunan_kalemler.sort(key=lambda x: x["pozisyon"])
    return bulunan_kalemler

# --- ORTAK PDF OLUŞTURUCU FONKSİYON ---
def pdf_belgesi_uret(
    musteri_adi: str,
    orijinal_talep: str,
    hesaplanan_detaylar: list,
    maliyetler: dict,
    genel_toplam: float,
    tarih_str: str = None,
    teklif_no: str = "SYN-2026-001"
) -> bytes:
    pdf = FPDF()
    pdf.add_page()
    
    def tr(metin):
        tr_map = {'ç':'c', 'ğ':'g', 'ı':'i', 'ö':'o', 'ş':'s', 'ü':'u', 'Ç':'C', 'Ğ':'G', 'İ':'I', 'Ö':'O', 'Ş':'S', 'Ü':'U'}
        for k, v in tr_map.items():
            metin = str(metin).replace(k, v)
        return metin

    pdf.set_fill_color(30, 58, 138) 
    pdf.set_text_color(255, 255, 255)
    pdf.set_font("helvetica", "B", 16)
    pdf.cell(0, 15, tr(" SYNTAX ÜRETİM SİSTEMLERİ - RESMİ SATIŞ TEKLİFİ "), border=0, ln=1, align="C", fill=True)
    pdf.ln(5)
    
    if not tarih_str:
        tarih_str = datetime.datetime.now().strftime("%d/%m/%Y")
        
    pdf.set_text_color(50, 50, 50)
    pdf.set_font("helvetica", "", 10)
    
    pdf.cell(100, 6, tr(f"Müşteri: {musteri_adi}"), border=0, ln=0)
    pdf.cell(0, 6, tr(f"Tarih: {tarih_str}"), border=0, ln=1, align="R")
    pdf.cell(100, 6, tr("Proje: Yapay Zekâ Destekli Maliyetlendirme"), border=0, ln=0)
    pdf.cell(0, 6, tr(f"Teklif No: {teklif_no}"), border=0, ln=1, align="R")
    
    pdf.set_draw_color(200, 200, 200)
    pdf.line(10, pdf.get_y()+2, 200, pdf.get_y()+2)
    pdf.ln(8)
    
    pdf.set_font("helvetica", "B", 11)
    pdf.cell(0, 6, tr("Talep Özeti:"), ln=1)
    pdf.set_font("helvetica", "I", 10)
    pdf.multi_cell(0, 6, tr(orijinal_talep))
    pdf.ln(5)

    pdf.set_fill_color(240, 240, 240)
    pdf.set_text_color(0, 0, 0)
    pdf.set_font("helvetica", "B", 10)
    pdf.cell(80, 8, tr("Malzeme / Hizmet"), border=1, fill=True, align="L")
    pdf.cell(30, 8, tr("Miktar"), border=1, fill=True, align="C")
    pdf.cell(40, 8, tr("Birim Fiyat"), border=1, fill=True, align="C")
    pdf.cell(40, 8, tr("Toplam"), border=1, ln=1, fill=True, align="C")
    
    pdf.set_font("helvetica", "", 10)
    for kalem in hesaplanan_detaylar:
        if "uyari" not in kalem:
            pdf.cell(80, 8, tr(kalem['malzeme']), border=1, align="L")
            pdf.cell(30, 8, f"{kalem['adet']} Adet", border=1, align="C")
            pdf.cell(40, 8, f"{kalem['birim_fiyat']} TL", border=1, align="R")
            pdf.cell(40, 8, f"{kalem['toplam_tutar']} TL", border=1, ln=1, align="R")
            
    pdf.ln(5)
    pdf.set_font("helvetica", "", 10)
    pdf.cell(110, 6, "", border=0, align="R")
    pdf.cell(40, 6, tr("Saf Malzeme:"), border=0, align="R")
    pdf.cell(40, 6, f"{maliyetler['malzeme']} TL", border=0, ln=1, align="R")
    pdf.cell(110, 6, "", border=0, align="R")
    pdf.cell(40, 6, tr("İşçilik & Amort. (%15):"), border=0, align="R")
    pdf.cell(40, 6, f"{maliyetler['iscilik']} TL", border=0, ln=1, align="R")
    pdf.cell(110, 6, "", border=0, align="R")
    pdf.cell(40, 6, tr("Kâr Marjı (%20):"), border=0, align="R")
    pdf.cell(40, 6, f"{maliyetler['kar']} TL", border=0, ln=1, align="R")
    pdf.line(120, pdf.get_y()+2, 200, pdf.get_y()+2)
    pdf.ln(4)
    pdf.set_font("helvetica", "B", 12)
    pdf.set_text_color(30, 58, 138)
    pdf.cell(110, 8, "", border=0, align="R")
    pdf.cell(40, 8, tr("GENEL TOPLAM:"), border=0, align="R")
    pdf.cell(40, 8, f"{genel_toplam} TL", border=0, ln=1, align="R")
    
    pdf.set_y(-30)
    pdf.set_text_color(120, 120, 120)
    pdf.set_font("helvetica", "I", 8)
    pdf.cell(0, 4, tr("Bu belge Syntax Uretim Sistemleri yapay zeka motoru tarafindan otomatik hazirlanmistir."), align="C", ln=1)
    pdf.cell(0, 4, tr("Fiyatlara KDV dahil degildir. Teklif gecerlilik suresi 15 gundur."), align="C", ln=1)
    
    return bytes(pdf.output())

@app.post("/hammadde/")
def hammadde_ekle(hammadde: HammaddeEkle, db: Session = Depends(get_db)):
    yeni_hammadde = database.Hammadde(
        isim=hammadde.isim,
        birim_fiyati=hammadde.birim_fiyati,
        stok_adedi=hammadde.stok_adedi
    )
    db.add(yeni_hammadde)
    db.commit()
    return {"mesaj": "Sisteme eklendi!"}

@app.get("/hammadde/")
def hammaddeleri_getir(db: Session = Depends(get_db)):
    return db.query(database.Hammadde).all()

@app.delete("/hammadde/{hammadde_id}")
def hammadde_sil(hammadde_id: int, db: Session = Depends(get_db)):
    malzeme = db.query(database.Hammadde).filter(database.Hammadde.id == hammadde_id).first()
    if malzeme:
        db.delete(malzeme)
        db.commit()
        return {"mesaj": "Silindi!"}
    return {"hata": "Bulunamadı"}

@app.put("/hammadde/stok/{hammadde_id}")
def stok_guncelle(hammadde_id: int, islem: str, miktar: int = 1, db: Session = Depends(get_db)):
    malzeme = db.query(database.Hammadde).filter(database.Hammadde.id == hammadde_id).first()
    if malzeme:
        if islem == "arttir": 
            malzeme.stok_adedi += miktar
        elif islem == "azalt":
            if malzeme.stok_adedi >= miktar: 
                malzeme.stok_adedi -= miktar
            else: 
                malzeme.stok_adedi = 0
        db.commit()
        return {"mesaj": "Güncellendi"}
    return {"hata": "Bulunamadı"}

@app.post("/teklif-hazirla/")
def teklif_hazirla(siparis: SiparisMetni, db: Session = Depends(get_db)):
    tum_stoklar = db.query(database.Hammadde).all()
    analiz_sonucu = coklu_metin_analiz_et(siparis.metin, tum_stoklar)
    
    if not analiz_sonucu:
        return {"hata": "Sipariş anlaşılamadı. Lütfen miktarı ve ürün adını belirtin (Örn: 20 adet aa ve 30 adet bbb)."}

    toplam_malzeme = 0
    detaylar = []

    for kalem in analiz_sonucu:
        db_malzeme = kalem["db_stok"]
        adet = kalem["adet"]
        if db_malzeme and db_malzeme.stok_adedi < adet:
            return {
                "hata": f"Stok Yetersiz! '{db_malzeme.isim}' ürünü için depoda sadece {db_malzeme.stok_adedi} adet bulunuyor (Talep edilen: {adet})."
            }

    for kalem in analiz_sonucu:
        db_malzeme = kalem["db_stok"]
        adet = kalem["adet"]
        
        if db_malzeme:
            kalem_tutari = round(db_malzeme.birim_fiyati * adet, 2)
            toplam_malzeme += kalem_tutari
            detaylar.append({
                "malzeme": db_malzeme.isim,
                "adet": adet,
                "birim_fiyat": db_malzeme.birim_fiyati,
                "toplam_tutar": kalem_tutari
            })
        else:
            detaylar.append({
                "malzeme": kalem["isim"],
                "uyari": "Stokta yok!"
            })

    iscilik_amortisman = toplam_malzeme * 0.15
    kar_marji = (toplam_malzeme + iscilik_amortisman) * 0.20
    genel_toplam = toplam_malzeme + iscilik_amortisman + kar_marji

    return {
        "musteri_adi": siparis.musteri_adi,
        "orijinal_talep": siparis.metin,
        "hesaplanan_detaylar": detaylar,
        "maliyetler": {
            "malzeme": round(toplam_malzeme, 2),
            "iscilik": round(iscilik_amortisman, 2),
            "kar": round(kar_marji, 2)
        },
        "genel_toplam": round(genel_toplam, 2)
    }

@app.post("/siparis-onayla/")
def siparis_onayla(veri: TeklifVerisi, db: Session = Depends(get_db)):
    onaylanan_kalem_sayisi = 0

    for kalem in veri.hesaplanan_detaylar:
        if "uyari" not in kalem:
            db_malzeme = db.query(database.Hammadde).filter(database.Hammadde.isim == kalem["malzeme"]).first()
            if not db_malzeme or db_malzeme.stok_adedi < kalem["adet"]:
                return {"hata": f"'{kalem['malzeme']}' ürünü için güncel stok yetersiz!"}

    for kalem in veri.hesaplanan_detaylar:
        if "uyari" not in kalem:
            db_malzeme = db.query(database.Hammadde).filter(database.Hammadde.isim == kalem["malzeme"]).first()
            if db_malzeme:
                db_malzeme.stok_adedi -= int(kalem["adet"])
                onaylanan_kalem_sayisi += 1

    if onaylanan_kalem_sayisi == 0:
        return {"hata": "Onaylanacak geçerli bir stoklu ürün bulunamadı!"}

    yeni_kayit = database.TeklifArsivi(
        musteri_adi=veri.musteri_adi,
        talep=veri.orijinal_talep,
        toplam_tutar=round(veri.genel_toplam, 2),
        tarih=datetime.datetime.now()
    )
    db.add(yeni_kayit)
    db.commit()

    return {"mesaj": "Sipariş başarıyla onaylandı, stoktan düşüldü ve arşive kaydedildi!"}

@app.post("/pdf-indir/")
def pdf_indir(veri: TeklifVerisi):
    pdf_bytes = pdf_belgesi_uret(
        musteri_adi=veri.musteri_adi,
        orijinal_talep=veri.orijinal_talep,
        hesaplanan_detaylar=veri.hesaplanan_detaylar,
        maliyetler=veri.maliyetler,
        genel_toplam=veri.genel_toplam
    )
    return Response(content=pdf_bytes, media_type="application/pdf")

# --- YENİ: GEÇMİŞ SİPARİŞİN PDF BELGESİNİ YENİDEN OLUŞTURMA ROTASI ---
@app.get("/arsiv-pdf-indir/{kayit_id}")
def arsiv_pdf_indir(kayit_id: int, db: Session = Depends(get_db)):
    kayit = db.query(database.TeklifArsivi).filter(database.TeklifArsivi.id == kayit_id).first()
    if not kayit:
        return Response(content=b"Kayit bulunamadi", status_code=404)

    tum_stoklar = db.query(database.Hammadde).all()
    analiz_sonucu = coklu_metin_analiz_et(kayit.talep, tum_stoklar)

    toplam_malzeme = 0
    detaylar = []

    for kalem in analiz_sonucu:
        db_malzeme = kalem["db_stok"]
        adet = kalem["adet"]
        if db_malzeme:
            kalem_tutari = round(db_malzeme.birim_fiyati * adet, 2)
            toplam_malzeme += kalem_tutari
            detaylar.append({
                "malzeme": db_malzeme.isim,
                "adet": adet,
                "birim_fiyat": db_malzeme.birim_fiyati,
                "toplam_tutar": kalem_tutari
            })

    # Eğer ürün sonradan stoktan silindiyse bile kayıtlı toplam tutardan geriye dönük hesapla
    if not detaylar:
        saf_malzeme = round(kayit.toplam_tutar / 1.38, 2)
        iscilik = round(saf_malzeme * 0.15, 2)
        kar = round(kayit.toplam_tutar - saf_malzeme - iscilik, 2)
        detaylar.append({
            "malzeme": kayit.talep,
            "adet": 1,
            "birim_fiyat": saf_malzeme,
            "toplam_tutar": saf_malzeme
        })
        maliyetler = {"malzeme": saf_malzeme, "iscilik": iscilik, "kar": kar}
    else:
        iscilik = round(toplam_malzeme * 0.15, 2)
        kar = round((toplam_malzeme + iscilik) * 0.20, 2)
        maliyetler = {"malzeme": round(toplam_malzeme, 2), "iscilik": iscilik, "kar": kar}

    tarih_str = kayit.tarih.strftime("%d/%m/%Y %H:%M") if kayit.tarih else ""
    teklif_no = f"SYN-2026-{kayit.id:04d}"

    pdf_bytes = pdf_belgesi_uret(
        musteri_adi=kayit.musteri_adi or "Bireysel Müşteri",
        orijinal_talep=kayit.talep,
        hesaplanan_detaylar=detaylar,
        maliyetler=maliyetler,
        genel_toplam=round(kayit.toplam_tutar, 2),
        tarih_str=tarih_str,
        teklif_no=teklif_no
    )
    return Response(content=pdf_bytes, media_type="application/pdf")

@app.get("/teklif-arsivi/")
def teklif_arsivini_getir(db: Session = Depends(get_db)):
    return db.query(database.TeklifArsivi).order_by(database.TeklifArsivi.id.desc()).all()

@app.get("/analiz/")
def analiz_getir(db: Session = Depends(get_db)):
    teklifler = db.query(database.TeklifArsivi).all()
    hammadde_sayisi = db.query(database.Hammadde).count()
    toplam_ciro = sum(t.toplam_tutar for t in teklifler)
    return {
        "toplam_ciro": round(toplam_ciro, 2),
        "teklif_sayisi": len(teklifler),
        "hammadde_sayisi": hammadde_sayisi
    }