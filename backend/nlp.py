"""Serbest sipariş metnini (ürün, ebat, adet) kalemlerine ayıran kural tabanlı motor.

Örnek: "2 adet golden yatak 160x200 ve 3 tane kaz tüyü yastık"
  -> [{golden yatak 160x200, adet 2}, {kaz tüyü yastık, adet 3}]
"""
import re

# ---------------------------------------------------------------- normalizasyon
_TR = str.maketrans({"I": "ı", "İ": "i"})
_ASCII = str.maketrans("çğıöşüâî", "cgiosuai")


def tr_kucuk(metin: str) -> str:
    """Türkçe doğru küçük harf + ASCII'ye katlama (Çelik, ÇELİK, celik -> celik)."""
    return metin.translate(_TR).lower().translate(_ASCII)


def normalize(metin: str) -> str:
    m = tr_kucuk(metin)
    m = re.sub(r"(\d)\s*[x×*]\s*(\d)", r"\1x\2", m)        # 160 X 200 -> 160x200
    m = re.sub(r"[^a-z0-9x+/ ]", " ", m)                  # tire, nokta vb. -> boşluk
    m = re.sub(r"\bhavuzlu\b", "havuzlu hvz", m)            # havuzlu = hvz
    return re.sub(r"\s+", " ", m).strip()


# ---------------------------------------------------------------- sözlükler
# Müşterinin yazabileceği kelime -> veritabanındaki kategori
KATEGORI_KELIMELERI = {
    "yatak": "YATAK", "yataklar": "YATAK",
    "baza": "BAZA", "bazasi": "BAZA",
    "baslik": "BASLIK", "basligi": "BASLIK",
    "set": "SET", "seti": "SET",
    "yastik": "YASTIK", "yastigi": "YASTIK",
    "yorgan": "YORGAN", "yorgani": "YORGAN",
    "nevresim": "NEVRESIM", "alez": "ALEZ", "carsaf": "CARSAF", "pike": "PIKE",
    "battaniye": "BATTANIYE", "ped": "YATAK PEDI", "topper": "YATAK PEDI",
    "abajur": "AYDINLATMA", "lamba": "AYDINLATMA", "komodin": "KOMODIN",
    "puf": "AKSESUAR", "kilif": "YASTIK KILIFI", "kirlent": "KIRLENT",
}
# Model adlarında geçen ama ayırt edici olmayan kelimeler (eşleşme puanı vermez)
GENEL_KELIMELER = {"s", "set", "seti", "baza", "baslik", "yatak", "mini", "tkm",
                   "tk", "ck", "bt", "battal", "uyk", "uyku", "sag/sol", "-", "/"}
EBAT_KELIMELERI = [
    (r"\b(tek kisilik|tk)\b", "TEK KISILIK"),
    (r"\b(cift kisilik|ck)\b", "CIFT KISILIK"),
    (r"\b(battal|bt)\b", "BATTAL"),
]
ADET = r"(?:adet|ad|tane|tn|pcs)"


def _parcalara_bol(metin: str) -> list[str]:
    """'ve', virgül, noktalı virgül ve satır sonlarından böler."""
    parcalar = re.split(r"\s*(?:,|;|\n| ve | ile | bir de |\+ ?(?=\d))\s*", " " + metin + " ")
    return [p.strip() for p in parcalar if p.strip()]


def _model_kelimeleri(model: str) -> set[str]:
    return {k for k in normalize(model).split() if k not in GENEL_KELIMELER and not re.fullmatch(r"[\d x()]+", k)}


class Ayristirici:
    """Ürün listesini bir kez alıp indeksler, sonra metinleri hızlıca çözer."""

    def __init__(self, urunler):
        # urunler: id, kategori, model, ebat alanları olan nesneler
        self.urunler = []
        for u in urunler:
            self.urunler.append({
                "id": u.id, "kategori": u.kategori, "ebat": u.ebat,
                "kelimeler": _model_kelimeleri(u.model),
            })

    def ayristir(self, metin: str) -> dict:
        kalemler, anlasilmayan = [], []
        for ham in _parcalara_bol(metin):
            parca = normalize(ham)
            sonuc = self._parcayi_coz(parca)
            if sonuc:
                sonuc["kaynak_metin"] = ham
                kalemler.append(sonuc)
            elif re.search(r"[a-z]{3,}", parca):
                anlasilmayan.append(ham)
        return {"kalemler": kalemler, "anlasilmayan": anlasilmayan}

    def _parcayi_coz(self, parca: str):
        # 1) ebat: 160x200 veya "cift kisilik"
        ebat = None
        m = re.search(r"\b(\d{2,3})x(\d{2,3})\b", parca)
        if m:
            ebat = f"{m[1]}x{m[2]}"
            parca_kalan = parca.replace(m[0], " ")
        else:
            parca_kalan = parca
            for desen, deger in EBAT_KELIMELERI:
                if re.search(desen, parca):
                    ebat = deger
                    break

        # 3) kategori ipucu
        kelimeler = set(parca.split())
        kategoriler = {KATEGORI_KELIMELERI[k] for k in kelimeler if k in KATEGORI_KELIMELERI}

        # Başlıklar genişlikle yazılır: "blacksand başlık 180" -> ebat 180
        if not ebat and "BASLIK" in kategoriler:
            g = re.search(r"\b(80|90|100|110|120|130|140|150|160|170|180|190|200|210)\s*(?:cm)?\b(?!\s*" + ADET + ")", parca_kalan)
            if g:
                ebat = g[1]
                parca_kalan = parca_kalan[:g.start()] + " " + parca_kalan[g.end():]

        # 2) adet: "3 adet", "3 tane", "x3" ya da cümledeki ilk sayı
        adet = 1
        a = re.search(rf"\b(\d+)\s*{ADET}\b", parca_kalan) or re.search(r"\bx\s*(\d+)\b", parca_kalan) \
            or re.search(r"\b(\d{1,4})\b", parca_kalan)
        if a:
            adet = int(a[1])

        # 4) en iyi ürünü puanla
        en_iyi, en_iyi_puan = None, 0.0
        for u in self.urunler:
            ortak = u["kelimeler"] & kelimeler
            if not ortak:
                continue
            puan = len(ortak) * 10 + 5 * len(ortak) / len(u["kelimeler"])
            if u["kategori"] in kategoriler:
                puan += 8
            elif kategoriler:
                puan -= 4
            if ebat:
                if self._ebat_uyar(u, ebat):
                    puan += 6
                else:
                    continue                       # müşteri ebat verdiyse uymayan ürünü eleme
            if puan > en_iyi_puan:
                en_iyi, en_iyi_puan = u, puan

        if not en_iyi:
            return None
        return {"urun_id": en_iyi["id"], "adet": adet, "istenen_ebat": ebat}

    @staticmethod
    def _ebat_uyar(u, ebat: str) -> bool:
        if not u["ebat"]:
            return False
        if u["ebat"] == ebat:
            return True
        if u["kategori"] == "BASLIK" and "x" not in ebat:
            return False
        # Başlıklar sadece genişlikle listelenir: 160x200 -> 160
        if u["kategori"] == "BASLIK" and "x" in ebat:
            return u["ebat"] == ebat.split("x")[0]
        return False
