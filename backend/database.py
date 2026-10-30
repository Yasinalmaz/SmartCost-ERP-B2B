from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import datetime

engine = create_engine("sqlite:///./teklif_sistemi.db", connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class Hammadde(Base):
    __tablename__ = "hammaddeler"
    id = Column(Integer, primary_key=True, index=True)
    isim = Column(String, index=True)
    birim_fiyati = Column(Float)
    stok_adedi = Column(Integer, default=50)

class TeklifArsivi(Base):
    __tablename__ = "teklif_arsivi"
    id = Column(Integer, primary_key=True, index=True)
    musteri_adi = Column(String, default="Bireysel Müşteri") # YENİ EKLENDİ
    tarih = Column(DateTime, default=datetime.datetime.utcnow)
    talep = Column(String)
    toplam_tutar = Column(Float)

Base.metadata.create_all(bind=engine)