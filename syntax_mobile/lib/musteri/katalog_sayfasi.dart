import 'package:flutter/material.dart';

import '../api.dart';
import '../ortak.dart';
import '../tema.dart';
import 'urun_detay.dart';

class KatalogSayfasi extends StatefulWidget {
  const KatalogSayfasi({super.key, required this.arama, required this.akilliSiparisAc});
  final ValueNotifier<String> arama;
  final VoidCallback akilliSiparisAc;

  @override
  State<KatalogSayfasi> createState() => _KatalogSayfasiState();
}

class _KatalogSayfasiState extends State<KatalogSayfasi> {
  String _kategori = '';
  String _siralama = 'onerilen';
  late Future<List<dynamic>> _urunler;
  late Future<List<dynamic>> _kategoriler;

  static const _siralamalar = {
    'onerilen': 'Önerilen',
    'artan': 'Fiyat: Artan',
    'azalan': 'Fiyat: Azalan',
    'ad': 'Ada göre (A-Z)',
  };

  @override
  void initState() {
    super.initState();
    _kategoriler = _kategorileriGetir();
    _yukle();
    widget.arama.addListener(_aramaDegisti);
  }

  @override
  void dispose() {
    widget.arama.removeListener(_aramaDegisti);
    super.dispose();
  }

  Future<List<dynamic>> _kategorileriGetir() async {
    final liste = (await Api.get('/kategoriler')) as List<dynamic>;
    final sira = kategoriBilgileri.keys.toList();
    int konum(dynamic k) {
      final i = sira.indexOf(k['kategori'] as String);
      return i < 0 ? 999 : i;
    }

    liste.sort((a, b) => konum(a).compareTo(konum(b)));
    return liste;
  }

  void _aramaDegisti() => setState(() {
        if (widget.arama.value.isNotEmpty) _kategori = '';
        _yukle();
      });

  void _yukle() {
    _urunler = Api.get('/katalog', {
      'kategori': _kategori,
      'q': widget.arama.value,
      'siralama': _siralama,
    }).then((v) => v as List<dynamic>);
  }

  void _kategoriSec(String k) => setState(() {
        _kategori = k;
        _yukle();
      });

