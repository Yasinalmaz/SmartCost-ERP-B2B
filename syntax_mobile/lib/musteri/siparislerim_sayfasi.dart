import 'package:flutter/material.dart';

import '../api.dart';
import '../ortak.dart';
import '../tema.dart';

class SiparislerimSayfasi extends StatefulWidget {
  const SiparislerimSayfasi({super.key});

  @override
  State<SiparislerimSayfasi> createState() => _SiparislerimSayfasiState();
}

class _SiparislerimSayfasiState extends State<SiparislerimSayfasi> {
  late Future<List<dynamic>> _siparisler;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  // Not: gövde blok olmalı; "=>" ile yazılırsa setState'e Future döner ve hata verir.
  void _yukle() {
    _siparisler = Api.get('/siparislerim').then((v) => v as List<dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _siparisler,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Yukleniyor();
        if (snap.hasError) return HataGorunumu(hata: snap.error, tekrarDene: () => setState(_yukle));
        final liste = snap.data!;
        if (liste.isEmpty) {
          return const BosDurum(
            ikon: Icons.receipt_long_outlined,
            baslik: 'Henüz siparişiniz yok',
            aciklama: 'Onayladığınız siparişler ve PDF teklifleri burada listelenir.',
          );
        }
        final toplam = liste.fold<double>(
            0, (t, s) => t + ((s['durum'] == 'İptal') ? 0 : (s['toplam_tutar'] as num).toDouble()));
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                BolumBasligi(
                  'Siparişlerim',
                  alt: '${liste.length} sipariş · toplam ${tl(toplam)}',
                  sag: IconButton(
                    tooltip: 'Yenile',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(_yukle),
                  ),
                ),
                for (final s in liste) ...[
                  _SiparisKarti(siparis: s as Map<String, dynamic>),
                  const SizedBox(height: 14),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _SiparisKarti extends StatelessWidget {
  const _SiparisKarti({required this.siparis});
  final Map<String, dynamic> siparis;

  @override
  Widget build(BuildContext context) {
    final kalemler = siparis['kalemler'] as List<dynamic>;
    final durum = siparis['durum'] as String;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: DurumRozeti.renk(durum).withValues(alpha: 0.12),
          child: Icon(DurumRozeti.ikon(durum), color: DurumRozeti.renk(durum)),
        ),
        title: Row(children: [
          Text(siparis['seri_no'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: lacivert)),
          const SizedBox(width: 12),
          DurumRozeti(durum),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${tarihBicim(siparis['tarih'] as String)} · ${kalemler.length} kalem · ${siparis['urun_adedi']} adet',
            style: const TextStyle(color: gri),
          ),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(tl(siparis['toplam_tutar'] as num),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: lacivert)),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'PDF teklifi aç',
            icon: const Icon(Icons.picture_as_pdf_outlined, color: kirmizi),
            onPressed: () => Api.pdfAc(siparis['id'] as int),
          ),
          const Icon(Icons.expand_more),
        ]),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(children: [
              for (final k in kalemler)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(child: Text(k['urun_adi'] as String)),
                    SizedBox(width: 80, child: Text('× ${k['adet']}', textAlign: TextAlign.right)),
                    SizedBox(
                      width: 140,
                      child: Text(tl(k['tutar'] as num),
                          textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 360,
                  child: Column(children: [
                    TutarSatiri('Malzeme toplamı', siparis['malzeme_toplami'] as num),
                    TutarSatiri('Operasyon / işçilik (%15)', siparis['operasyon_gideri'] as num),
                    TutarSatiri('Kâr marjı (%20)', siparis['kar_marji'] as num),
                    TutarSatiri('Genel Toplam', siparis['toplam_tutar'] as num, vurgulu: true),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
