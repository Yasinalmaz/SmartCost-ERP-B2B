import 'package:flutter/foundation.dart';

const double operasyonOrani = 0.15;
const double karOrani = 0.20;

class SepetSatiri {
  SepetSatiri(this.urun, this.adet);

  /// Sunucudan gelen ürün bilgisi: id, urun_adi, kategori, ebat, fiyat, stok ...
  final Map<String, dynamic> urun;
  int adet;

  int get id => urun['id'] as int;
  String get ad => urun['urun_adi'] as String;
  String get kategori => (urun['kategori'] ?? '') as String;
  double get fiyat => (urun['fiyat'] as num).toDouble();
  int get stok => urun['stok'] as int;
  double get tutar => fiyat * adet;
  bool get stokYetersiz => adet > stok;
}

class Sepet extends ChangeNotifier {
  final List<SepetSatiri> satirlar = [];

  /// Akıllı siparişten gelindiyse müşterinin yazdığı orijinal metin.
  String talep = '';

  bool get bos => satirlar.isEmpty;
  int get toplamAdet => satirlar.fold<int>(0, (t, s) => t + s.adet);
  double get malzeme => satirlar.fold<double>(0, (t, s) => t + s.tutar);
  double get operasyon => malzeme * operasyonOrani;
  double get kar => (malzeme + operasyon) * karOrani;
  double get genelToplam => malzeme + operasyon + kar;
  bool get stokSorunuVar => satirlar.any((s) => s.stokYetersiz);

  void ekle(Map<String, dynamic> urun, int adet) {
    final i = satirlar.indexWhere((s) => s.id == urun['id']);
    if (i >= 0) {
      satirlar[i].adet += adet;
    } else {
      satirlar.add(SepetSatiri(urun, adet));
    }
    notifyListeners();
  }

  void adetAyarla(int id, int adet) {
    if (adet <= 0) {
      cikar(id);
      return;
    }
    satirlar.firstWhere((s) => s.id == id).adet = adet;
    notifyListeners();
  }

  void cikar(int id) {
    satirlar.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void temizle() {
    satirlar.clear();
    talep = '';
    notifyListeners();
  }

  List<Map<String, int>> get istekKalemleri => [
        for (final s in satirlar) {'urun_id': s.id, 'adet': s.adet},
      ];
}

/// Uygulama genelinde tek sepet.
final Sepet sepet = Sepet();
