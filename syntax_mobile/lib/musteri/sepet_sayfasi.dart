import 'package:flutter/material.dart';

import '../api.dart';
import '../ortak.dart';
import '../sepet.dart';
import '../tema.dart';

class SepetSayfasi extends StatelessWidget {
  const SepetSayfasi({super.key, required this.alisveriseDon, required this.siparislerimeGit});
  final VoidCallback alisveriseDon;
  final VoidCallback siparislerimeGit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sepet,
      builder: (context, _) {
        if (sepet.bos) {
          return BosDurum(
            ikon: Icons.shopping_cart_outlined,
            baslik: 'Sepetiniz boş',
            aciklama: 'Ürünleri katalogdan ekleyebilir ya da Akıllı Sipariş ile tek seferde oluşturabilirsiniz.',
            eylem: FilledButton.icon(
              onPressed: alisveriseDon,
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Alışverişe Başla'),
            ),
          );
        }
        final genis = MediaQuery.sizeOf(context).width >= 1000;
        final liste = _SepetListesi();
        final ozet = _SiparisOzeti(siparislerimeGit: siparislerimeGit);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                BolumBasligi('Sepetim', alt: '${sepet.satirlar.length} kalem · ${sepet.toplamAdet} adet ürün'),
                if (genis)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: liste),
                    const SizedBox(width: 24),
                    SizedBox(width: 380, child: ozet),
                  ])
                else ...[
                  liste,
                  const SizedBox(height: 20),
                  ozet,
                ],
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _SepetListesi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(children: [
            Expanded(child: Text('ÜRÜN', style: _baslikStili)),
            SizedBox(width: 140, child: Text('ADET', style: _baslikStili, textAlign: TextAlign.center)),
            SizedBox(width: 130, child: Text('TUTAR', style: _baslikStili, textAlign: TextAlign.right)),
            SizedBox(width: 48),
          ]),
        ),
        const Divider(),
        for (final s in sepet.satirlar) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(children: [
              KategoriGorseli(kategori: s.kategori, boyut: 64, yuvarlak: 10),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.ad, style: const TextStyle(fontWeight: FontWeight.w700, color: lacivert)),
                  const SizedBox(height: 2),
                  Text('${kategoriBilgi(s.kategori).ad} · ${tl(s.fiyat)} / adet',
                      style: const TextStyle(color: gri, fontSize: 13)),
                  if (s.stokYetersiz) ...[
                    const SizedBox(height: 6),
                    Rozet('Stokta yalnızca ${s.stok} adet var', renk: kirmizi, ikon: Icons.warning_amber),
                  ],
                ]),
              ),
              SizedBox(
                width: 140,
                child: Center(
                  child: AdetSecici(adet: s.adet, degisti: (a) => sepet.adetAyarla(s.id, a)),
                ),
              ),
              SizedBox(
                width: 130,
                child: Text(tl(s.tutar),
                    textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              SizedBox(
                width: 48,
                child: IconButton(
                  tooltip: 'Kaldır',
                  icon: const Icon(Icons.delete_outline, color: gri),
                  onPressed: () => sepet.cikar(s.id),
                ),
              ),
            ]),
          ),
          const Divider(),
        ],
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: sepet.temizle,
              icon: const Icon(Icons.remove_shopping_cart_outlined, color: kirmizi),
              label: const Text('Sepeti Boşalt', style: TextStyle(color: kirmizi)),
            ),
          ),
        ),
      ]),
    );
  }
}

const _baslikStili = TextStyle(color: gri, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5);

class _SiparisOzeti extends StatelessWidget {
  const _SiparisOzeti({required this.siparislerimeGit});
  final VoidCallback siparislerimeGit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Sipariş Özeti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: lacivert)),
          const SizedBox(height: 14),
          TutarSatiri('Ürünler toplamı', sepet.malzeme),
          TutarSatiri('Operasyon / işçilik (%${(operasyonOrani * 100).round()})', sepet.operasyon),
          TutarSatiri('Kâr marjı (%${(karOrani * 100).round()})', sepet.kar),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
          TutarSatiri('Genel Toplam', sepet.genelToplam, vurgulu: true),
          const SizedBox(height: 4),
          const Text('KDV hariç teklif tutarıdır.', style: TextStyle(color: gri, fontSize: 12)),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: vurgu, minimumSize: const Size(0, 52)),
            onPressed: sepet.stokSorunuVar ? null : () => _teklifAl(context),
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Resmi Teklif Oluştur'),
          ),
          if (sepet.stokSorunuVar) ...[
            const SizedBox(height: 8),
            const Text('Stok yetersiz olan ürünlerin adedini düşürün.',
                style: TextStyle(color: kirmizi, fontSize: 12), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 18),
          const _Guvence(Icons.verified_outlined, 'Fiyatlar anlık stok ve liste fiyatıyla hesaplanır'),
          const _Guvence(Icons.lock_outline, 'Onaylamadan stoktan düşüm yapılmaz'),
          const _Guvence(Icons.picture_as_pdf_outlined, 'Onay sonrası seri numaralı PDF teklif'),
        ]),
      ),
    );
  }

  Future<void> _teklifAl(BuildContext context) async {
    final onaylandi = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _TeklifOnizleme(),
    );
    if (onaylandi == null || !context.mounted) return;
    final basari = showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: yesil, size: 56),
        title: const Text('Siparişiniz alındı'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Sipariş No: ${onaylandi['seri_no']}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: lacivert)),
          const SizedBox(height: 6),
          Text('Toplam: ${tl(onaylandi['toplam_tutar'] as num)}'),
          const SizedBox(height: 10),
          const Text('Stoklar güncellendi. Resmi teklif belgenizi indirebilirsiniz.',
              textAlign: TextAlign.center, style: TextStyle(color: gri)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              siparislerimeGit();
            },
            child: const Text('Siparişlerime Git'),
          ),
          FilledButton.icon(
            onPressed: () => Api.pdfAc(onaylandi['id'] as int),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF Teklifi Aç'),
          ),
        ],
      ),
    );
    sepet.temizle(); // dialog açıldıktan sonra sepeti boşalt
    await basari;
  }
}

