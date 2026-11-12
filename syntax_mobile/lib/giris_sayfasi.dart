import 'package:flutter/material.dart';

import 'api.dart';
import 'ortak.dart';
import 'tema.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _form = GlobalKey<FormState>();
  final _eposta = TextEditingController();
  final _sifre = TextEditingController();
  final _adSoyad = TextEditingController();
  final _firma = TextEditingController();
  bool _kayitModu = false;
  bool _sifreGizli = true;
  bool _bekliyor = false;

  @override
  void dispose() {
    for (final c in [_eposta, _sifre, _adSoyad, _firma]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _gonder() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _bekliyor = true);
    try {
      if (_kayitModu) {
        await Api.kayitOl(
          eposta: _eposta.text.trim(),
          sifre: _sifre.text,
          adSoyad: _adSoyad.text.trim(),
          firma: _firma.text.trim(),
        );
      } else {
        await Api.girisYap(_eposta.text.trim(), _sifre.text);
      }
    } on ApiHata catch (e) {
      if (mounted) bildir(context, e.mesaj, hata: true);
    } finally {
      if (mounted) setState(() => _bekliyor = false);
    }
  }

  void _demoDoldur(String eposta, String sifre) {
    setState(() => _kayitModu = false);
    _eposta.text = eposta;
    _sifre.text = sifre;
  }

  @override
  Widget build(BuildContext context) {
    final genis = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(children: [
        if (genis) const Expanded(flex: 5, child: _TanitimPaneli()),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _formIcerigi(context, genis),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _formIcerigi(BuildContext context, bool genis) {
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!genis) ...[const _Logo(koyu: true), const SizedBox(height: 32)],
        Text(
          _kayitModu ? 'Kurumsal hesap oluşturun' : 'Tekrar hoş geldiniz',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: lacivert),
        ),
        const SizedBox(height: 6),
        Text(
          _kayitModu
              ? 'Firmanız adına toplu sipariş ve teklif almak için kayıt olun.'
              : 'Hesabınıza giriş yaparak sipariş ve tekliflerinizi yönetin.',
          style: const TextStyle(color: gri),
        ),
        const SizedBox(height: 28),
        if (_kayitModu) ...[
          TextFormField(
            controller: _adSoyad,
            decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Ad soyad gerekli' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _firma,
            decoration: const InputDecoration(labelText: 'Firma unvanı', prefixIcon: Icon(Icons.apartment_outlined)),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Firma unvanı gerekli' : null,
          ),
          const SizedBox(height: 14),
        ],
        TextFormField(
          controller: _eposta,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.mail_outline)),
          validator: (v) => (v ?? '').contains('@') ? null : 'Geçerli bir e-posta girin',
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _sifre,
          obscureText: _sifreGizli,
          onFieldSubmitted: (_) => _gonder(),
          decoration: InputDecoration(
            labelText: 'Şifre',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_sifreGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
            ),
          ),
          validator: (v) => (v ?? '').length < (_kayitModu ? 6 : 1) ? 'Şifre en az 6 karakter olmalı' : null,
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _bekliyor ? null : _gonder,
          child: _bekliyor
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_kayitModu ? 'Hesap Oluştur' : 'Giriş Yap'),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_kayitModu ? 'Zaten hesabınız var mı?' : 'Hesabınız yok mu?', style: const TextStyle(color: gri)),
          TextButton(
            onPressed: () => setState(() => _kayitModu = !_kayitModu),
            child: Text(_kayitModu ? 'Giriş yapın' : 'Kurumsal kayıt'),
          ),
        ]),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),
        const Text('Demo hesaplar', style: TextStyle(color: gri, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _DemoKarti(
              ikon: Icons.storefront_outlined,
              baslik: 'Müşteri',
              alt: 'Yıldız Otelcilik',
              tiklandi: () => _demoDoldur('satinalma@yildizotel.com', '123456'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DemoKarti(
              ikon: Icons.admin_panel_settings_outlined,
              baslik: 'Yönetici',
              alt: 'ERP Paneli',
              tiklandi: () => _demoDoldur('admin@smartcost.com', 'admin123'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _DemoKarti extends StatelessWidget {
  const _DemoKarti({required this.ikon, required this.baslik, required this.alt, required this.tiklandi});
  final IconData ikon;
  final String baslik;
  final String alt;
  final VoidCallback tiklandi;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tiklandi,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(ikon, color: lacivert),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(baslik, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(alt, style: const TextStyle(color: gri, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.koyu = false});
  final bool koyu;

  @override
  Widget build(BuildContext context) {
    final renk = koyu ? lacivert : Colors.white;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: vurgu, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.bolt, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Text('SmartCost', style: TextStyle(color: renk, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(width: 6),
      Text('B2B', style: TextStyle(color: renk.withValues(alpha: 0.6), fontSize: 22, fontWeight: FontWeight.w300)),
    ]);
  }
}

class _TanitimPaneli extends StatelessWidget {
  const _TanitimPaneli();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lacivert, lacivertAcik],
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Logo(),
        const Spacer(),
        const Text(
          'Toplu siparişiniz,\nsaniyeler içinde resmi teklif.',
          style: TextStyle(color: Colors.white, fontSize: 40, height: 1.15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Text(
          'Otel, yurt ve kurumsal müşteriler için yatak, baza ve ev tekstili tedarik portalı. '
          'Siparişinizi yazın; ürünleri, ebatları ve adetleri sistem tanısın.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 36),
        const _Ozellik(Icons.auto_awesome, 'Akıllı sipariş', 'Serbest metinden otomatik ürün ve adet tespiti'),
        const _Ozellik(Icons.inventory_2_outlined, 'Anlık stok kontrolü', '1.400+ ürün, gerçek zamanlı stok'),
        const _Ozellik(Icons.picture_as_pdf_outlined, 'Resmi PDF teklif', 'Seri numaralı, şeffaf maliyet dökümü'),
        const Spacer(),
        Text('© 2026 SmartCost · İstanbul Gedik Üniversitesi',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      ]),
    );
  }
}

class _Ozellik extends StatelessWidget {
  const _Ozellik(this.ikon, this.baslik, this.aciklama);
  final IconData ikon;
  final String baslik;
  final String aciklama;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(ikon, color: vurgu),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          Text(aciklama, style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
        ]),
      ]),
    );
  }
}
