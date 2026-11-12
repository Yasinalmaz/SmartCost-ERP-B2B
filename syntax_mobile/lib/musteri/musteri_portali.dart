import 'package:flutter/material.dart';

import '../api.dart';
import '../sepet.dart';
import '../tema.dart';
import 'akilli_siparis_sayfasi.dart';
import 'katalog_sayfasi.dart';
import 'sepet_sayfasi.dart';
import 'siparislerim_sayfasi.dart';

/// Müşterinin gördüğü e-ticaret vitrini: üst menü + sayfalar.
class MusteriPortali extends StatefulWidget {
  const MusteriPortali({super.key});

  @override
  State<MusteriPortali> createState() => _MusteriPortaliState();
}

class _MusteriPortaliState extends State<MusteriPortali> {
  int _sayfa = 0;
  final ValueNotifier<String> _arama = ValueNotifier<String>('');
  final _aramaKutusu = TextEditingController();
  int _siparisYenile = 0;

  static const _menu = [
    (Icons.storefront_outlined, 'Ürünler'),
    (Icons.auto_awesome_outlined, 'Akıllı Sipariş'),
    (Icons.shopping_cart_outlined, 'Sepetim'),
    (Icons.receipt_long_outlined, 'Siparişlerim'),
  ];

  @override
  void dispose() {
    _arama.dispose();
    _aramaKutusu.dispose();
    super.dispose();
  }

  void _git(int sayfa) => setState(() {
        _sayfa = sayfa;
        if (sayfa == 3) _siparisYenile++;
      });

  void _ara(String metin) {
    _arama.value = metin.trim();
    _git(0);
  }

  @override
  Widget build(BuildContext context) {
    final genis = MediaQuery.sizeOf(context).width >= 900;
    final kullanici = Api.oturum.value!;

    return Scaffold(
      body: Column(children: [
        _UstBant(kullanici: kullanici),
        Material(
          color: Colors.white,
          child: Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cizgi))),
            padding: EdgeInsets.symmetric(horizontal: genis ? 32 : 12, vertical: 12),
            child: Row(children: [
              InkWell(onTap: () => _git(0), child: const _Logo()),
              SizedBox(width: genis ? 40 : 12),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: TextField(
                    controller: _aramaKutusu,
                    onSubmitted: _ara,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Ürün, model veya ebat ara (ör. golden 160x200)',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: zemin,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _aramaKutusu.clear();
                          _ara('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (genis)
                for (var i = 0; i < _menu.length; i++)
                  if (i != 2) _MenuDugmesi(ikon: _menu[i].$1, metin: _menu[i].$2, secili: _sayfa == i, tiklandi: () => _git(i)),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: sepet,
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _sayfa == 2 ? vurgu : lacivert,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () => _git(2),
                    icon: Badge(
                      isLabelVisible: sepet.toplamAdet > 0,
                      label: Text('${sepet.toplamAdet}'),
                      backgroundColor: vurgu,
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                    label: Text(genis ? 'Sepetim · ${tl(sepet.malzeme)}' : ''),
                  ),
                ),
              ),
            ]),
          ),
        ),
        Expanded(
          child: IndexedStack(index: _sayfa, children: [
            KatalogSayfasi(arama: _arama, akilliSiparisAc: () => _git(1)),
            AkilliSiparisSayfasi(sepeteGit: () => _git(2)),
            SepetSayfasi(alisveriseDon: () => _git(0), siparislerimeGit: () => _git(3)),
            SiparislerimSayfasi(key: ValueKey(_siparisYenile)),
          ]),
        ),
      ]),
      bottomNavigationBar: genis
          ? null
          : NavigationBar(
              selectedIndex: _sayfa,
              onDestinationSelected: _git,
              destinations: [for (final m in _menu) NavigationDestination(icon: Icon(m.$1), label: m.$2)],
            ),
    );
  }
}

class _UstBant extends StatelessWidget {
  const _UstBant({required this.kullanici});
  final Kullanici kullanici;

  @override
  Widget build(BuildContext context) {
    const stil = TextStyle(color: Colors.white, fontSize: 12.5);
    return Container(
      color: lacivert,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      child: Row(children: [
        const Icon(Icons.local_shipping_outlined, color: vurgu, size: 16),
        const SizedBox(width: 6),
        const Flexible(
          child: Text('Kurumsal siparişlerde anlık stok kontrolü ve seri numaralı resmi teklif',
              style: stil, overflow: TextOverflow.ellipsis),
        ),
        const Spacer(),
        PopupMenuButton<String>(
          tooltip: 'Hesabım',
          onSelected: (s) {
            if (s == 'cikis') {
              sepet.temizle();
              Api.cikis();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(kullanici.adSoyad, style: const TextStyle(fontWeight: FontWeight.w600, color: lacivert)),
                Text(kullanici.eposta, style: const TextStyle(fontSize: 12, color: gri)),
              ]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'cikis',
              child: Row(children: [Icon(Icons.logout, size: 18), SizedBox(width: 10), Text('Çıkış yap')]),
            ),
          ],
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.apartment_outlined, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(kullanici.gorunenAd, style: stil.copyWith(fontWeight: FontWeight.w600)),
            const Icon(Icons.expand_more, color: Colors.white, size: 18),
          ]),
        ),
      ]),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: vurgu, borderRadius: BorderRadius.circular(9)),
        child: const Icon(Icons.bolt, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 8),
      const Text('SmartCost', style: TextStyle(color: lacivert, fontSize: 20, fontWeight: FontWeight.w800)),
      const Text(' B2B', style: TextStyle(color: gri, fontSize: 20, fontWeight: FontWeight.w300)),
    ]);
  }
}

class _MenuDugmesi extends StatelessWidget {
  const _MenuDugmesi({required this.ikon, required this.metin, required this.secili, required this.tiklandi});
  final IconData ikon;
  final String metin;
  final bool secili;
  final VoidCallback tiklandi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton.icon(
        onPressed: tiklandi,
        style: TextButton.styleFrom(
          foregroundColor: secili ? vurgu : lacivert,
          backgroundColor: secili ? vurgu.withValues(alpha: 0.08) : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(ikon, size: 20),
        label: Text(metin, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
