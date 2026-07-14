import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'booking_form_screen.dart';
import 'login_screen.dart';

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic>? unitData;
  const DetailScreen({super.key, this.unitData});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final title = unitData?['title'] ?? 'Tipe Premium';
    final price = unitData?['price'] ?? 'Rp 1.800.000';
    final imageUrl = unitData?['image'] ??
        'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png';
    final features = (unitData?['features'] as List<dynamic>?) ??
        ['Kamar Tidur', 'Kamar Mandi', 'WiFi', 'AC'];

    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: CustomScrollView(
        slivers: [
          // ─── SliverAppBar (hero image) ───
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryBlack,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: AppTheme.primaryBlack, size: 20),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  tooltip: 'Bagikan',
                  onPressed: () => _showShareSheet(context, title, price),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200),
                  ),
                  // Bottom gradient so title is legible
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Content ───
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title + Price
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppTheme.primaryBlack,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: const [
                                Icon(Icons.location_on, color: AppTheme.accentGold, size: 14),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Pasar Rebo, Jakarta Timur',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          price,
                          style: const TextStyle(
                            color: AppTheme.primaryBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const _Divider(),

                // About Section
                const _SectionTitle('Tentang Hunian'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    'Kostraktor menghadirkan hunian kost premium dengan fasilitas lengkap dan kualitas konstruksi terbaik. Setiap kamar dirancang dengan ventilasi silang alami, kedap suara, dan bebas banjir. Cocok untuk mahasiswa dan pekerja muda Jakarta Timur.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.7),
                  ),
                ),

                const SizedBox(height: 24),
                const _Divider(),

                // Facilities
                const _SectionTitle('Fasilitas'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: features.map<Widget>((f) => _FacilityBadge(label: f.toString())).toList(),
                  ),
                ),

                const SizedBox(height: 24),
                const _Divider(),

                // Pricing breakdown
                const _SectionTitle('Rincian Biaya'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PriceBox(label: 'Sewa / Bulan', value: price),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _PriceBox(label: 'Deposit Awal', value: 'Rp 1.000.000'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const _Divider(),

                // Lokasi & Transportasi
                const _SectionTitle('Lokasi & Transportasi'),
                const _LocationSection(),

                const SizedBox(height: 100), // space for FAB
              ],
            ),
          ),
        ],
      ),

      // ─── Book Now FAB ───
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: Builder(builder: (ctx) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: Colors.black38,
              ),
              onPressed: () {
                final auth = Provider.of<AuthProvider>(ctx, listen: false);
                if (!auth.isLoggedIn) {
                  _showLoginPrompt(ctx);
                } else {
                  Navigator.push(ctx, MaterialPageRoute(
                    builder: (_) => BookingFormScreen(unitData: unitData),
                  ));
                }
              },
              child: const Text(
                'Ajukan Sewa Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: AppTheme.bgWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(
                      color: AppTheme.primaryBlack, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Login Dulu',
                  style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Untuk mengajukan sewa, masuk atau buat akun dulu. Gratis dan cepat!',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()));
                    },
                    child: const Text('Masuk / Daftar Akun',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Lanjut Lihat-lihat Dulu',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showShareSheet(BuildContext context, String title, String price) {
    final shareText =
        'Cek hunian $title di Kostraktor!\n'
        'Lokasi: Pasar Rebo, Jakarta Timur\n'
        'Harga: $price/bulan\n\n'
        'Kostraktor - Hunian Premium Jakarta Timur';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bagikan Hunian',
              style: TextStyle(
                color: AppTheme.primaryBlack,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ── Salin Link ──
            _ShareOption(
              icon: Icons.copy_outlined,
              iconColor: Colors.blueGrey,
              label: 'Salin Link',
              subtitle: 'Salin teks ke clipboard',
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: shareText));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Teks berhasil disalin ke clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // ── WhatsApp ──
            _ShareOption(
              icon: Icons.chat_outlined,
              iconColor: Colors.green,
              label: 'Bagikan via WhatsApp',
              subtitle: 'Buka WhatsApp dengan pesan siap kirim',
              onTap: () async {
                final encoded = Uri.encodeComponent(shareText);
                final uri = Uri.parse('https://wa.me/?text=$encoded');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),

            // ── Aplikasi Lain ──
            _ShareOption(
              icon: Icons.share_outlined,
              iconColor: AppTheme.accentGold,
              label: 'Bagikan ke Aplikasi Lain',
              subtitle: 'Gunakan menu berbagi sistem',
              onTap: () async {
                Navigator.pop(context);
                await Share.share(shareText, subject: 'Hunian $title - Kostraktor');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Share Option Tile ────────────────────────────────────────────────────────

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Divider(color: Colors.grey.shade200, thickness: 1, indent: 24, endIndent: 24);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Text(
          text,
          style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 17, fontWeight: FontWeight.bold),
        ),
      );
}

class _FacilityBadge extends StatelessWidget {
  final String label;
  const _FacilityBadge({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label, style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 13)),
      );
}

