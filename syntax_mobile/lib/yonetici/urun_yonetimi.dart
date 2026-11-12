import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../ortak.dart';
import '../tema.dart';

class UrunYonetimi extends StatefulWidget {
  const UrunYonetimi({super.key});

  @override
  State<UrunYonetimi> createState() => _UrunYonetimiState();
}

class _UrunYonetimiState extends State<UrunYonetimi> {
  final _arama = TextEditingController();
  String _kategori = '';
  bool _sadeceKritik = false;
  int _sayfa = 1;
  static const _boyut = 25;
  late Future<Map<String, dynamic>> _veri;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _arama.dispose();
    super.dispose();
  }

  void _yukle() {
    _veri = Api.get('/admin/urunler', {
      'q': _arama.text.trim(),
      'kategori': _kategori,
      'sadece_kritik': _sadeceKritik ? 'true' : null,
      'sayfa': _sayfa,
      'boyut': _boyut,
    }).then((v) => v as Map<String, dynamic>);
  }

  void _filtrele(VoidCallback degisiklik) => setState(() {
        degisiklik();
        _sayfa = 1;
        _yukle();
      });

  Future<void> _duzenle(Map<String, dynamic> u) async {
    final guncellendi = await showDialog<bool>(context: context, builder: (_) => _UrunDuzenle(urun: u));
    if (guncellendi == true && mounted) {
      bildir(context, '${u['urun_adi']} güncellendi');
      setState(_yukle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(28), children: [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: _arama,
            onSubmitted: (_) => _filtrele(() {}),
            decoration: const InputDecoration(hintText: 'Ürün adı veya ebat ara', prefixIcon: Icon(Icons.search)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: cizgi),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _kategori,
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm kategoriler')),
                for (final e in kategoriBilgileri.entries) DropdownMenuItem(value: e.key, child: Text(e.value.ad)),
              ],
              onChanged: (v) => _filtrele(() => _kategori = v ?? ''),
            ),
          ),
        ),
        FilterChip(
          avatar: const Icon(Icons.warning_amber_rounded, size: 18, color: kirmizi),
          label: const Text('Sadece kritik stok'),
          selected: _sadeceKritik,
          onSelected: (v) => _filtrele(() => _sadeceKritik = v),
        ),
      ]),
      const SizedBox(height: 20),
      FutureBuilder<Map<String, dynamic>>(
        future: _veri,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Yukleniyor();
          if (snap.hasError) return HataGorunumu(hata: snap.error, tekrarDene: () => setState(_yukle));
          final toplam = snap.data!['toplam'] as int;
          final urunler = (snap.data!['urunler'] as List<dynamic>).cast<Map<String, dynamic>>();
          if (urunler.isEmpty) return const BosDurum(ikon: Icons.inventory_2_outlined, baslik: 'Ürün bulunamadı');
          final baslangic = (_sayfa - 1) * _boyut + 1;
          final bitis = baslangic + urunler.length - 1;
          final sonSayfa = bitis >= toplam;

          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              LayoutBuilder(builder: (context, c) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: c.maxWidth),
                    child: DataTable(
                      headingRowColor: const WidgetStatePropertyAll(zemin),
                      headingTextStyle: const TextStyle(color: gri, fontWeight: FontWeight.w700, fontSize: 12.5),
                      columns: const [
                        DataColumn(label: Text('ÜRÜN')),
                        DataColumn(label: Text('KATEGORİ')),
                        DataColumn(label: Text('EBAT')),
                        DataColumn(label: Text('LİSTE FİYATI'), numeric: true),
                        DataColumn(label: Text('SATIŞ FİYATI'), numeric: true),
                        DataColumn(label: Text('STOK'), numeric: true),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final u in urunler)
                          DataRow(cells: [
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                              KategoriGorseli(kategori: u['kategori'] as String, boyut: 34, yuvarlak: 8),
                              const SizedBox(width: 10),
                              Text(u['urun_adi'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ])),
                            DataCell(Text(kategoriBilgi(u['kategori'] as String).ad)),
                            DataCell(Text(ebatBicim(u['ebat'] as String))),
                            DataCell(Text(tl(u['liste_fiyati'] as num))),
                            DataCell(Text(tl(u['fiyat'] as num),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: u['indirimli_fiyat'] != null ? kirmizi : null,
                                ))),
                            DataCell(_StokHucresi(stok: u['stok'] as int)),
                            DataCell(IconButton(
                              tooltip: 'Fiyat / stok düzenle',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _duzenle(u),
                            )),
                          ]),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Text('$baslangic–$bitis / $toplam ürün', style: const TextStyle(color: gri)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Önceki sayfa',
                    onPressed: _sayfa > 1
                        ? () => setState(() {
                              _sayfa--;
                              _yukle();
                            })
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Sayfa $_sayfa'),
                  IconButton(
                    tooltip: 'Sonraki sayfa',
                    onPressed: sonSayfa
                        ? null
                        : () => setState(() {
                              _sayfa++;
                              _yukle();
                            }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
    ]);
  }
}

