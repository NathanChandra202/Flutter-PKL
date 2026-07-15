import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background image
          Positioned.fill(
            child: Image.network(
              'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/galeri1.png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, _, __) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
                  ),
                ),
              ),
            ),
          ),

          // Gradient overlay — dark on bottom for text legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.black.withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final hPad = constraints.maxWidth < 360 ? 20.0 : 28.0;
                final titleSize = constraints.maxWidth < 360 ? 28.0 : 36.0;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ─── Logo / Brand ───
                          Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
                            child: Row(
                              children: [
                                _KostraktorLogo(size: 36),
                              ],
                            ),
                          ),

                          // Push content to bottom
                          const Spacer(),

                          // ─── Bottom content ───
                          Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tagline
                                Text(
                                  'Ng\'Kost\nNyaman,\nHarga Aman.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Hunian premium berkualitas konstruktor\ndi kawasan strategis Jakarta Timur.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Starting price badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGold,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Text(
                                    'Mulai dari Rp 800.000 / bulan',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Facilities row
                                _FacilityRow(),
                                const SizedBox(height: 20),

                                // CTA Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const HomeScreen()),
                                      );
                                    },
                                    child: const Text(
                                      'Jelajahi Kamar Kos',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Secondary CTA — Masuk Akun
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white54, width: 1.5),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const LoginScreen()),
                                      );
                                    },
                                    child: const Text(
                                      'Masuk Akun',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        letterSpacing: 0.3,
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KostraktorLogo extends StatelessWidget {
  final double size;
  const _KostraktorLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/logo/kostraktor.jpeg',
      height: size,
      errorBuilder: (ctx, _, __) => Text(
        'Kostraktor',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.7,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _FacilityRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.ac_unit_outlined, 'AC'),
      (Icons.wifi_outlined, 'WiFi'),
      (Icons.bed_outlined, 'Kamar Mandi'),
      (Icons.security_outlined, 'Keamanan'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.$1, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(
                item.$2,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
