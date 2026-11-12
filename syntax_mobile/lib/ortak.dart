import 'package:flutter/material.dart';

import 'tema.dart';

void bildir(BuildContext context, String mesaj, {bool hata = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(hata ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(mesaj)),
      ]),
      backgroundColor: hata ? kirmizi : lacivert,
      width: 520,
    ));
}

class Yukleniyor extends StatelessWidget {
  const Yukleniyor({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
}

class HataGorunumu extends StatelessWidget {
  const HataGorunumu({super.key, required this.hata, required this.tekrarDene});
  final Object? hata;
  final VoidCallback tekrarDene;

  @override
  Widget build(BuildContext context) => BosDurum(
        ikon: Icons.cloud_off_outlined,
        baslik: 'Veriler yüklenemedi',
        aciklama: '$hata',
        eylem: OutlinedButton.icon(
          onPressed: tekrarDene,
          icon: const Icon(Icons.refresh),
          label: const Text('Tekrar dene'),
        ),
      );
}

class BosDurum extends StatelessWidget {
  const BosDurum({super.key, required this.ikon, required this.baslik, this.aciklama, this.eylem});
  final IconData ikon;
  final String baslik;
  final String? aciklama;
  final Widget? eylem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(ikon, size: 44, color: gri),
          ),
          const SizedBox(height: 18),
          Text(baslik, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          if (aciklama != null) ...[
            const SizedBox(height: 6),
            Text(aciklama!, textAlign: TextAlign.center, style: const TextStyle(color: gri)),
          ],
          if (eylem != null) ...[const SizedBox(height: 18), eylem!],
        ]),
      ),
    );
  }
}

/// Ürün fotoğrafı yerine kategoriye özel renkli görsel.
class KategoriGorseli extends StatelessWidget {
  const KategoriGorseli({super.key, required this.kategori, this.boyut, this.yuvarlak = 12, this.ikonBoyutu});
  final String kategori;
  final double? boyut;
  final double yuvarlak;
  final double? ikonBoyutu;

  @override
  Widget build(BuildContext context) {
    final b = kategoriBilgi(kategori);
    return Container(
      width: boyut,
      height: boyut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(yuvarlak),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [b.renk.withValues(alpha: 0.10), b.renk.withValues(alpha: 0.28)],
        ),
      ),
      child: Center(child: Icon(b.ikon, size: ikonBoyutu ?? (boyut ?? 120) * 0.45, color: b.renk)),
    );
  }
}

class Rozet extends StatelessWidget {
  const Rozet(this.metin, {super.key, required this.renk, this.ikon});
  final String metin;
  final Color renk;
  final IconData? ikon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (ikon != null) ...[Icon(ikon, size: 14, color: renk), const SizedBox(width: 4)],
        Text(metin, style: TextStyle(color: renk, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }
}

class DurumRozeti extends StatelessWidget {
  const DurumRozeti(this.durum, {super.key});
  final String durum;

  static Color renk(String durum) => switch (durum) {
        'Onaylandı' => const Color(0xFF2563EB),
        'Hazırlanıyor' => sari,
        'Kargoda' => const Color(0xFF7C3AED),
        'Teslim Edildi' => yesil,
        'İptal' => kirmizi,
        _ => gri,
      };

  static IconData ikon(String durum) => switch (durum) {
        'Onaylandı' => Icons.task_alt,
        'Hazırlanıyor' => Icons.inventory_2_outlined,
        'Kargoda' => Icons.local_shipping_outlined,
        'Teslim Edildi' => Icons.done_all,
        'İptal' => Icons.cancel_outlined,
        _ => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) => Rozet(durum, renk: renk(durum), ikon: ikon(durum));
}

class StokRozeti extends StatelessWidget {
  const StokRozeti(this.stok, {super.key});
  final int stok;

  @override
  Widget build(BuildContext context) {
    if (stok <= 0) return const Rozet('Tükendi', renk: kirmizi);
    if (stok < 20) return Rozet('Son $stok adet', renk: sari);
    return const Rozet('Stokta', renk: yesil);
  }
}

class AdetSecici extends StatelessWidget {
  const AdetSecici({super.key, required this.adet, required this.degisti, this.min = 1, this.max = 9999});
  final int adet;
  final ValueChanged<int> degisti;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(border: Border.all(color: cizgi), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove, size: 18),
          onPressed: adet > min ? () => degisti(adet - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text('$adet', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add, size: 18),
          onPressed: adet < max ? () => degisti(adet + 1) : null,
        ),
      ]),
    );
  }
}

class KpiKart extends StatelessWidget {
  const KpiKart({super.key, required this.baslik, required this.deger, required this.ikon, required this.renk, this.alt});
  final String baslik;
  final String deger;
  final IconData ikon;
  final Color renk;
  final String? alt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(ikon, color: renk),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(baslik, style: const TextStyle(color: gri, fontSize: 13)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(deger, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: lacivert)),
              ),
              if (alt != null) Text(alt!, style: const TextStyle(color: gri, fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class BolumBasligi extends StatelessWidget {
  const BolumBasligi(this.baslik, {super.key, this.alt, this.sag});
  final String baslik;
  final String? alt;
  final Widget? sag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(baslik,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: lacivert)),
            if (alt != null) Text(alt!, style: const TextStyle(color: gri)),
          ]),
        ),
        if (sag != null) sag!,
      ]),
    );
  }
}

/// Toplam satırı (etiket ...... tutar)
class TutarSatiri extends StatelessWidget {
  const TutarSatiri(this.etiket, this.tutar, {super.key, this.vurgulu = false});
  final String etiket;
  final num tutar;
  final bool vurgulu;

  @override
  Widget build(BuildContext context) {
    final stil = vurgulu
        ? const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: lacivert)
        : const TextStyle(color: Color(0xFF374151));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(etiket, style: stil)),
        Text(tl(tutar), style: stil),
      ]),
    );
  }
}
