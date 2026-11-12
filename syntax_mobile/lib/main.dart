import 'package:flutter/material.dart';

import 'api.dart';
import 'giris_sayfasi.dart';
import 'musteri/musteri_portali.dart';
import 'tema.dart';
import 'yonetici/yonetici_paneli.dart';

void main() => runApp(const SmartCostUygulamasi());

class SmartCostUygulamasi extends StatelessWidget {
  const SmartCostUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCost B2B',
      debugShowCheckedModeBanner: false,
      theme: uygulamaTemasi(),
      // Oturum durumuna göre doğru ekran: giriş / müşteri portalı / yönetici paneli
      home: ValueListenableBuilder<Kullanici?>(
        valueListenable: Api.oturum,
        builder: (context, kullanici, _) {
          if (kullanici == null) return const GirisSayfasi();
          return kullanici.yonetici ? const YoneticiPaneli() : const MusteriPortali();
        },
      ),
    );
  }
}
