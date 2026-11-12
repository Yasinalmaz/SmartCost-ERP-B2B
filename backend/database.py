"""Veritabanı bağlantısı, tablolar ve ürün listesinin ilk yüklemesi."""
import csv
import hashlib
from datetime import datetime
from pathlib import Path

from sqlalchemy import (Column, DateTime, Float, ForeignKey, Integer, String,
                        Text, create_engine)
from sqlalchemy.orm import declarative_base, relationship, sessionmaker

KLASOR = Path(__file__).resolve().parent
DB_YOLU = KLASOR / "smartcost.db"
CSV_YOLU = KLASOR / "veri" / "urunler.csv"

engine = create_engine(f"sqlite:///{DB_YOLU}", connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine, autoflush=False)
Base = declarative_base()


class Urun(Base):
    """Bambi fiyat listesindeki her ürün + ebat kombinasyonu bir satırdır."""
    __tablename__ = "urunler"
    id = Column(Integer, primary_key=True, index=True)
    kategori = Column(String, index=True, nullable=False)   # YATAK, BAZA, YASTIK ...
    model = Column(String, index=True, nullable=False)      # GOLDEN, PAMUK ALEZ (100x200) ...
    ebat = Column(String, default="")                       # 160x200, CIFT KISILIK, 160 ...
    urun_adi = Column(String, nullable=False)               # Ekranda/PDF'te görünen tam ad
    birim_fiyati = Column(Float, nullable=False)            # Liste fiyatı (₺, KDV dahil)
    indirimli_fiyat = Column(Float, nullable=True)          # Kampanyalı ürünlerde dolu
    stok_adedi = Column(Integer, default=50)

    @property
    def gecerli_fiyat(self) -> float:
        return self.indirimli_fiyat or self.birim_fiyati


SIPARIS_DURUMLARI = ["Onaylandı", "Hazırlanıyor", "Kargoda", "Teslim Edildi", "İptal"]


def sifre_ozeti(sifre: str) -> str:
    return hashlib.sha256(sifre.encode("utf-8")).hexdigest()


class Kullanici(Base):
    """Portal kullanıcıları: rol = 'musteri' veya 'yonetici'."""
    __tablename__ = "kullanicilar"
    id = Column(Integer, primary_key=True)
    eposta = Column(String, unique=True, index=True, nullable=False)
    sifre_hash = Column(String, nullable=False)
    ad_soyad = Column(String, nullable=False)
    firma = Column(String, default="")
    rol = Column(String, default="musteri")


class TeklifArsivi(Base):
    """Onaylanan siparişler."""
    __tablename__ = "teklif_arsivi"
    id = Column(Integer, primary_key=True, index=True)
    seri_no = Column(String, unique=True, index=True)       # SYN-2026-0001
    kullanici_id = Column(Integer, ForeignKey("kullanicilar.id"), nullable=True)
    musteri_adi = Column(String, nullable=False)
    talep = Column(Text, nullable=False)
    malzeme_toplami = Column(Float, nullable=False)
    operasyon_gideri = Column(Float, nullable=False)
    kar_marji = Column(Float, nullable=False)
    toplam_tutar = Column(Float, nullable=False)
    durum = Column(String, default="Onaylandı")
    tarih = Column(DateTime, default=datetime.now)
    kalemler = relationship("TeklifKalemi", back_populates="teklif", cascade="all, delete-orphan")


class TeklifKalemi(Base):
    """Bir siparişin satırları (hangi üründen kaç adet, o anki fiyatla)."""
    __tablename__ = "teklif_kalemleri"
    id = Column(Integer, primary_key=True)
    teklif_id = Column(Integer, ForeignKey("teklif_arsivi.id"), nullable=False)
    urun_id = Column(Integer, ForeignKey("urunler.id"), nullable=False)
    urun_adi = Column(String, nullable=False)
    adet = Column(Integer, nullable=False)
    birim_fiyat = Column(Float, nullable=False)
    tutar = Column(Float, nullable=False)
    teklif = relationship("TeklifArsivi", back_populates="kalemler")


def veritabanini_hazirla() -> None:
    """Tabloları oluşturur; ürün tablosu boşsa CSV'den doldurur."""
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        if db.query(Urun).count() == 0:
            with open(CSV_YOLU, encoding="utf-8") as f:
                for r in csv.DictReader(f):
                    db.add(Urun(
                        id=int(r["id"]),
                        kategori=r["kategori"],
                        model=r["model"],
                        ebat=r["ebat"],
                        urun_adi=r["urun_adi"],
                        birim_fiyati=float(r["fiyat"]),
                        indirimli_fiyat=float(r["indirimli_fiyat"]) if r["indirimli_fiyat"] else None,
                        stok_adedi=int(r["stok_adedi"]),
                    ))
            db.commit()
            print(f"{db.query(Urun).count()} ürün veritabanına yüklendi.")
        if db.query(Kullanici).count() == 0:
            db.add_all([
                Kullanici(eposta="admin@smartcost.com", sifre_hash=sifre_ozeti("admin123"),
                          ad_soyad="Sistem Yöneticisi", firma="SmartCost", rol="yonetici"),
                Kullanici(eposta="satinalma@yildizotel.com", sifre_hash=sifre_ozeti("123456"),
                          ad_soyad="Ayşe Yıldız", firma="Yıldız Otelcilik A.Ş.", rol="musteri"),
                Kullanici(eposta="info@egeyurt.com", sifre_hash=sifre_ozeti("123456"),
                          ad_soyad="Mehmet Kaya", firma="Ege Öğrenci Yurtları", rol="musteri"),
            ])
            db.commit()
    finally:
        db.close()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
