import 'package:flutter/material.dart';

import '../ortak.dart';
import '../sepet.dart';
import '../tema.dart';

Future<void> urunDetayGoster(BuildContext context, Map<String, dynamic> grup) {
  return showDialog<void>(context: context, builder: (_) => _UrunDetay(grup: grup));
}

class _UrunDetay extends StatefulWidget {
  const _UrunDetay({required this.grup});
  final Map<String, dynamic> grup;

  @override
  State<_UrunDetay> createState() => _UrunDetayState();
}

class _UrunDetayState extends State<_UrunDetay> {
  late Map<String, dynamic> _varyant;
  int _adet = 1;

  List<Map<String, dynamic>> get _varyantlar =>
      (widget.grup['varyantlar'] as List<dynamic>).cast<Map<String, dynamic>>();

  String get _kategori => widget.grup['kategori'] as String;

  @override
  void initState() {
    super.initState();
    _varyant = _varyantlar.firstWhere((v) => (v['stok'] as int) > 0, orElse: () => _varyantlar.first);
  }

  void _sepeteEkle() {
    sepet.ekle({..._varyant, 'kategori': _kategori}, _adet);
    Navigator.pop(context);
    bildir(context, '${_varyant['urun_adi']} × $_adet sepete eklendi');
  }

  @override
  Widget build(BuildContext context) {
    final genis = MediaQuery.sizeOf(context).width >= 760;
    final stok = _varyant['stok'] as int;
    final indirimli = _varyant['indirimli_fiyat'] as num?;
    final listeFiyati = _varyant['liste_fiyati'] as num;

    final gorsel = KategoriGorseli(kategori: _kategori, boyut: genis ? 300 : 160, yuvarlak: 16);

    final bilgiler = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(kategoriBilgi(_kategori).ad.toUpperCase(),
          style: const TextStyle(color: gri, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
      const SizedBox(height: 6),
      Text(widget.grup['model'] as String,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: lacivert)),
      const SizedBox(height: 18),
      if (_varyantlar.length > 1) ...[
        const Text('Ebat seçin', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in _varyantlar)
            ChoiceChip(
              label: Text(ebatBicim(v['ebat'] as String)),
              selected: identical(v, _varyant),
              onSelected: (_) => setState(() {
                _varyant = v;
                _adet = 1;
              }),
              selectedColor: lacivert,
              labelStyle: TextStyle(
                color: identical(v, _varyant) ? Colors.white : lacivert,
                fontWeight: FontWeight.w600,
              ),
              showCheckmark: false,
            ),
        ]),
        const SizedBox(height: 20),
      ] else ...[
        Text('Ebat: ${ebatBicim(_varyant['ebat'] as String)}', style: const TextStyle(color: gri)),
        const SizedBox(height: 20),
      ],
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (indirimli != null)
            Row(children: [
              Text(tl(listeFiyati),
                  style: const TextStyle(color: gri, decoration: TextDecoration.lineThrough, fontSize: 15)),
              const SizedBox(width: 10),
              Rozet('%${((1 - indirimli / listeFiyati) * 100).round()} indirim', renk: kirmizi),
            ]),
          Text(tl(indirimli ?? listeFiyati),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: lacivert)),
          const Text('Birim fiyat · KDV dahil liste fiyatı', style: TextStyle(color: gri, fontSize: 12)),
          const SizedBox(height: 10),
          StokRozeti(stok),
        ]),
      ),
      const SizedBox(height: 20),
      Row(children: [
        AdetSecici(adet: _adet, max: stok < 1 ? 1 : stok, degisti: (a) => setState(() => _adet = a)),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: stok > 0 ? _sepeteEkle : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(stok > 0 ? 'Sepete Ekle · ${tl((indirimli ?? listeFiyati) * _adet)}' : 'Stokta yok'),
          ),
        ),
      ]),
    ]);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Stack(children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: genis
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    gorsel,
                    const SizedBox(width: 28),
                    Expanded(child: bilgiler),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    gorsel,
                    const SizedBox(height: 20),
                    bilgiler,
                  ]),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ),
        ]),
      ),
    );
  }
}