class _StokHucresi extends StatelessWidget {
  const _StokHucresi({required this.stok});
  final int stok;

  @override
  Widget build(BuildContext context) {
    final renk = stok == 0 ? kirmizi : (stok < 20 ? sari : yesil);
    return Rozet('$stok adet', renk: renk);
  }
}

class _UrunDuzenle extends StatefulWidget {
  const _UrunDuzenle({required this.urun});
  final Map<String, dynamic> urun;

  @override
  State<_UrunDuzenle> createState() => _UrunDuzenleState();
}

class _UrunDuzenleState extends State<_UrunDuzenle> {
  late final TextEditingController _fiyat;
  late final TextEditingController _stok;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _fiyat = TextEditingController(text: (widget.urun['liste_fiyati'] as num).toStringAsFixed(2));
    _stok = TextEditingController(text: '${widget.urun['stok']}');
  }

  @override
  void dispose() {
    _fiyat.dispose();
    _stok.dispose();
    super.dispose();
  }

  void _stokEkle(int miktar) {
    final mevcut = int.tryParse(_stok.text) ?? 0;
    setState(() => _stok.text = '${mevcut + miktar}');
  }

  Future<void> _kaydet() async {
    final fiyat = double.tryParse(_fiyat.text.replaceAll(',', '.'));
    final stok = int.tryParse(_stok.text);
    if (fiyat == null || fiyat <= 0 || stok == null || stok < 0) {
      bildir(context, 'Geçerli bir fiyat ve stok girin.', hata: true);
      return;
    }
    final govde = <String, Object>{'stok_adedi': stok};
    if ((fiyat - (widget.urun['liste_fiyati'] as num)).abs() > 0.001) govde['birim_fiyati'] = fiyat;

    setState(() => _kaydediliyor = true);
    try {
      await Api.patch('/admin/urunler/${widget.urun['id']}', govde);
      if (mounted) Navigator.pop(context, true);
    } on ApiHata catch (e) {
      if (mounted) {
        setState(() => _kaydediliyor = false);
        bildir(context, e.mesaj, hata: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ürünü Düzenle'),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.urun['urun_adi'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: lacivert)),
          Text(kategoriBilgi(widget.urun['kategori'] as String).ad, style: const TextStyle(color: gri)),
          const SizedBox(height: 18),
          TextField(
            controller: _fiyat,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: const InputDecoration(labelText: 'Liste fiyatı (₺)', prefixIcon: Icon(Icons.sell_outlined)),
          ),
          if (widget.urun['indirimli_fiyat'] != null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Not: Fiyatı değiştirirseniz kampanya indirimi kaldırılır.',
                  style: TextStyle(color: sari, fontSize: 12)),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _stok,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Stok adedi', prefixIcon: Icon(Icons.inventory_2_outlined)),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final m in [10, 25, 50, 100])
              ActionChip(label: Text('+$m'), onPressed: () => _stokEkle(m)),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: _kaydediliyor ? null : () => Navigator.pop(context, false), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: _kaydediliyor ? null : _kaydet,
          child: _kaydediliyor
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
