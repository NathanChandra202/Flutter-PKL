import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> _units = [
    {
      'title': 'Tipe Standard',
      'price': 'Rp 800.000',
      'image': 'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png',
      'features': ['1 Kamar Tidur', '1 Kamar Mandi', 'WiFi', 'AC'],
      'location': 'Pasar Rebo, Jakarta Timur',
    },
    {
      'title': 'Tipe Deluxe',
      'price': 'Rp 1.200.000',
      'image': 'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png',
      'features': ['2 Kamar Tidur', '1 Kamar Mandi', 'WiFi', 'AC'],
      'location': 'Pasar Rebo, Jakarta Timur',
    },
    {
      'title': 'Tipe Premium',
      'price': 'Rp 1.800.000',
      'image': 'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png',
      'features': ['3 Kamar Tidur', '2 Kamar Mandi', 'WiFi', 'AC'],
      'location': 'Pasar Rebo, Jakarta Timur',
    },
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── App Bar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/logo/kostraktor.jpeg',
                        height: 24,
                        errorBuilder: (_, __, ___) => const Text(
                          'Kostraktor',
                          style: TextStyle(
                            color: AppTheme.primaryBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const Text(
                        'Jakarta Timur',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlack,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

            // ─── Search bar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 16),
                    Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                    SizedBox(width: 10),
                    Text('Cari kamar, tipe, lokasi...', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  ],
                ),
              ),
            ),

            // ─── Filter chips ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 0, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'Semua', active: true),
                    _FilterChip(label: 'Standard'),
                    _FilterChip(label: 'Deluxe'),
                    _FilterChip(label: 'Premium'),
                  ],
                ),
              ),
            ),

            // ─── Section Header ───
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text('Unit Tersedia', style: TextStyle(color: AppTheme.primaryBlack, fontSize: 17, fontWeight: FontWeight.bold))),
                  Text('100+ kamar', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),

            // ─── Grid ───
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: _units.length,
                itemBuilder: (context, i) => _UnitCard(unit: _units[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  const _FilterChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryBlack : Colors.white,
          border: Border.all(color: active ? AppTheme.primaryBlack : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textMuted,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final Map<String, dynamic> unit;
  const _UnitCard({required this.unit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(unitData: unit)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      unit['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.apartment, size: 48, color: Colors.grey),
                      ),
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit['title'],
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.accentGold, size: 11),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          'Jakarta Timur',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${unit['price']} / bln',
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
