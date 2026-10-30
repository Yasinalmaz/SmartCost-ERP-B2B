import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

void main() {
  runApp(const SyntaxErpApp());
}

class SyntaxErpApp extends StatelessWidget {
  const SyntaxErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Syntax Kurumsal ERP & B2B Portal',
      theme: ThemeData(
        primaryColor: const Color(0xFF0F2027),
        scaffoldBackgroundColor: const Color(0xFFE2E8F0),
        useMaterial3: true,
      ),
      home: const AnaMerkez(),
    );
  }
}

// ---------------------------------------------------------
// ANA MERKEZ (ROL TABANLI YÖNLENDİRME VE SOL MENÜ)
// ---------------------------------------------------------
class AnaMerkez extends StatefulWidget {
  const AnaMerkez({super.key});

  @override
  State<AnaMerkez> createState() => _AnaMerkezState();
}

class _AnaMerkezState extends State<AnaMerkez> {
  String? _aktifRol;
  String _aktifMusteriAdi = '';
  int _seciliSayfa = 0;

  void _adminGirisYap() {
    setState(() {
      _aktifRol = 'admin';
      _aktifMusteriAdi = 'Sistem Yöneticisi';
      _seciliSayfa = 0;
    });
  }

  void _musteriGirisYap(String firmaAdi) {
    setState(() {
      _aktifRol = 'musteri';
      _aktifMusteriAdi = firmaAdi;
      _seciliSayfa = 0;
    });
  }

