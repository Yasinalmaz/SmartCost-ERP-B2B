import 'package:flutter/material.dart';

import '../api.dart';
import '../ortak.dart';
import '../sepet.dart';
import '../tema.dart';

class AkilliSiparisSayfasi extends StatefulWidget {
  const AkilliSiparisSayfasi({super.key, required this.sepeteGit});
  final VoidCallback sepeteGit;

  @override
  State<AkilliSiparisSayfasi> createState() => _AkilliSiparisSayfasiState();
}

class _Bulunan {
  _Bulunan(this.urun) : adet = urun['adet'] as int;
  final Map<String, dynamic> urun;
  int adet;
  bool secili = true;
}

class _AkilliSiparisSayfasiState extends State<AkilliSiparisSayfasi> {
  final _metin = TextEditingController();
  List<_Bulunan>? _bulunanlar;
  List<String> _anlasilmayan = [];
  bool _bekliyor = false;

  static const _ornekler = [
    'Otelimiz için 20 adet golden yatak 90x200, 20 adet golden prime baza 90x200 ve 40 tane microfiber yastık lazım.',
    '5 adet blacksand yatak 160x200, 5 blacksand baza 160x200 ve 5 tane blacksand başlık 160',
    '30 adet pamuk alez 100x200; 30 adet microfiber yorgan tek kişilik; 60 adet bambu yastık',
  ];

  @override
  void dispose() {
    _metin.dispose();
    super.dispose();
  }

  Future<void> _analizEt() async {
    if (_metin.text.trim().isEmpty) {
      bildir(context, 'Lütfen sipariş metninizi yazın.', hata: true);
      return;
    }
    setState(() => _bekliyor = true);
    try {
      final cevap = await Api.post('/metin-ayristir', {'talep': _metin.text}) as Map<String, dynamic>;
      setState(() {
        _bulunanlar = [
          for (final k in cevap['kalemler'] as List<dynamic>) _Bulunan(k as Map<String, dynamic>),
        ];
        _anlasilmayan = (cevap['anlasilmayan'] as List<dynamic>).cast<String>();
      });
    } on ApiHata catch (e) {
      if (mounted) bildir(context, e.mesaj, hata: true);
    } finally {
      if (mounted) setState(() => _bekliyor = false);
    }
  }

  void _sepeteEkle() {
    final secilenler = _bulunanlar!.where((b) => b.secili).toList();
    for (final b in secilenler) {
      sepet.ekle(b.urun, b.adet);
    }
    sepet.talep = _metin.text;
    bildir(context, '${secilenler.length} ürün sepete eklendi');
    setState(() {
      _bulunanlar = null;
      _anlasilmayan = [];
      _metin.clear();
    });
    widget.sepeteGit();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const BolumBasligi(
              'Akıllı Sipariş',
              alt: 'Siparişinizi e-posta yazar gibi yazın; ürünler, ebatlar ve adetler otomatik tanınsın.',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextField(
                    controller: _metin,
                    minLines: 5,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Örn: 12 adet golden yatak 90x200, 12 golden prime baza 90x200 ve 24 tane kaz tüyü yastık',
                      fillColor: zemin,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Örnek siparişler', style: TextStyle(color: gri, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < _ornekler.length; i++)
                      ActionChip(
                        avatar: const Icon(Icons.bolt, size: 16, color: vurgu),
                        label: Text('Örnek ${i + 1}'),
                        tooltip: _ornekler[i],
                        onPressed: () => setState(() => _metin.text = _ornekler[i]),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: vurgu, padding: const EdgeInsets.symmetric(horizontal: 26)),
                      onPressed: _bekliyor ? null : _analizEt,
                      icon: _bekliyor
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome),
                      label: const Text('Siparişi Analiz Et'),
                    ),
                  ),
                ]),
              ),
            ),
            if (_bulunanlar != null) ...[
              const SizedBox(height: 24),
              _sonuclar(),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _sonuclar() {
    final bulunanlar = _bulunanlar!;
    final secilenler = bulunanlar.where((b) => b.secili);
    final toplam = secilenler.fold<double>(0, (t, b) => t + (b.urun['fiyat'] as num) * b.adet);

    return Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(children: [
            const Icon(Icons.fact_check_outlined, color: yesil),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${bulunanlar.length} ürün tanındı',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: lacivert)),
            ),
            const Text('Kontrol edip sepete ekleyin', style: TextStyle(color: gri)),
          ]),
        ),
        const Divider(),
        if (bulunanlar.isEmpty)
          const BosDurum(
            ikon: Icons.search_off,
            baslik: 'Hiçbir ürün tanınamadı',
            aciklama: 'Ürün adını ve ebadı (ör. 160x200) yazdığınızdan emin olun.',
          ),
        for (final b in bulunanlar) _BulunanSatiri(
          bulunan: b,
          degisti: () => setState(() {}),
        ),
        if (_anlasilmayan.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sari.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sari.withValues(alpha: 0.3)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.help_outline, color: sari),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tanınamayan ifadeler', style: TextStyle(fontWeight: FontWeight.w700, color: sari)),
                  const SizedBox(height: 4),
                  Text(_anlasilmayan.map((a) => '“$a”').join('   ·   ')),
                  const SizedBox(height: 4),
                  const Text('Bu ürünler katalogda bulunamadı; ürün sayfasından arayarak ekleyebilirsiniz.',
                      style: TextStyle(color: gri, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        if (bulunanlar.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${secilenler.length} ürün seçili', style: const TextStyle(color: gri)),
                  Text(tl(toplam), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: lacivert)),
                ]),
              ),
              FilledButton.icon(
                onPressed: secilenler.isEmpty ? null : _sepeteEkle,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Seçilenleri Sepete Ekle'),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _BulunanSatiri extends StatelessWidget {
  const _BulunanSatiri({required this.bulunan, required this.degisti});
  final _Bulunan bulunan;
  final VoidCallback degisti;

  @override
  Widget build(BuildContext context) {
    final u = bulunan.urun;
    final stok = u['stok'] as int;
    final yetersiz = bulunan.adet > stok;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        Checkbox(
          value: bulunan.secili,
          onChanged: (v) {
            bulunan.secili = v ?? false;
            degisti();
          },
        ),
        KategoriGorseli(kategori: u['kategori'] as String, boyut: 52, yuvarlak: 10),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u['urun_adi'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: lacivert)),
            const SizedBox(height: 2),
            Text('Metinde: “${u['kaynak_metin']}”',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: gri, fontSize: 12, fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${tl(u['fiyat'] as num)} / adet', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 10),
              if (yetersiz) Rozet('Stok yetersiz ($stok)', renk: kirmizi) else StokRozeti(stok),
            ]),
          ]),
        ),
        const SizedBox(width: 12),
        AdetSecici(
          adet: bulunan.adet,
          degisti: (a) {
            bulunan.adet = a;
            degisti();
          },
        ),
        SizedBox(
          width: 130,
          child: Text(tl((u['fiyat'] as num) * bulunan.adet),
              textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
      ]),
    );
  }
}
