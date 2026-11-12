import 'package:flutter/material.dart';

import '../api.dart';
import '../tema.dart';
import 'gosterge_paneli.dart';
import 'siparis_yonetimi.dart';
import 'urun_yonetimi.dart';

/// Yönetici (ERP) paneli: sol menü + içerik.
class YoneticiPaneli extends StatefulWidget {
  const YoneticiPaneli({super.key});

  @override
  State<YoneticiPaneli> createState() => _YoneticiPaneliState();
}

class _YoneticiPaneliState extends State<YoneticiPaneli> {
  int _sayfa = 0;

  static const _menu = [
    (Icons.space_dashboard_outlined, Icons.space_dashboard, 'Gösterge Paneli'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Siparişler'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Ürün & Stok'),
  ];

  @override
  Widget build(BuildContext context) {
    final genis = MediaQuery.sizeOf(context).width >= 1200;
    final kullanici = Api.oturum.value!;

    final Widget icerik = switch (_sayfa) {
      0 => GostergePaneli(sayfayaGit: (i) => setState(() => _sayfa = i)),
      1 => const SiparisYonetimi(),
      _ => const UrunYonetimi(),
    };

    return Scaffold(
      body: Row(children: [
        Container(
          color: lacivert,
          child: NavigationRail(
            backgroundColor: lacivert,
            extended: genis,
            minExtendedWidth: 240,
            selectedIndex: _sayfa,
            onDestinationSelected: (i) => setState(() => _sayfa = i),
            indicatorColor: vurgu,
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.7)),
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            unselectedLabelTextStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            labelType: genis ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: vurgu, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                ),
                if (genis) ...[
                  const SizedBox(width: 10),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SmartCost', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('ERP Yönetim', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ],
              ]),
            ),
            destinations: [
              for (final m in _menu)
                NavigationRailDestination(icon: Icon(m.$1), selectedIcon: Icon(m.$2), label: Text(m.$3)),
            ],
          ),
        ),
        Expanded(
          child: Column(children: [
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: cizgi)),
              ),
              child: Row(children: [
                Text(_menu[_sayfa].$3,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: lacivert)),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: lacivert,
                  radius: 17,
                  child: Text(kullanici.adSoyad.isEmpty ? '?' : kullanici.adSoyad[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(kullanici.adSoyad, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Text('Yönetici', style: TextStyle(color: gri, fontSize: 12)),
                ]),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: Api.cikis,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Çıkış'),
                ),
              ]),
            ),
            Expanded(child: icerik),
          ]),
        ),
      ]),
    );
  }
}
