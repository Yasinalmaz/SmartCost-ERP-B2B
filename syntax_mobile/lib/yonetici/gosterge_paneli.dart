import 'package:flutter/material.dart';

import '../api.dart';
import '../ortak.dart';
import '../tema.dart';

class GostergePaneli extends StatefulWidget {
  const GostergePaneli({super.key, required this.sayfayaGit});
  final ValueChanged<int> sayfayaGit;

  @override
  State<GostergePaneli> createState() => _GostergePaneliState();
}

class _GostergePaneliState extends State<GostergePaneli> {
  late Future<Map<String, dynamic>> _ozet;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  void _yukle() {
    _ozet = Api.get('/admin/ozet').then((v) => v as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _ozet,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Yukleniyor();
        if (snap.hasError) return HataGorunumu(hata: snap.error, tekrarDene: () => setState(_yukle));
        final o = snap.data!;
        return LayoutBuilder(builder: (context, c) {
          final genis = c.maxWidth >= 1050;
          final kpiGenislik = genis ? (c.maxWidth - 56 - 16 * 2) / 3 : (c.maxWidth - 56 - 16) / 2;
          Widget kpi(Widget w) => SizedBox(width: kpiGenislik.clamp(220, 600).toDouble(), child: w);

          return RefreshIndicator(
            onRefresh: () async => setState(_yukle),
            child: ListView(padding: const EdgeInsets.all(28), children: [
              Row(children: [
                const Expanded(
                  child: Text('Bugünkü durum ve işletme özeti', style: TextStyle(color: gri)),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(_yukle),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Yenile'),
                ),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 16, runSpacing: 16, children: [
                kpi(KpiKart(
                  baslik: 'Toplam Ciro',
                  deger: tl(o['toplam_ciro'] as num),
                  ikon: Icons.payments_outlined,
                  renk: yesil,
                  alt: 'İptal edilenler hariç',
                )),
                kpi(KpiKart(
                  baslik: 'Sipariş Sayısı',
                  deger: '${o['siparis_sayisi']}',
                  ikon: Icons.receipt_long_outlined,
                  renk: const Color(0xFF2563EB),
                  alt: '${o['bekleyen_siparis']} sipariş işlem bekliyor',
                )),
                kpi(KpiKart(
                  baslik: 'Ortalama Sepet',
                  deger: tl(o['ortalama_sepet'] as num),
                  ikon: Icons.shopping_basket_outlined,
                  renk: const Color(0xFF7C3AED),
                )),
                kpi(KpiKart(
                  baslik: 'Kritik Stok',
                  deger: '${o['kritik_stok_sayisi']} ürün',
                  ikon: Icons.warning_amber_rounded,
                  renk: kirmizi,
                  alt: 'Stok 20 adedin altında',
                )),
                kpi(KpiKart(
                  baslik: 'Kayıtlı Müşteri',
                  deger: '${o['musteri_sayisi']}',
                  ikon: Icons.apartment_outlined,
                  renk: vurgu,
                )),
                kpi(KpiKart(
                  baslik: 'Stok Değeri',
                  deger: tl(o['stok_degeri'] as num),
                  ikon: Icons.inventory_2_outlined,
                  renk: const Color(0xFF0891B2),
                  alt: '${o['urun_sayisi']} ürün-ebat kalemi',
                )),
              ]),
              const SizedBox(height: 20),
              _ikili(
                genis,
                _KategoriSatis(veri: (o['kategori_satis'] as List<dynamic>).cast<Map<String, dynamic>>()),
                _EnCokSatan(veri: (o['en_cok_satan'] as List<dynamic>).cast<Map<String, dynamic>>()),
              ),
              const SizedBox(height: 20),
              _ikili(
                genis,
                _SonSiparisler(
                  veri: (o['son_siparisler'] as List<dynamic>).cast<Map<String, dynamic>>(),
                  tumunuGor: () => widget.sayfayaGit(1),
                ),
                _KritikStok(
                  veri: (o['kritik_stok'] as List<dynamic>).cast<Map<String, dynamic>>(),
                  yonet: () => widget.sayfayaGit(2),
                ),
              ),
            ]),
          );
        });
      },
    );
  }

  Widget _ikili(bool genis, Widget sol, Widget sag) {
    if (!genis) return Column(children: [sol, const SizedBox(height: 20), sag]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: sol),
      const SizedBox(width: 20),
      Expanded(flex: 2, child: sag),
    ]);
  }
}

