# SmartCost ERP & B2B Portalı

Bambi Yatak 07.10.2026 tavsiye edilen perakende fiyat listeleri (yatak/baza/başlık/set + ev tekstili, 1.434 ürün-ebat satırı, 292 model) ile çalışan B2B sipariş ve teklif sistemi.

## Çalıştırma

**1. Backend** (VS Code terminali, venv açık):
```powershell
cd backend
python -m uvicorn main:app --reload
```
API dokümantasyonu: http://127.0.0.1:8000/docs

**2. Arayüz** (ikinci terminal):
```powershell
cd syntax_mobile
flutter run -d chrome
```

## Demo hesaplar
| Rol | E-posta | Şifre |
|---|---|---|
| Yönetici | admin@smartcost.com | admin123 |
| Müşteri | satinalma@yildizotel.com | 123456 |
| Müşteri | info@egeyurt.com | 123456 |

## Ekranlar
**Müşteri portalı:** ürün kataloğu (kategori menüsü, arama, sıralama, ebat seçimi), Akıllı Sipariş (serbest metinden ürün/ebat/adet tanıma), sepet, iki aşamalı teklif → onay, PDF teklif, Siparişlerim.

**Yönetici paneli:** gösterge paneli (ciro, sipariş, ortalama sepet, kritik stok, kategori bazlı satış, en çok satanlar), sipariş yönetimi (durum: Onaylandı → Hazırlanıyor → Kargoda → Teslim Edildi / İptal; iptalde stok geri eklenir), ürün & stok yönetimi (fiyat/stok düzenleme, kritik stok filtresi).

## Backend dosyaları
| Dosya | Görev |
|---|---|
| `database.py` | SQLite (`smartcost.db`): urunler, kullanicilar, teklif_arsivi, teklif_kalemleri; CSV'den ilk yükleme |
| `nlp.py` | Türkçe normalizasyon (`tr_kucuk`) + çoklu ürün/ebat/adet ayrıştırma motoru |
| `main.py` | FastAPI uç noktaları, %15 operasyon + %20 kâr hesabı, oturum, yönetici işlemleri |
| `pdf_olustur.py` | FPDF2 ile SYN-2026-XXXX numaralı teklif PDF'i |
| `veri/urunler.csv` | Fiyat listelerinden çıkarılan ürün kataloğu (başlangıç stoku 50) |

Veritabanını sıfırlamak için: sunucuyu durdur, `backend/smartcost.db` dosyasını sil, tekrar başlat.