  void _cikisYap() {
    setState(() {
      _aktifRol = null;
      _aktifMusteriAdi = '';
      _seciliSayfa = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_aktifRol == null) {
      return GirisPortalEkrani(
        onAdminGiris: _adminGirisYap,
        onMusteriGiris: _musteriGirisYap,
      );
    }

    bool isAdmin = _aktifRol == 'admin';

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 270,
            color: const Color(0xFF0F2027),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.storefront,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'SYNTAX ERP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.amber.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAdmin ? 'Yönetici Paneli' : 'Müşteri: $_aktifMusteriAdi',
                          style: TextStyle(
                            color: isAdmin ? Colors.amberAccent : Colors.lightBlueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),

                if (isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.dashboard, color: Colors.white),
                    title: const Text(
                      'Genel Durum (Ciro)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    selected: _seciliSayfa == 0,
                    selectedTileColor: Colors.blue.withOpacity(0.3),
                    onTap: () => setState(() => _seciliSayfa = 0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory, color: Colors.white),
                    title: const Text(
                      'Depo & Stok Yönetimi',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    selected: _seciliSayfa == 1,
                    selectedTileColor: Colors.blue.withOpacity(0.3),
                    onTap: () => setState(() => _seciliSayfa = 1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.white),
                    title: const Text(
                      'Tüm Müşteri Siparişleri',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    selected: _seciliSayfa == 2,
                    selectedTileColor: Colors.blue.withOpacity(0.3),
                    onTap: () => setState(() => _seciliSayfa = 2),
                  ),
                ],

                if (!isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                    title: const Text(
                      'Ürün Talebi & Teklif Al',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    selected: _seciliSayfa == 0,
                    selectedTileColor: Colors.blue.withOpacity(0.3),
                    onTap: () => setState(() => _seciliSayfa = 0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.white),
                    title: const Text(
                      'Sipariş Geçmişim',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    selected: _seciliSayfa == 1,
                    selectedTileColor: Colors.blue.withOpacity(0.3),
                    onTap: () => setState(() => _seciliSayfa = 1),
                  ),
                ],

                const Spacer(),
                const Divider(color: Colors.white24, height: 20),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Oturumu Kapat',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  onTap: _cikisYap,
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'v6.2.0 - Arşiv PDF Destekli',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: isAdmin
                ? (_seciliSayfa == 0
                    ? const DashboardEkrani()
                    : _seciliSayfa == 1
                        ? const StokEkrani()
                        : const ArsivEkrani(filtreliMusteri: null))
                : (_seciliSayfa == 0
                    ? TeklifEkrani(aktifMusteriAdi: _aktifMusteriAdi)
                    : ArsivEkrani(filtreliMusteri: _aktifMusteriAdi)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 1. ÇİFT GİRİŞLİ KARŞILAMA PORTALI (MÜŞTERİ VEYA ADMİN)
// ---------------------------------------------------------
class GirisPortalEkrani extends StatefulWidget {
  final VoidCallback onAdminGiris;
  final Function(String) onMusteriGiris;

  const GirisPortalEkrani({
    super.key,
    required this.onAdminGiris,
    required this.onMusteriGiris,
  });

  @override
  State<GirisPortalEkrani> createState() => _GirisPortalEkraniState();
}

class _GirisPortalEkraniState extends State<GirisPortalEkrani> {
  final TextEditingController _firmaAdiController = TextEditingController();
  final TextEditingController _adminKullaniciController = TextEditingController();
  final TextEditingController _adminSifreController = TextEditingController();

  String _musteriHata = '';
  String _adminHata = '';

  void _musteriGirisKontrol() {
    if (_firmaAdiController.text.trim().isEmpty) {
      setState(() {
        _musteriHata = 'Lütfen firma veya ad-soyad bilginizi girin!';
      });
      return;
    }
    widget.onMusteriGiris(_firmaAdiController.text.trim());
  }

  void _adminGirisKontrol() {
    if (_adminKullaniciController.text == 'admin' &&
        _adminSifreController.text == 'syntax2026') {
      widget.onAdminGiris();
    } else {
      setState(() {
        _adminHata = 'Yönetici kullanıcı adı veya şifre hatalı!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hub, size: 64, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'SYNTAX KURUMSAL ERP PORTALI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lütfen devam etmek istediğiniz giriş türünü seçin',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const SizedBox(height: 48),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(36.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.storefront,
                                  size: 48,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Müşteri & Bayi Girişi',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2027),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Yapay zeka destekli anlık fiyat teklifi almak ve sipariş vermek için giriş yapın.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 32),
                              TextField(
                                controller: _firmaAdiController,
                                decoration: const InputDecoration(
                                  labelText: 'Firma / Müşteri Adınız',
                                  hintText: 'Örn: Syntax İnşaat',
                                  prefixIcon: Icon(Icons.business),
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) => _musteriGirisKontrol(),
                              ),
                              const SizedBox(height: 24),
                              if (_musteriHata.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    _musteriHata,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _musteriGirisKontrol,
                                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                  label: const Text(
                                    'Müşteri Paneline Gir',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),

                    Expanded(
                      child: Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(36.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F2027).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  size: 48,
                                  color: Color(0xFF0F2027),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Yönetici (Admin) Girişi',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2027),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Depo stoklarını yönetmek, kritik uyarıları ve ciro analizlerini görmek için giriş yapın.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _adminKullaniciController,
                                decoration: const InputDecoration(
                                  labelText: 'Yönetici Kullanıcı Adı',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _adminSifreController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Yönetici Şifresi',
                                  prefixIcon: Icon(Icons.lock),
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) => _adminGirisKontrol(),
                              ),
                              const SizedBox(height: 24),
                              if (_adminHata.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    _adminHata,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _adminGirisKontrol,
                                  icon: const Icon(Icons.security, color: Colors.white),
                                  label: const Text(
                                    'Yönetim Paneline Gir',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F2027),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. MÜŞTERİ TEKLİF & SİPARİŞ ONAY EKRANI
// ---------------------------------------------------------
class TeklifEkrani extends StatefulWidget {
  final String aktifMusteriAdi;

  const TeklifEkrani({super.key, required this.aktifMusteriAdi});

  @override
  State<TeklifEkrani> createState() => _TeklifEkraniState();
}

class _TeklifEkraniState extends State<TeklifEkrani> {
  late TextEditingController _musteriController;
  final TextEditingController _metinController = TextEditingController();
  bool _yukleniyor = false;
  bool _onayYukleniyor = false;
  bool _pdfYukleniyor = false;
  bool _siparisOnaylandi = false;
  Map<String, dynamic>? _teklifSonucu;
  String _hataMesaji = '';

  final String apiUrl = 'http://127.0.0.1:8000/teklif-hazirla/';
  final String onayUrl = 'http://127.0.0.1:8000/siparis-onayla/';
  final String pdfUrl = 'http://127.0.0.1:8000/pdf-indir/';

  @override
  void initState() {
    super.initState();
    _musteriController = TextEditingController(text: widget.aktifMusteriAdi);
  }

  Future<void> _teklifAl() async {
    if (_metinController.text.isEmpty || _musteriController.text.isEmpty) {
      setState(() {
        _hataMesaji = 'Lütfen talep ettiğiniz ürünleri ve miktarları yazın.';
      });
      return;
    }

    setState(() {
      _yukleniyor = true;
      _hataMesaji = '';
      _teklifSonucu = null;
      _siparisOnaylandi = false;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'musteri_adi': _musteriController.text,
          'metin': _metinController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['hata'] != null) {
          setState(() => _hataMesaji = data['hata']);
        } else {
          setState(() => _teklifSonucu = data);
        }
      } else {
        setState(() => _hataMesaji = 'Sunucu Hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _hataMesaji = 'Sunucuya bağlanılamadı.');
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _siparisiOnayla() async {
    if (_teklifSonucu == null || _siparisOnaylandi) return;

    setState(() {
      _onayYukleniyor = true;
      _hataMesaji = '';
    });

    try {
      final response = await http.post(
        Uri.parse(onayUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(_teklifSonucu),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['hata'] != null) {
          setState(() => _hataMesaji = data['hata']);
        } else {
          setState(() {
            _siparisOnaylandi = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  '✅ Siparişiniz onaylandı! Sipariş Geçmişinize ve Yönetim Paneline eklendi.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        }
      } else {
        setState(() => _hataMesaji = 'Onaylama Hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _hataMesaji = 'Onay sırasında sunucu bağlantı hatası oluştu.');
    } finally {
      setState(() => _onayYukleniyor = false);
    }
  }

  Future<void> _pdfIndir() async {
    if (_teklifSonucu == null) return;
    setState(() => _pdfYukleniyor = true);

    try {
      final response = await http.post(
        Uri.parse(pdfUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(_teklifSonucu),
      );

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "Syntax_${_musteriController.text}_Teklif.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      setState(() => _hataMesaji = 'PDF İndirme Hatası');
    } finally {
      setState(() => _pdfYukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: Card(
          elevation: 12,
          margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Müşteri Ürün Talebi & Otomatik Teklif Modülü',
                        style: TextStyle(
                          color: Color(0xFF0F2027),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hoş geldiniz, ${widget.aktifMusteriAdi}. İhtiyacınız olan malzemeleri doğal dille yazabilirsiniz.',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _musteriController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Kayıtlı Firma / Müşteri Adı',
                            prefixIcon: const Icon(Icons.verified_user, color: Colors.blue),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _metinController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Sipariş Talebiniz (Örn: 2 adet aa ve 3 adet bbb)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF0F2027), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _yukleniyor ? null : _teklifAl,
                          icon: _yukleniyor
                              ? const SizedBox()
                              : const Icon(Icons.auto_awesome, color: Colors.white),
                          label: _yukleniyor
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  'Yapay Zeka İle Fiyat Hesapla (Ön İzleme)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2027),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_hataMesaji.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _hataMesaji,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (_teklifSonucu != null) ...[
                          const SizedBox(height: 40),
                          const Divider(thickness: 2),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: (_teklifSonucu!['hesaplanan_detaylar'] as List).length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    var kalem = _teklifSonucu!['hesaplanan_detaylar'][index];
                                    if (kalem['uyari'] != null) {
                                      return ListTile(
                                        title: Text(
                                          kalem['malzeme'],
                                          style: const TextStyle(decoration: TextDecoration.lineThrough),
                                        ),
                                        subtitle: Text(
                                          kalem['uyari'],
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF0F2027).withOpacity(0.1),
                                        child: Text(
                                          kalem['adet'].toString(),
                                          style: const TextStyle(
                                            color: Color(0xFF0F2027),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        kalem['malzeme'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text('Birim Fiyat: ${kalem['birim_fiyat']} ₺'),
                                      trailing: Text(
                                        '${kalem['toplam_tutar']} ₺',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F2027),
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'GENEL TOPLAM (KDV Hariç)',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${_teklifSonucu!['genel_toplam']} ₺',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.greenAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (_siparisOnaylandi || _onayYukleniyor)
                                      ? null
                                      : _siparisiOnayla,
                                  icon: _onayYukleniyor
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Icon(
                                          _siparisOnaylandi ? Icons.check_circle : Icons.shopping_bag,
                                          color: Colors.white,
                                        ),
                                  label: Text(
                                    _siparisOnaylandi
                                        ? 'Sipariş Onaylandı (Kaydedildi)'
                                        : 'Teklifi Onayla & Sipariş Ver',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    disabledBackgroundColor: Colors.green.shade400,
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pdfYukleniyor ? null : _pdfIndir,
                                  icon: _pdfYukleniyor
                                      ? const SizedBox()
                                      : const Icon(Icons.picture_as_pdf, color: Colors.white),
                                  label: _pdfYukleniyor
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                        )
                                      : const Text(
                                          'Resmi Teklifi (PDF) İndir',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. YÖNETİCİ DASHBOARD (ANALİZ) EKRANI
// ---------------------------------------------------------
class DashboardEkrani extends StatefulWidget {
  const DashboardEkrani({super.key});

  @override
  State<DashboardEkrani> createState() => _DashboardEkraniState();
}

class _DashboardEkraniState extends State<DashboardEkrani> {
  Map<String, dynamic>? _analizVerisi;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _analizGetir();
  }

  Future<void> _analizGetir() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/analiz/'));
      if (response.statusCode == 200) {
        setState(() {
          _analizVerisi = jsonDecode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (e) {
      // Hata
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator());
    if (_analizVerisi == null) return const Center(child: Text("Veri alınamadı."));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Yönetici Özeti & Finansal Metrikler',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2027),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Müşteri portalından onaylanan siparişlerin ciro ve stok yansımaları.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _OzetKarti(
                      baslik: 'Onaylı Ciro Hacmi',
                      deger: '${_analizVerisi!['toplam_ciro']} ₺',
                      icon: Icons.account_balance_wallet,
                      renk: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OzetKarti(
                      baslik: 'Onaylanan Sipariş Sayısı',
                      deger: '${_analizVerisi!['teklif_sayisi']}',
                      icon: Icons.receipt_long,
                      renk: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OzetKarti(
                      baslik: 'Kayıtlı Hammadde Çeşidi',
                      deger: '${_analizVerisi!['hammadde_sayisi']}',
                      icon: Icons.category,
                      renk: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'B2B Portal & Yapay Zeka Motoru Durumu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2027),
                        ),
                      ),
                      const Divider(height: 32),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_graph, size: 80, color: Colors.blue.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              const Text(
                                '2 Aşamalı Sipariş Onay & Dinamik PDF Arşiv Motoru aktif çalışıyor.',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Şu ana kadar müşteriler tarafından ${_analizVerisi!['teklif_sayisi']} adet sipariş resmen onaylandı ve stoktan düşüldü.',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. ARŞİV VE SİPARİŞ GEÇMİŞİ EKRANI (PDF YENİDEN OLUŞTURMA BUTONLU)
// ---------------------------------------------------------
class ArsivEkrani extends StatefulWidget {
  final String? filtreliMusteri;

  const ArsivEkrani({super.key, this.filtreliMusteri});

  @override
  State<ArsivEkrani> createState() => _ArsivEkraniState();
}

class _ArsivEkraniState extends State<ArsivEkrani> {
  List<dynamic> _arsivKayitlari = [];
  bool _yukleniyor = true;
  int? _indirilenKayitId; // Hangi siparişin PDF'i indiriliyorsa onun ID'sini tutar

  @override
  void initState() {
    super.initState();
    _arsivleriGetir();
  }

  Future<void> _arsivleriGetir() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/teklif-arsivi/'));
      if (response.statusCode == 200) {
        List<dynamic> tumKayitlar = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          if (widget.filtreliMusteri != null) {
            _arsivKayitlari = tumKayitlar
                .where((k) =>
                    (k['musteri_adi'] ?? '').toString().toLowerCase() ==
                    widget.filtreliMusteri!.toLowerCase())
                .toList();
          } else {
            _arsivKayitlari = tumKayitlar;
          }
        });
      }
    } catch (e) {
      // Hata
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  // GEÇMİŞ SİPARİŞİN PDF'İNİ YENİDEN OLUŞTURUP İNDİREN FONKSİYON
  Future<void> _gecmisPdfIndir(int kayitId, String musteriAdi) async {
    setState(() {
      _indirilenKayitId = kayitId;
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/arsiv-pdf-indir/$kayitId'),
      );

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "Syntax_${musteriAdi}_Siparis_$kayitId.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('PDF oluşturulurken sunucu hatası meydana geldi.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Sunucuya bağlanılamadı.'),
          ),
        );
      }
    } finally {
      setState(() {
        _indirilenKayitId = null;
      });
    }
  }

  String _tarihFormatla(String tarihIso) {
    if (tarihIso.isEmpty) return "";
    DateTime dt = DateTime.parse(tarihIso);
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    bool isMusteri = widget.filtreliMusteri != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isMusteri ? 'Onaylanan Sipariş Geçmişim' : 'Tüm Müşteri Siparişleri Arşivi',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2027),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isMusteri
                    ? '${widget.filtreliMusteri} firması tarafından onaylanarak işleme alınan siparişler ve resmi PDF belgeleri.'
                    : 'Sistem üzerinden müşterilerin onayladığı resmi sipariş kayıtları ve PDF faturaları.',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _yukleniyor
                    ? const Center(child: CircularProgressIndicator())
                    : _arsivKayitlari.isEmpty
                        ? const Center(
                            child: Text(
                              "Henüz onaylanmış bir sipariş bulunmuyor.",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                              ],
                            ),
                            child: ListView.separated(
                              itemCount: _arsivKayitlari.length,
                              separatorBuilder: (context, index) =>
                                  Divider(color: Colors.grey.shade200, height: 1),
                              itemBuilder: (context, index) {
                                var kayit = _arsivKayitlari[index];
                                int kayitId = kayit['id'];
                                String musteriAdi = kayit['musteri_adi'] ?? 'Bilinmeyen Müşteri';
                                bool buKayitIndiriliyor = _indirilenKayitId == kayitId;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFF0F2027).withOpacity(0.1),
                                        radius: 25,
                                        child: const Icon(Icons.business, color: Color(0xFF0F2027)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              musteriAdi,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Color(0xFF0F2027),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Talep: ${kayit['talep'] ?? ''}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Onay Tarihi: ${_tarihFormatla(kayit['tarih'])}  •  Sipariş No: SYN-2026-${kayitId.toString().padLeft(4, '0')}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Onaylı Tutar',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          Text(
                                            '${kayit['toplam_tutar']} ₺',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 24),
                                      // YENİ: GEÇMİŞ SİPARİŞ PDF İNDİRME BUTONU
                                      ElevatedButton.icon(
                                        onPressed: buKayitIndiriliyor
                                            ? null
                                            : () => _gecmisPdfIndir(kayitId, musteriAdi),
                                        icon: buKayitIndiriliyor
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.picture_as_pdf,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                        label: Text(
                                          buKayitIndiriliyor ? 'Hazırlanıyor...' : 'PDF İndir',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade700,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 5. YÖNETİCİ STOK KONTROL EKRANI
// ---------------------------------------------------------
class StokEkrani extends StatefulWidget {
  const StokEkrani({super.key});

  @override
  State<StokEkrani> createState() => _StokEkraniState();
}

class _StokEkraniState extends State<StokEkrani> {
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  List<dynamic> _hammadeler = [];
  bool _yukleniyor = true;
  String _mesaj = '';

  final String apiUrl = 'http://127.0.0.1:8000/hammadde/';

  @override
  void initState() {
    super.initState();
    _stoklariGetir();
  }

  Future<void> _stoklariGetir() async {
    setState(() => _yukleniyor = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _hammadeler = jsonDecode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (e) {
      setState(() => _mesaj = "Bağlantı Hatası!");
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _hammaddeEkle() async {
    if (_isimController.text.isEmpty || _fiyatController.text.isEmpty) return;
    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'isim': _isimController.text,
          'birim_fiyati': double.parse(_fiyatController.text),
          'stok_adedi': _stokController.text.isEmpty ? 50 : int.parse(_stokController.text),
        }),
      );
      _isimController.clear();
      _fiyatController.clear();
      _stokController.clear();
      _mesaj = "";
      _stoklariGetir();
    } catch (e) {
      setState(() => _mesaj = "Ekleme başarısız!");
    }
  }

  Future<void> _hammaddeSil(int id) async {
    await http.delete(Uri.parse('$apiUrl$id'));
    _stoklariGetir();
  }

  Future<void> _stokGuncelle(int id, String islem, int miktar) async {
    await http.put(Uri.parse('${apiUrl}stok/$id?islem=$islem&miktar=$miktar'));
    _stoklariGetir();
  }

  Future<void> _stokMiktariSor(int id, String islem, String malzemeAdi) async {
    TextEditingController miktarController = TextEditingController(text: "10");
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            islem == 'arttir' ? 'Stok Girişi' : 'Stok Çıkışı',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Malzeme: $malzemeAdi',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: miktarController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: islem == 'arttir' ? 'Eklenecek Miktar' : 'Çıkarılacak Miktar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixText: 'Adet',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: islem == 'arttir' ? Colors.blue : Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                int miktar = int.tryParse(miktarController.text) ?? 1;
                Navigator.pop(context);
                _stokGuncelle(id, islem, miktar);
              },
              child: const Text(
                'Onayla',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int toplamUrun = _hammadeler.length;
    int kritikStok = _hammadeler.where((item) => (item['stok_adedi'] ?? 0) < 20).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Depo & Stok Kontrol Merkezi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2027),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _OzetKarti(
                      baslik: 'Toplam Ürün Çeşidi',
                      deger: '$toplamUrun',
                      icon: Icons.category,
                      renk: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OzetKarti(
                      baslik: 'Kritik Stok Uyarısı',
                      deger: '$kritikStok',
                      icon: Icons.warning_amber_rounded,
                      renk: kritikStok > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _isimController,
                            decoration: InputDecoration(
                              labelText: 'Yeni Malzeme Adı',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.add_box),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _fiyatController,
                            decoration: InputDecoration(
                              labelText: 'Birim Fiyatı (₺)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _stokController,
                            decoration: InputDecoration(
                              labelText: 'İlk Stok',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _hammaddeEkle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2027),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Stoka Ekle',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_mesaj.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_mesaj, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _yukleniyor
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                          ],
                        ),
                        child: ListView.separated(
                          itemCount: _hammadeler.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey.shade200, height: 1),
                          itemBuilder: (context, index) {
                            var item = _hammadeler[index];
                            int stok = item['stok_adedi'] ?? 0;
                            double stokYuzdesi = (stok / 200).clamp(0.0, 1.0);
                            Color barRengi = stok < 20
                                ? Colors.red
                                : (stok < 50 ? Colors.orange : Colors.green);

                            return Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['isim'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                            color: Color(0xFF0F2027),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item['birim_fiyati']} ₺ / Birim',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Mevcut Stok: $stok Adet',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            if (stok < 20)
                                              const Text(
                                                'Kritik!',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: stokYuzdesi,
                                            backgroundColor: Colors.grey.shade200,
                                            color: barRengi,
                                            minHeight: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.orange, size: 32),
                                          onPressed: stok > 0
                                              ? () => _stokMiktariSor(item['id'], 'azalt', item['isim'])
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32),
                                          onPressed: () => _stokMiktariSor(item['id'], 'arttir', item['isim']),
                                        ),
                                        const SizedBox(width: 24),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _hammaddeSil(item['id']),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ---------------------------------------------------------
// 6. YARDIMCI BİLEŞEN: ÖZET KARTI (TAŞMA HATASI DÜZELTİLDİ)
// ---------------------------------------------------------
class _OzetKarti extends StatelessWidget {
  final String baslik;
  final String deger;
  final IconData icon;
  final Color renk;

  const _OzetKarti({
    required this.baslik,
    required this.deger,
    required this.icon,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20), // İç boşluğu biraz daha dengeli yaptık
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
        border: Border(left: BorderSide(color: renk, width: 6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: renk.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: renk, size: 30),
          ),
          const SizedBox(width: 16),
          // İŞTE ÇÖZÜM BURADA: Expanded ekleyerek metnin karttan dışarı taşmasını engelledik!
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Çok uzunsa sonuna ... koyar, asla taşmaz
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown, // Ciro rakamı milyonlara çıkarsa bile otomatik küçülüp sığar
                  alignment: Alignment.centerLeft,
                  child: Text(
                    deger,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2027),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}