import 'package:flutter/material.dart';

// ---------------------------------------------------------------- renkler
const Color lacivert = Color(0xFF14213D);
const Color lacivertAcik = Color(0xFF243B66);
const Color vurgu = Color(0xFFE07A1F);
const Color zemin = Color(0xFFF4F6FA);
const Color cizgi = Color(0xFFE3E6EE);
const Color gri = Color(0xFF6B7280);
const Color yesil = Color(0xFF16A34A);
const Color kirmizi = Color(0xFFDC2626);
const Color sari = Color(0xFFD97706);

ThemeData uygulamaTemasi() {
  final renkler = ColorScheme.fromSeed(
    seedColor: lacivert,
    primary: lacivert,
    secondary: vurgu,
    surface: Colors.white,
  );
  final kenar = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: cizgi),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: renkler,
    scaffoldBackgroundColor: zemin,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: lacivert,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: cizgi),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: kenar,
      enabledBorder: kenar,
      focusedBorder: kenar.copyWith(borderSide: const BorderSide(color: lacivert, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: cizgi),
      ),
    ),
    dividerTheme: const DividerThemeData(color: cizgi, space: 1, thickness: 1),
    chipTheme: const ChipThemeData(side: BorderSide(color: cizgi)),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

// ---------------------------------------------------------------- biçimlendirme
String tl(num x) {
  final negatif = x < 0;
  final parcalar = x.abs().toStringAsFixed(2).split('.');
  final tam = parcalar[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '${negatif ? '-' : ''}$tam,${parcalar[1]} ₺';
}

String tarihBicim(String iso, {bool saat = true}) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  String iki(int n) => n.toString().padLeft(2, '0');
  final gun = '${iki(d.day)}.${iki(d.month)}.${d.year}';
  return saat ? '$gun ${iki(d.hour)}:${iki(d.minute)}' : gun;
}

String ebatBicim(String ebat) {
  switch (ebat) {
    case 'TEK KISILIK':
      return 'Tek Kişilik';
    case 'CIFT KISILIK':
      return 'Çift Kişilik';
    case 'BATTAL':
      return 'Battal';
    case '':
      return 'Standart';
  }
  if (RegExp(r'^\d+$').hasMatch(ebat)) return '$ebat cm';
  return '$ebat cm';
}

// ---------------------------------------------------------------- kategoriler
class KategoriBilgi {
  const KategoriBilgi(this.ad, this.ikon, this.renk);
  final String ad;
  final IconData ikon;
  final Color renk;
}

/// Sıra, müşteri menüsünde görünecek sıradır.
const Map<String, KategoriBilgi> kategoriBilgileri = {
  'YATAK': KategoriBilgi('Yataklar', Icons.king_bed_outlined, Color(0xFF2563EB)),
  'BAZA': KategoriBilgi('Bazalar', Icons.bed_outlined, Color(0xFF7C3AED)),
  'BASLIK': KategoriBilgi('Başlıklar', Icons.bedroom_parent_outlined, Color(0xFF9333EA)),
  'SET': KategoriBilgi('Yatak + Baza + Başlık Setleri', Icons.hotel_outlined, Color(0xFF0F766E)),
  'YATAK PEDI': KategoriBilgi('Yatak Pedleri', Icons.layers_outlined, Color(0xFF0891B2)),
  'BEBEK YATAGI': KategoriBilgi('Bebek Yatakları', Icons.child_friendly_outlined, Color(0xFFDB2777)),
  'YASTIK': KategoriBilgi('Yastıklar', Icons.cloud_outlined, Color(0xFF0284C7)),
  'YORGAN': KategoriBilgi('Yorganlar', Icons.bedtime_outlined, Color(0xFF4F46E5)),
  'NEVRESIM': KategoriBilgi('Nevresimler', Icons.style_outlined, Color(0xFFBE185D)),
  'UYKU SETI': KategoriBilgi('Uyku Setleri', Icons.nightlight_outlined, Color(0xFF6D28D9)),
  'ALEZ': KategoriBilgi('Alezler', Icons.water_drop_outlined, Color(0xFF0369A1)),
  'CARSAF': KategoriBilgi('Çarşaflar', Icons.checkroom_outlined, Color(0xFF059669)),
  'PIKE': KategoriBilgi('Pikeler', Icons.grid_on_outlined, Color(0xFFCA8A04)),
  'BATTANIYE': KategoriBilgi('Battaniyeler', Icons.texture, Color(0xFFB45309)),
  'YATAK ORTUSU': KategoriBilgi('Yatak Örtüleri', Icons.view_day_outlined, Color(0xFF9D174D)),
  'YASTIK KILIFI': KategoriBilgi('Yastık Kılıfları', Icons.crop_portrait, Color(0xFF0E7490)),
  'KIRLENT': KategoriBilgi('Kırlentler', Icons.crop_square, Color(0xFFC2410C)),
  'KOMODIN': KategoriBilgi('Komodinler', Icons.table_restaurant_outlined, Color(0xFF78350F)),
  'AYDINLATMA': KategoriBilgi('Aydınlatma', Icons.light_outlined, Color(0xFFEAB308)),
  'AKSESUAR': KategoriBilgi('Puf & Aksesuar', Icons.chair_outlined, Color(0xFF57534E)),
  'BAHCE MOBILYASI': KategoriBilgi('Bahçe Mobilyası', Icons.deck_outlined, Color(0xFF15803D)),
};

KategoriBilgi kategoriBilgi(String kod) =>
    kategoriBilgileri[kod] ?? KategoriBilgi(kod, Icons.inventory_2_outlined, gri);