class _PriceBox extends StatelessWidget {
  final String label, value;
  const _PriceBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      );
}

// ─── Lokasi & Transportasi ────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  const _LocationSection();

  static const _address = 'Jl. H. Hasan No.36, RT.2/RW.9, Pasar Rebo, Jakarta Timur 13780';
  static const _lat = -6.3141;
  static const _lng = 106.8710;

  // Pilihan transportasi ke lokasi kos
  static const _transports = [
    _TransportData(
      icon: Icons.directions_walk,
      color: Colors.teal,
      mode: 'Jalan Kaki',
      distance: '± 0.5 km dari halte terdekat',
      duration: '~7 menit',
      note: 'Dari Halte Pasar Rebo (TransJakarta)',
      mapsMode: 'walking',
    ),
    _TransportData(
      icon: Icons.directions_bike,
      color: Colors.green,
      mode: 'Motor / Ojol',
      distance: '± 8 km dari Pusat Jakarta',
      duration: '~20–35 menit',
      note: 'Gojek / Grab tersedia di area ini',
      mapsMode: 'driving',
    ),
    _TransportData(
      icon: Icons.directions_car,
      color: Colors.blue,
      mode: 'Mobil',
      distance: '± 8 km dari Pusat Jakarta',
      duration: '~25–45 menit',
      note: 'Akses lewat Jl. Raya Bogor & TB Simatupang',
      mapsMode: 'driving',
    ),
    _TransportData(
      icon: Icons.directions_bus,
      color: Colors.orange,
      mode: 'TransJakarta',
      distance: 'Koridor 7 / 7C',
      duration: '~30–50 menit dari Harmoni',
      note: 'Turun di Halte Pasar Rebo, lanjut jalan ± 500m',
      mapsMode: 'transit',
    ),
    _TransportData(
      icon: Icons.train,
      color: Colors.purple,
      mode: 'KRL Commuter Line',
      distance: '± 4 km dari Stasiun Pasar Minggu',
      duration: '~10 menit naik ojol dari stasiun',
      note: 'Stasiun Pasar Minggu → ojol ke lokasi',
      mapsMode: 'transit',
    ),
  ];

  Future<void> _openMaps(BuildContext context, String mapsMode) async {
    // Buka Google Maps navigasi ke koordinat lokasi kos
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$_lat,$_lng'
      '&travelmode=$mapsMode',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
        );
      }
    }
  }

  Future<void> _openPinpoint(BuildContext context) async {
    // Buka pinpoint langsung ke lokasi kos
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_lat,$_lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Alamat + tombol buka maps ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Icon(Icons.location_on, color: Colors.red.shade600, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alamat Lengkap',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            _address,
                            style: TextStyle(
                              color: AppTheme.primaryBlack,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Koordinat badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location, size: 12, color: Colors.blue.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Tombol buka di Google Maps
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text(
                      'Lihat di Google Maps',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _openPinpoint(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Label pilihan transportasi ──
          const Text(
            'Pilihan Transportasi',
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ketuk untuk buka navigasi di Google Maps',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // ── List transportasi ──
          ...(_transports.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => _openMaps(context, t.mapsMode),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon mode
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: t.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: t.color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(t.icon, color: t.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.mode,
                                style: const TextStyle(
                                  color: AppTheme.primaryBlack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.distance,
                                style: TextStyle(
                                  color: t.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t.note,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Durasi + arrow
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: t.color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t.duration,
                                style: TextStyle(
                                  color: t.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ))),
        ],
      ),
    );
  }
}

class _TransportData {
  final IconData icon;
  final Color color;
  final String mode;
  final String distance;
  final String duration;
  final String note;
  final String mapsMode; // walking | driving | transit | bicycling

  const _TransportData({
    required this.icon,
    required this.color,
    required this.mode,
    required this.distance,
    required this.duration,
    required this.note,
    required this.mapsMode,
  });
}
