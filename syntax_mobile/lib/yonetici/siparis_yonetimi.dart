import 'package:flutter/material.dart';

import '../api.dart';
import '../ortak.dart';
import '../tema.dart';

const List<String> siparisDurumlari = ['Onaylandı', 'Hazırlanıyor', 'Kargoda', 'Teslim Edildi', 'İptal'];

class SiparisYonetimi extends StatefulWidget {
  const SiparisYonetimi({super.key});

  @override
  State<SiparisYonetimi> createState() => _SiparisYonetimiState();
}

class _SiparisYonetimiState extends State<SiparisYonetimi> {
  final _arama = TextEditingController();
  String _durum = '';
  late Future<List<dynamic>> _siparisler;

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
    _siparisler = Api.get('/admin/siparisler', {'durum': _durum, 'q': _arama.text.trim()})
        .then((v) => v as List<dynamic>);
  }

  Future<void> _durumDegistir(Map<String, dynamic> s, String yeni) async {
    if (yeni == s['durum']) return;
    if (yeni == 'İptal') {
      final emin = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Sipariş iptal edilsin mi?'),
          content: Text('${s['seri_no']} iptal edilecek ve ürünler stoğa geri eklenecek.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kirmizi),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('İptal Et'),
            ),
          ],
        ),
      );
      if (emin != true) return;
    }
    try {
      await Api.patch('/admin/siparisler/${s['id']}', {'durum': yeni});
      if (!mounted) return;
      bildir(context, '${s['seri_no']} → $yeni');
      setState(_yukle);
    } on ApiHata catch (e) {
      if (mounted) bildir(context, e.mesaj, hata: true);
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
            onSubmitted: (_) => setState(_yukle),
            decoration: const InputDecoration(
              hintText: 'Sipariş no veya müşteri ara',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        for (final d in ['', ...siparisDurumlari])
          ChoiceChip(
            label: Text(d.isEmpty ? 'Tümü' : d),
            selected: _durum == d,
            onSelected: (_) => setState(() {
              _durum = d;
              _yukle();
            }),
          ),
      ]),
      const SizedBox(height: 20),
      FutureBuilder<List<dynamic>>(
        future: _siparisler,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Yukleniyor();
          if (snap.hasError) return HataGorunumu(hata: snap.error, tekrarDene: () => setState(_yukle));
          final liste = snap.data!.cast<Map<String, dynamic>>();
          if (liste.isEmpty) {
            return const BosDurum(ikon: Icons.receipt_long_outlined, baslik: 'Sipariş bulunamadı');
          }
          return Card(
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(builder: (context, c) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: c.maxWidth),
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(zemin),
                    headingTextStyle: const TextStyle(color: gri, fontWeight: FontWeight.w700, fontSize: 12.5),
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 64,
                    columns: const [
                      DataColumn(label: Text('SİPARİŞ NO')),
                      DataColumn(label: Text('MÜŞTERİ')),
                      DataColumn(label: Text('TARİH')),
                      DataColumn(label: Text('ÜRÜN'), numeric: true),
                      DataColumn(label: Text('TUTAR'), numeric: true),
                      DataColumn(label: Text('DURUM')),
                      DataColumn(label: Text('İŞLEMLER')),
                    ],
                    rows: [
                      for (final s in liste)
                        DataRow(cells: [
                          DataCell(Text(s['seri_no'] as String, style: const TextStyle(fontWeight: FontWeight.w700))),
                          DataCell(Text(s['musteri_adi'] as String)),
                          DataCell(Text(tarihBicim(s['tarih'] as String))),
                          DataCell(Text('${s['urun_adedi']}')),
                          DataCell(Text(tl(s['toplam_tutar'] as num), style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(_DurumSecici(
                            durum: s['durum'] as String,
                            degisti: (d) => _durumDegistir(s, d),
                          )),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              tooltip: 'Detay',
                              icon: const Icon(Icons.visibility_outlined),
                              onPressed: () => siparisDetayGoster(context, s),
                            ),
                            IconButton(
                              tooltip: 'PDF',
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: kirmizi),
                              onPressed: () => Api.pdfAc(s['id'] as int),
                            ),
                          ])),
                        ]),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    ]);
  }
}

class _DurumSecici extends StatelessWidget {
  const _DurumSecici({required this.durum, required this.degisti});
  final String durum;
  final ValueChanged<String> degisti;

  @override
  Widget build(BuildContext context) {
    final iptal = durum == 'İptal';
    return PopupMenuButton<String>(
      enabled: !iptal,
      tooltip: iptal ? 'İptal edilmiş sipariş değiştirilemez' : 'Durumu değiştir',
      onSelected: degisti,
      itemBuilder: (_) => [
        for (final d in siparisDurumlari)
          PopupMenuItem(
            value: d,
            child: Row(children: [
              Icon(DurumRozeti.ikon(d), color: DurumRozeti.renk(d), size: 18),
              const SizedBox(width: 10),
              Text(d),
            ]),
          ),
      ],
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        DurumRozeti(durum),
        if (!iptal) const Icon(Icons.arrow_drop_down, color: gri),
      ]),
    );
  }
}

Future<void> siparisDetayGoster(BuildContext context, Map<String, dynamic> s) {
  final kalemler = (s['kalemler'] as List<dynamic>).cast<Map<String, dynamic>>();
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Row(children: [
        Text(s['seri_no'] as String),
        const SizedBox(width: 12),
        DurumRozeti(s['durum'] as String),
      ]),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${s['musteri_adi']} · ${tarihBicim(s['tarih'] as String)}', style: const TextStyle(color: gri)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Müşteri talebi', style: TextStyle(color: gri, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(s['talep'] as String),
              ]),
            ),
            const SizedBox(height: 12),
            for (final k in kalemler)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(child: Text(k['urun_adi'] as String)),
                  SizedBox(width: 60, child: Text('× ${k['adet']}', textAlign: TextAlign.right)),
                  SizedBox(width: 130, child: Text(tl(k['tutar'] as num), textAlign: TextAlign.right)),
                ]),
              ),
            const Divider(),
            TutarSatiri('Malzeme toplamı', s['malzeme_toplami'] as num),
            TutarSatiri('Operasyon / işçilik (%15)', s['operasyon_gideri'] as num),
            TutarSatiri('Kâr marjı (%20)', s['kar_marji'] as num),
            TutarSatiri('Genel Toplam', s['toplam_tutar'] as num, vurgulu: true),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Kapat')),
        FilledButton.icon(
          onPressed: () => Api.pdfAc(s['id'] as int),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('PDF'),
        ),
      ],
    ),
  );
}
