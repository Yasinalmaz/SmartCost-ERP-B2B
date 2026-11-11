"""Etiketli sentetik müşteri sipariş cümleleri üretir (Hafta 4).

Kullanım:  python betikler/veri_seti_uret.py cikti.csv
Girdi: veri/urun_katalogu.csv   Çıktı: tek CSV (bolum sütunuyla) + bolum_modelleri.json
Ayrım: ürün modeli bazlı (train/val/test modelleri ayrık) + test için ayrık cümle şablonları.
"""
import csv
import json
import random
import re
import sys
from collections import defaultdict
from pathlib import Path

KOK = Path(__file__).resolve().parent
random.seed(2026)

urunler = [{"id": r["urun_id"], "kategori": r["kategori_kodu"], "model": r["model"], "ebat": r["ebat"], "urun_adi": r["urun_adi"]}
           for r in csv.DictReader(open(KOK.parent / "veri/urun_katalogu.csv", encoding="utf-8-sig"))]
modeller = defaultdict(list)
for u in urunler:
    modeller[(u["kategori"], u["model"])].append(u)

KATEGORI_KELIMESI = {
    "YATAK": ["yatak"], "BAZA": ["baza"], "BASLIK": ["başlık"], "SET": ["set", "takım"],
    "YATAK PEDI": ["topper", "ped"], "BEBEK YATAGI": ["bebek yatağı"], "YASTIK": ["yastık"],
    "YORGAN": ["yorgan"], "NEVRESIM": ["nevresim"], "ALEZ": ["alez"], "CARSAF": ["çarşaf"],
    "PIKE": ["pike"], "BATTANIYE": ["battaniye"], "UYKU SETI": ["uyku seti"],
    "YATAK ORTUSU": ["yatak örtüsü"], "YASTIK KILIFI": ["yastık kılıfı"], "KIRLENT": ["kırlent"],
    "KOMODIN": ["komodin"], "AYDINLATMA": [""], "AKSESUAR": [""], "BAHCE MOBILYASI": [""],
}
TURKCE = {"yun": "yün", "tuyu": "tüyü", "carsaf": "çarşaf", "cift": "çift", "kisilik": "kişilik",
          "yastik": "yastık", "baslik": "başlık", "ortusu": "örtüsü", "gecirmez": "geçirmez",
          "sivi": "sıvı", "dogal": "doğal", "kilifi": "kılıfı", "yatagi": "yatağı", "salincak": "salıncak",
          "koltugu": "koltuğu", "sandikli": "sandıklı", "sarkit": "sarkıt", "ucklu": "üçlü", "ikili": "ikili"}


def musteri_ifadesi(kategori: str, model: str) -> str:
    """Katalogdaki model adını müşterinin yazacağı biçime çevirir."""
    m = re.sub(r"\([^)]*\+[^)]*\)", " ", model)         # (3+1+1+MASA) gibi içerik açıklamaları
    m = m.lower().replace("-s ", " ").replace("(", " ").replace(")", " ")
    if " hvz" in m and random.random() < 0.5:
        m = m.replace(" hvz", " havuzlu")
    m = re.sub(r"\s+", " ", m).strip()
    m = " ".join(TURKCE.get(k, k) for k in m.split())
    kelime = random.choice(KATEGORI_KELIMESI.get(kategori, [""]))
    if kelime and kelime.split()[0] not in m:
        m = f"{m} {kelime}"
    return m


def ebat_ifadesi(kategori: str, ebat: str, bicimler) -> str:
    if not ebat:
        return ""
    if ebat == "TEK KISILIK":
        return random.choice(["tek kişilik", "tek kişilik", "tk"])
    if ebat == "CIFT KISILIK":
        return random.choice(["çift kişilik", "çift kişilik", "çk"])
    if ebat == "BATTAL":
        return "battal"
    if re.fullmatch(r"\d+", ebat):                       # başlık genişliği
        return random.choice([ebat, f"{ebat} cm"])
    a, b = ebat.split("x")
    return random.choice(bicimler).format(a=a, b=b)


def harf_bicimi(metin: str) -> str:
    r = random.random()
    if r < 0.15:
        return metin.upper()
    if r < 0.35:
        return metin.title()
    return metin


