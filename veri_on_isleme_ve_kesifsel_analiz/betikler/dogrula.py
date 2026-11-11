"""Veri setini yükler, bütünlük kontrollerini çalıştırır ve özet basar.

Kullanım:  python betikler/dogrula.py
Yalnızca Python standart kütüphanesi gerekir.
"""
import csv
import json
import re
from collections import Counter
from pathlib import Path

KOK = Path(__file__).resolve().parent.parent
VERI = KOK / "veri"


def oku(yol):
    with open(yol, encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


katalog = oku(VERI / "urun_katalogu.csv")
idler = {r["urun_id"] for r in katalog}
hatalar = []


def kontrol(kosul, mesaj):
    print(("  [OK]   " if kosul else "  [HATA] ") + mesaj)
    if not kosul:
        hatalar.append(mesaj)


print("Ürün kataloğu")
kontrol(len(katalog) == 1434, f"{len(katalog)} satır")
kontrol(len(idler) == len(katalog), "urun_id benzersiz")
kontrol(all(float(r["satis_fiyati_tl"]) > 0 for r in katalog), "tüm fiyatlar pozitif")
kontrol(len({(r["kategori_kodu"], r["model"], r["ebat"]) for r in katalog}) == len(katalog), "kategori+model+ebat tekrarı yok")
ihlal = 0
gruplar = {}
for r in katalog:
    if r["ebat_turu"] == "en_x_boy":
        gruplar.setdefault((r["kategori_kodu"], r["model"], r["boy_cm"]), []).append((int(r["en_cm"]), float(r["liste_fiyati_tl"])))
for g in gruplar.values():
    g.sort()
    ihlal += sum(1 for a, b in zip(g, g[1:]) if b[1] < a[1])
kontrol(ihlal == 0, "aynı modelde ebat büyüdükçe fiyat azalmıyor")
print("  kategoriler:", dict(Counter(r["kategori"] for r in katalog).most_common()))

print("\nSipariş cümleleri")
bolum_modeli = {}
for satir in oku(VERI / "siparis_cumleleri/bolum_modelleri.csv"):
    bolum_modeli[(satir["kategori_kodu"], satir["model"])] = satir["bolum"]
model_of = {r["urun_id"]: (r["kategori_kodu"], r["model"]) for r in katalog}
metinler = {}
for bolum in ["train", "val", "test"]:
    satirlar = [json.loads(s) for s in open(VERI / f"siparis_cumleleri/{bolum}.jsonl", encoding="utf-8")]
    kalemler = [k for s in satirlar for k in s["kalemler"]]
    kontrol(all(str(k["urun_id"]) in idler for k in kalemler), f"{bolum}: {len(satirlar)} cümle, {len(kalemler)} kalem; tüm urun_id'ler katalogda")
    kontrol(all(bolum_modeli[model_of[str(k["urun_id"])]] == bolum for k in kalemler), f"{bolum}: tüm ürünler yalnızca bu bölümün modellerinden")
    metinler[bolum] = {s["metin"] for s in satirlar}
kontrol(not (metinler["train"] & metinler["test"]) and not (metinler["val"] & metinler["test"]), "bölümler arasında ortak cümle yok")

print("\nSONUÇ:", "tüm kontroller geçti" if not hatalar else f"{len(hatalar)} kontrol başarısız")
