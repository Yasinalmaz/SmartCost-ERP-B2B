import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Backend adresi. Sunucu başka bir bilgisayarda çalışırsa burayı değiştir.
const String apiAdresi = 'http://127.0.0.1:8000';

class ApiHata implements Exception {
  ApiHata(this.mesaj, this.kod);
  final String mesaj;
  final int kod;

  @override
  String toString() => mesaj;
}

class Kullanici {
  Kullanici.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        eposta = j['eposta'] as String,
        adSoyad = j['ad_soyad'] as String,
        firma = (j['firma'] ?? '') as String,
        rol = j['rol'] as String;

  final int id;
  final String eposta;
  final String adSoyad;
  final String firma;
  final String rol;

  bool get yonetici => rol == 'yonetici';
  String get gorunenAd => firma.isNotEmpty ? firma : adSoyad;
}

/// Sunucuyla tüm iletişim bu sınıftan geçer.
class Api {
  Api._();

  static String? _token;

  /// Giriş yapan kullanıcı. Değiştiğinde uygulama doğru ekrana geçer.
  static final ValueNotifier<Kullanici?> oturum = ValueNotifier<Kullanici?>(null);

  static Map<String, String> get _basliklar => {
        'Content-Type': 'application/json; charset=utf-8',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Uri _uri(String yol, [Map<String, Object?>? parametreler]) {
    final uri = Uri.parse('$apiAdresi$yol');
    if (parametreler == null) return uri;
    final temiz = <String, String>{
      for (final e in parametreler.entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
    };
    return uri.replace(queryParameters: temiz);
  }

  static Future<http.Response> _gonder(Future<http.Response> Function() istek) async {
    try {
      return await istek();
    } catch (_) {
      throw ApiHata('Sunucuya ulaşılamıyor. Backend çalışıyor mu?', 0);
    }
  }

  static dynamic _coz(http.Response r) {
    final govde = r.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 200 && r.statusCode < 300) return govde;

    var mesaj = 'Beklenmeyen hata (${r.statusCode})';
    final detay = govde is Map ? govde['detail'] : null;
    if (detay is String) {
      mesaj = detay;
    } else if (detay is Map) {
      mesaj = '${detay['mesaj']}: ${(detay['detay'] as List).join(', ')}';
    } else if (detay is List && detay.isNotEmpty) {
      mesaj = 'Geçersiz veri: ${(detay.first as Map)['msg']}';
    }
    if (r.statusCode == 401 && _token != null) cikis();
    throw ApiHata(mesaj, r.statusCode);
  }

  static Future<dynamic> get(String yol, [Map<String, Object?>? parametreler]) async =>
      _coz(await _gonder(() => http.get(_uri(yol, parametreler), headers: _basliklar)));

  static Future<dynamic> post(String yol, Object govde) async =>
      _coz(await _gonder(() => http.post(_uri(yol), headers: _basliklar, body: jsonEncode(govde))));

  static Future<dynamic> patch(String yol, Object govde) async =>
      _coz(await _gonder(() => http.patch(_uri(yol), headers: _basliklar, body: jsonEncode(govde))));

  // ---------------------------------------------------------------- oturum
  static Future<void> _oturumAc(dynamic cevap) async {
    final j = cevap as Map<String, dynamic>;
    _token = j['token'] as String;
    oturum.value = Kullanici.fromJson(j['kullanici'] as Map<String, dynamic>);
  }

  static Future<void> girisYap(String eposta, String sifre) async =>
      _oturumAc(await post('/giris', {'eposta': eposta, 'sifre': sifre}));

  static Future<void> kayitOl(
          {required String eposta, required String sifre, required String adSoyad, required String firma}) async =>
      _oturumAc(await post('/kayit', {'eposta': eposta, 'sifre': sifre, 'ad_soyad': adSoyad, 'firma': firma}));

  static void cikis() {
    _token = null;
    oturum.value = null;
  }

  /// Sipariş PDF'ini yeni sekmede açar.
  static Future<void> pdfAc(int siparisId) async {
    await launchUrl(_uri('/arsiv-pdf-indir/$siparisId', {'token': _token}), webOnlyWindowName: '_blank');
  }
}
