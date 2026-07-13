import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
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
                          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
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
                          color: AppTheme.accentGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accentGold.withOpacity(0.4)),
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
