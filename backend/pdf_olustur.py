"""Onaylanan sipariş için PDF teklif belgesi (FPDF2)."""
from pathlib import Path

from fpdf import FPDF
from fpdf.fonts import FontFace

# Türkçe karakterler için sistemdeki bir Unicode font aranır.
FONT_ADAYLARI = [
    "/System/Library/Fonts/Supplemental/Arial.ttf",          # macOS
    "C:/Windows/Fonts/arial.ttf",                            # Windows
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",       # Linux
]


def _tl(x: float) -> str:
    return f"{x:,.2f} TL".replace(",", "#").replace(".", ",").replace("#", ".")


def teklif_pdf(t) -> bytes:
    pdf = FPDF()
    pdf.add_page()
    font = next((f for f in FONT_ADAYLARI if Path(f).exists()), None)
    if font:
        pdf.add_font("TR", "", font)
        pdf.set_font("TR", size=11)
        yaz = lambda s: s
    else:  # font yoksa Türkçe harfleri sadeleştir
        pdf.set_font("Helvetica", size=11)
        yaz = lambda s: s.translate(str.maketrans("çğıöşüÇĞİÖŞÜ₺", "cgiosuCGIOSUT"))

    pdf.set_font_size(18)
    pdf.cell(0, 12, yaz("SmartCost ERP - Satış Teklifi"), new_x="LMARGIN", new_y="NEXT")
    pdf.set_font_size(11)
    pdf.cell(0, 7, yaz(f"Seri No: {t.seri_no}"), new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, yaz(f"Müşteri: {t.musteri_adi}"), new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, yaz(f"Onay Tarihi: {t.tarih:%d.%m.%Y %H:%M}"), new_x="LMARGIN", new_y="NEXT")
    pdf.ln(4)

    with pdf.table(col_widths=(95, 20, 35, 40), text_align=("LEFT", "CENTER", "RIGHT", "RIGHT"),
                   headings_style=FontFace(emphasis="", fill_color=(230, 230, 230))) as tablo:
        tablo.row([yaz("Ürün"), "Adet", "Birim Fiyat", "Tutar"])
        for k in t.kalemler:
            tablo.row([yaz(k.urun_adi), str(k.adet), _tl(k.birim_fiyat), _tl(k.tutar)])

    pdf.ln(4)
    for etiket, deger in [("Malzeme Toplamı", t.malzeme_toplami),
                          ("Operasyon Gideri (%15)", t.operasyon_gideri),
                          ("Kâr Marjı (%20)", t.kar_marji),
                          ("GENEL TOPLAM", t.toplam_tutar)]:
        pdf.cell(140, 8, yaz(etiket), align="R")
        pdf.cell(50, 8, _tl(deger), align="R", new_x="LMARGIN", new_y="NEXT")
    return bytes(pdf.output())