  @override
  Widget build(BuildContext context) {
    final genislik = MediaQuery.sizeOf(context).width;
    final genis = genislik >= 1100;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (genis)
        SizedBox(
          width: 270,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 24, 8, 24),
            child: _KategoriMenusu(kategoriler: _kategoriler, secili: _kategori, secildi: _kategoriSec),
          ),
        ),
      Expanded(
        child: FutureBuilder<List<dynamic>>(
          future: _urunler,
          builder: (context, snap) {
            return CustomScrollView(slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(genis ? 16 : 16, 24, genis ? 32 : 16, 0),
                sliver: SliverList.list(children: [
                  if (_kategori.isEmpty && widget.arama.value.isEmpty) ...[
                    _Afis(akilliSiparisAc: widget.akilliSiparisAc),
                    const SizedBox(height: 24),
                  ],
                  if (!genis) ...[
                    _KategoriCipleri(kategoriler: _kategoriler, secili: _kategori, secildi: _kategoriSec),
                    const SizedBox(height: 16),
                  ],
                  _baslik(snap),
                ]),
              ),
              if (snap.connectionState != ConnectionState.done)
                const SliverToBoxAdapter(child: Yukleniyor())
              else if (snap.hasError)
                SliverToBoxAdapter(
                  child: HataGorunumu(hata: snap.error, tekrarDene: () => setState(_yukle)),
                )
              else if (snap.data!.isEmpty)
                const SliverToBoxAdapter(
                  child: BosDurum(
                    ikon: Icons.search_off,
                    baslik: 'Ürün bulunamadı',
                    aciklama: 'Farklı bir arama yapmayı ya da kategoriyi değiştirmeyi deneyin.',
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, genis ? 32 : 16, 32),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 290,
                      mainAxisExtent: 390,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    itemCount: snap.data!.length,
                    itemBuilder: (context, i) => UrunKarti(grup: snap.data![i] as Map<String, dynamic>),
                  ),
                ),
            ]);
          },
        ),
      ),
    ]);
  }

  Widget _baslik(AsyncSnapshot<List<dynamic>> snap) {
    final String baslik;
    if (widget.arama.value.isNotEmpty) {
      baslik = '"${widget.arama.value}" için sonuçlar';
    } else if (_kategori.isNotEmpty) {
      baslik = kategoriBilgi(_kategori).ad;
    } else {
      baslik = 'Tüm Ürünler';
    }
    final adet = snap.hasData ? '${snap.data!.length} ürün' : '';
    return BolumBasligi(
      baslik,
      alt: adet,
      sag: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: cizgi),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _siralama,
            icon: const Icon(Icons.sort),
            items: [
              for (final e in _siralamalar.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() {
              _siralama = v!;
              _yukle();
            }),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- vitrin afişi
class _Afis extends StatelessWidget {
  const _Afis({required this.akilliSiparisAc});
  final VoidCallback akilliSiparisAc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [lacivert, lacivertAcik]),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Rozet('YENİ', renk: vurgu, ikon: Icons.auto_awesome),
            const SizedBox(height: 14),
            const Text('Siparişinizi yazın, teklifiniz hazır olsun.',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '"20 adet golden yatak 90x200 ve 40 tane microfiber yastık" gibi yazmanız yeterli. '
              'Ürünler, ebatlar ve adetler otomatik tanınır, stok anında kontrol edilir.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: vurgu),
              onPressed: akilliSiparisAc,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Akıllı Sipariş Oluştur'),
            ),
          ]),
        ),
        if (MediaQuery.sizeOf(context).width > 1000) ...[
          const SizedBox(width: 32),
          Icon(Icons.king_bed_outlined, size: 140, color: Colors.white.withValues(alpha: 0.15)),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------- kategoriler
class _KategoriMenusu extends StatelessWidget {
  const _KategoriMenusu({required this.kategoriler, required this.secili, required this.secildi});
  final Future<List<dynamic>> kategoriler;
  final String secili;
  final ValueChanged<String> secildi;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: FutureBuilder<List<dynamic>>(
          future: kategoriler,
          builder: (context, snap) {
            if (!snap.hasData) return const Yukleniyor();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Text('KATEGORİLER', style: TextStyle(color: gri, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              _satir(Icons.apps, 'Tüm Ürünler', '', null),
              for (final k in snap.data!)
                _satir(
                  kategoriBilgi(k['kategori'] as String).ikon,
                  kategoriBilgi(k['kategori'] as String).ad,
                  k['kategori'] as String,
                  k['model_sayisi'] as int,
                ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _satir(IconData ikon, String ad, String kod, int? adet) {
    final aktif = secili == kod;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: aktif ? lacivert.withValues(alpha: 0.07) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => secildi(kod),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(children: [
              Icon(ikon, size: 19, color: aktif ? vurgu : gri),
              const SizedBox(width: 10),
              Expanded(
                child: Text(ad,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: aktif ? lacivert : const Color(0xFF374151),
                      fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              if (adet != null) Text('$adet', style: const TextStyle(color: gri, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _KategoriCipleri extends StatelessWidget {
  const _KategoriCipleri({required this.kategoriler, required this.secili, required this.secildi});
  final Future<List<dynamic>> kategoriler;
  final String secili;
  final ValueChanged<String> secildi;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: kategoriler,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 40);
        final kodlar = ['', ...snap.data!.map((k) => k['kategori'] as String)];
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kodlar.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => ChoiceChip(
              label: Text(kodlar[i].isEmpty ? 'Tümü' : kategoriBilgi(kodlar[i]).ad),
              selected: secili == kodlar[i],
              onSelected: (_) => secildi(kodlar[i]),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- ürün kartı
class UrunKarti extends StatelessWidget {
  const UrunKarti({super.key, required this.grup});
  final Map<String, dynamic> grup;

  @override
  Widget build(BuildContext context) {
    final kategori = grup['kategori'] as String;
    final varyantlar = grup['varyantlar'] as List<dynamic>;
    final minFiyat = grup['min_fiyat'] as num;
    final kampanyali = grup['kampanyali'] as bool;
    final toplamStok = grup['toplam_stok'] as int;
    final tekVaryant = varyantlar.length == 1;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => urunDetayGoster(context, grup),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(children: [
            SizedBox(height: 160, width: double.infinity, child: KategoriGorseli(kategori: kategori, yuvarlak: 0, ikonBoyutu: 64)),
            if (kampanyali)
              const Positioned(
                left: 12,
                top: 12,
                child: Rozet('%60 İNDİRİM', renk: kirmizi, ikon: Icons.local_offer),
              ),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(kategoriBilgi(kategori).ad.toUpperCase(),
                    style: const TextStyle(color: gri, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text(grup['model'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: lacivert, height: 1.25)),
                const SizedBox(height: 6),
                Text(
                  tekVaryant
                      ? ebatBicim(varyantlar.first['ebat'] as String)
                      : '${varyantlar.length} ebat seçeneği',
                  style: const TextStyle(color: gri, fontSize: 13),
                ),
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (!tekVaryant) const Text('başlayan fiyatlarla', style: TextStyle(color: gri, fontSize: 11)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(tl(minFiyat),
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: lacivert)),
                      ),
                    ]),
                  ),
                  StokRozeti(tekVaryant ? varyantlar.first['stok'] as int : toplamStok),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => urunDetayGoster(context, grup),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: Text(tekVaryant ? 'Sepete Ekle' : 'Ebat Seç'),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