class _Guvence extends StatelessWidget {
  const _Guvence(this.ikon, this.metin);
  final IconData ikon;
  final String metin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          Icon(ikon, size: 18, color: yesil),
          const SizedBox(width: 8),
          Expanded(child: Text(metin, style: const TextStyle(color: gri, fontSize: 12.5))),
        ]),
      );
}

/// 1. aşama: sunucudan resmi teklif dökümü alınır. 2. aşama: müşteri onaylar.
class _TeklifOnizleme extends StatefulWidget {
  const _TeklifOnizleme();

  @override
  State<_TeklifOnizleme> createState() => _TeklifOnizlemeState();
}

class _TeklifOnizlemeState extends State<_TeklifOnizleme> {
  late final Future<Map<String, dynamic>> _teklif;
  bool _onaylaniyor = false;

  @override
  void initState() {
    super.initState();
    _teklif = Api.post('/sepet/teklif', {'kalemler': sepet.istekKalemleri, 'talep': sepet.talep})
        .then((v) => v as Map<String, dynamic>);
  }

  Future<void> _onayla() async {
    setState(() => _onaylaniyor = true);
    try {
      final siparis = await Api.post('/sepet/onayla', {'kalemler': sepet.istekKalemleri, 'talep': sepet.talep})
          as Map<String, dynamic>;
      if (mounted) Navigator.pop(context, siparis);
    } on ApiHata catch (e) {
      if (mounted) {
        setState(() => _onaylaniyor = false);
        bildir(context, e.mesaj, hata: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.request_quote_outlined, color: lacivert),
        SizedBox(width: 10),
        Text('Teklif Önizleme'),
      ]),
      content: SizedBox(
        width: 640,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _teklif,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const SizedBox(height: 200, child: Yukleniyor());
            if (snap.hasError) return Text('${snap.error}', style: const TextStyle(color: kirmizi));
            final t = snap.data!;
            final hatalar = (t['stok_hatalari'] as List<dynamic>).cast<String>();
            return SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(),
                    1: FixedColumnWidth(60),
                    2: FixedColumnWidth(120),
                    3: FixedColumnWidth(130),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cizgi))),
                      children: [
                        _Hucre('Ürün', baslik: true),
                        _Hucre('Adet', baslik: true, sag: true),
                        _Hucre('Birim', baslik: true, sag: true),
                        _Hucre('Tutar', baslik: true, sag: true),
                      ],
                    ),
                    for (final k in t['kalemler'] as List<dynamic>)
                      TableRow(children: [
                        _Hucre(k['urun_adi'] as String),
                        _Hucre('${k['adet']}', sag: true),
                        _Hucre(tl(k['birim_fiyat'] as num), sag: true),
                        _Hucre(tl(k['tutar'] as num), sag: true),
                      ]),
                  ],
                ),
                const SizedBox(height: 14),
                TutarSatiri('Malzeme toplamı', t['malzeme_toplami'] as num),
                TutarSatiri('Operasyon / işçilik (%15)', t['operasyon_gideri'] as num),
                TutarSatiri('Kâr marjı (%20)', t['kar_marji'] as num),
                const Divider(),
                TutarSatiri('Genel Toplam', t['genel_toplam'] as num, vurgulu: true),
                if (hatalar.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Yetersiz stok: ${hatalar.join(', ')}',
                      style: const TextStyle(color: kirmizi, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    'Onayladığınızda ürünler stoktan düşülür ve sipariş seri numarasıyla kaydedilir.',
                    style: TextStyle(color: gri, fontSize: 13),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: _onaylaniyor ? null : () => Navigator.pop(context), child: const Text('Vazgeç')),
        FutureBuilder<Map<String, dynamic>>(
          future: _teklif,
          builder: (context, snap) {
            final hazir = snap.hasData && (snap.data!['stok_hatalari'] as List).isEmpty;
            return FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: yesil),
              onPressed: hazir && !_onaylaniyor ? _onayla : null,
              icon: _onaylaniyor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('Siparişi Onayla'),
            );
          },
        ),
      ],
    );
  }
}

class _Hucre extends StatelessWidget {
  const _Hucre(this.metin, {this.baslik = false, this.sag = false});
  final String metin;
  final bool baslik;
  final bool sag;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          metin,
          textAlign: sag ? TextAlign.right : TextAlign.left,
          style: baslik
              ? const TextStyle(color: gri, fontSize: 12, fontWeight: FontWeight.w700)
              : const TextStyle(fontSize: 13.5),
        ),
      );
}