def yazim_hatasi(metin: str) -> str:
    """Ürün adındaki en uzun kelimeden bir harf siler (gürültü)."""
    kelimeler = metin.split()
    adaylar = [i for i, k in enumerate(kelimeler) if len(k) >= 5 and k.isalpha()]
    if not adaylar:
        return metin
    i = random.choice(adaylar)
    k = kelimeler[i]
    j = random.randrange(1, len(k) - 1)
    kelimeler[i] = k[:j] + k[j + 1:]
    return " ".join(kelimeler)


# ---------------------------------------------------------------- şablonlar
SABLONLAR = {
    "gelistirme": {
        "kalem": ["{ad} adet {u} {e}", "{ad} tane {u} {e}", "{u} {e} {ad} adet", "{ad} {u} {e}"],
        "baglac": [", ", " ve ", "; "],
        "ebat": ["{a}x{b}", "{a} x {b}", "{a}X{b}"],
    },
    "test": {   # geliştirmede hiç görülmeyen kalıplar
        "kalem": ["{u} {e} x{ad}", "{e} {u} {ad} tane", "{ad} ad. {u} {e}", "{u} {e} ölçüsünde {ad} adet"],
        "baglac": ["\n", " ile ", " bir de ", ", "],
        "ebat": ["{a}*{b}", "{a}x{b} cm", "{a} X {b}"],
    },
}
ONEKLER = ["", "", "Merhaba, ", "İyi günler, ", "Otelimiz için ", "Firmamız adına "]
SONEKLER = ["", "", " lazım.", " rica ederiz.", " için teklif bekliyoruz.", " acil lazım"]


def cumle_uret(model_listesi, kalip, gurultulu):
    kalem_sayisi = random.choices([1, 2, 3, 4], weights=[3, 4, 3, 1])[0]
    secilen = random.sample(model_listesi, kalem_sayisi)
    parcalar, etiket = [], []
    for anahtar in secilen:
        kategori, model = anahtar
        varyant = random.choice(modeller[anahtar])
        adet = random.choice([1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 24, 25, 30, 40])
        u = musteri_ifadesi(kategori, model)
        if gurultulu:
            u = yazim_hatasi(u)
        e = ebat_ifadesi(kategori, varyant["ebat"], kalip["ebat"])
        sablon = random.choice(kalip["kalem"])
        if not e:                                        # ebatsız üründe "ölçüsünde" anlamsız
            sablon = sablon.replace(" ölçüsünde", "")
        if adet == 1 and random.random() < 0.3:          # "1 adet" yazılmayabilir
            ifade = f"{u} {e}"
        else:
            ifade = sablon.format(ad=adet, u=u, e=e)
        parcalar.append(harf_bicimi(re.sub(r"\s+", " ", ifade).strip()))
        etiket.append({"urun_id": int(varyant["id"]), "adet": adet, "urun_adi": varyant["urun_adi"]})
    metin = parcalar[0]
    for p in parcalar[1:]:
        metin += random.choice(kalip["baglac"]) + p
    metin = random.choice(ONEKLER) + metin + random.choice(SONEKLER)
    return metin, etiket


def main(cikti: Path):
    anahtarlar = sorted(modeller)
    random.shuffle(anahtarlar)
    n = len(anahtarlar)
    bolum = {"train": anahtarlar[: int(n * 0.6)], "val": anahtarlar[int(n * 0.6): int(n * 0.8)],
             "test": anahtarlar[int(n * 0.8):]}
    hedef = {"train": 600, "val": 200, "test": 200}

    satirlar = []
    for ad, sayi in hedef.items():
        kalip = SABLONLAR["test" if ad == "test" else "gelistirme"]
        for i in range(sayi):
            gurultulu = ad == "test" and i % 5 == 0          # testin %20'si yazım hatalı
            metin, etiket = cumle_uret(bolum[ad], kalip, gurultulu)
            satirlar.append({"id": len(satirlar) + 1, "bolum": ad, "gurultulu": int(gurultulu),
                             "kalem_sayisi": len(etiket), "metin": metin,
                             "etiket": json.dumps(etiket, ensure_ascii=False)})

    with open(cikti, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(satirlar[0]))
        w.writeheader()
        w.writerows(satirlar)
    with open(cikti.with_name("bolum_modelleri.json"), "w", encoding="utf-8") as f:
        json.dump({k: ["|".join(m) for m in v] for k, v in bolum.items()}, f, ensure_ascii=False, indent=1)
    print(f"{len(satirlar)} cümle yazıldı; model sayıları:", {k: len(v) for k, v in bolum.items()})


if __name__ == "__main__":
    main(Path(sys.argv[1]))