class _PanelKarti extends StatelessWidget {
  const _PanelKarti({required this.baslik, required this.child, this.eylem});
  final String baslik;
  final Widget child;
  final Widget? eylem;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: lacivert)),
            ),
            if (eylem != null) eylem!,
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      ),
    );
  }
}

class _KategoriSatis extends StatelessWidget {
  const _KategoriSatis({required this.veri});
  final List<Map<String, dynamic>> veri;

  @override
  Widget build(BuildContext context) {
    final enBuyuk = veri.isEmpty ? 1.0 : (veri.first['tutar'] as num).toDouble();
    return _PanelKarti(
      baslik: 'Kategori Bazlı Satış',
      child: veri.isEmpty
          ? const Padding(padding: EdgeInsets.all(20), child: Text('Henüz satış yok.', style: TextStyle(color: gri)))
          : Column(children: [
              for (final k in veri.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    Icon(kategoriBilgi(k['kategori'] as String).ikon,
                        size: 18, color: kategoriBilgi(k['kategori'] as String).renk),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 150,
                      child: Text(kategoriBilgi(k['kategori'] as String).ad, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (k['tutar'] as num) / enBuyuk,
                          minHeight: 12,
                          backgroundColor: zemin,
                          color: kategoriBilgi(k['kategori'] as String).renk,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Text(tl(k['tutar'] as num),
                          textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
            ]),
    );
  }
}

class _EnCokSatan extends StatelessWidget {
  const _EnCokSatan({required this.veri});
  final List<Map<String, dynamic>> veri;

  @override
  Widget build(BuildContext context) {
    return _PanelKarti(
      baslik: 'En Çok Satan Ürünler',
      child: veri.isEmpty
          ? const Padding(padding: EdgeInsets.all(20), child: Text('Henüz satış yok.', style: TextStyle(color: gri)))
          : Column(children: [
              for (var i = 0; i < veri.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: i == 0 ? vurgu : zemin,
                    child: Text('${i + 1}',
                        style: TextStyle(color: i == 0 ? Colors.white : lacivert, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(veri[i]['urun_adi'] as String, overflow: TextOverflow.ellipsis),
                  trailing: Text('${veri[i]['adet']} adet', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ]),
    );
  }
}

class _SonSiparisler extends StatelessWidget {
  const _SonSiparisler({required this.veri, required this.tumunuGor});
  final List<Map<String, dynamic>> veri;
  final VoidCallback tumunuGor;

  @override
  Widget build(BuildContext context) {
    return _PanelKarti(
      baslik: 'Son Siparişler',
      eylem: TextButton(onPressed: tumunuGor, child: const Text('Tümünü gör →')),
      child: veri.isEmpty
          ? const Padding(padding: EdgeInsets.all(20), child: Text('Henüz sipariş yok.', style: TextStyle(color: gri)))
          : Column(children: [
              for (final s in veri)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    SizedBox(
                      width: 120,
                      child: Text(s['seri_no'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: Text(s['musteri_adi'] as String, overflow: TextOverflow.ellipsis)),
                    SizedBox(
                      width: 120,
                      child: Text(tarihBicim(s['tarih'] as String, saat: false), style: const TextStyle(color: gri)),
                    ),
                    SizedBox(width: 130, child: Align(alignment: Alignment.centerLeft, child: DurumRozeti(s['durum'] as String))),
                    SizedBox(
                      width: 120,
                      child: Text(tl(s['toplam_tutar'] as num),
                          textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
            ]),
    );
  }
}

class _KritikStok extends StatelessWidget {
  const _KritikStok({required this.veri, required this.yonet});
  final List<Map<String, dynamic>> veri;
  final VoidCallback yonet;

  @override
  Widget build(BuildContext context) {
    return _PanelKarti(
      baslik: 'Kritik Stok Uyarıları',
      eylem: TextButton(onPressed: yonet, child: const Text('Stok yönet →')),
      child: veri.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Row(children: [
                Icon(Icons.check_circle_outline, color: yesil),
                SizedBox(width: 8),
                Text('Tüm ürünlerin stoğu yeterli.'),
              ]),
            )
          : Column(children: [
              for (final u in veri.take(8))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.warning_amber_rounded, color: kirmizi),
                  title: Text(u['urun_adi'] as String, overflow: TextOverflow.ellipsis),
                  trailing: Rozet('${u['stok']} adet', renk: (u['stok'] as int) == 0 ? kirmizi : sari),
                ),
            ]),
    );
  }
}
