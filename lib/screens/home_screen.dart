import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<Map<String, dynamic>> _allUnits = [
    {
      'title': 'Tipe Standard',
      'price': 'Rp 800.000',
      'image':
          'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png',
      'features': ['1 Kamar Tidur', '1 Kamar Mandi', 'WiFi', 'AC'],
      'location': 'Pasar Rebo, Jakarta Timur',
      'type': 'Standard',
    },
    {
      'title': 'Tipe Deluxe',
      'price': 'Rp 1.200.000',
      'image':
          'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png',
      'features': ['2 Kamar Tidur', '1 Kamar Mandi', 'WiFi', 'AC'],
      'location': 'Pasar Rebo, Jakarta Timur',
      'type': 'Deluxe',
    },
    {
      'title': 'Tipe Premium',
      'price': 'Rp 1.800.000',
      'image':
          'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png',
      'features': ['3 Kamar Tidur', '2 Kamar Mandi', 'WiFi', 'AC'],
      'location': 'Pasar Rebo, Jakarta Timur',
      'type': 'Premium',
    },
  ];

  String _activeFilter = 'Semua';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUnits {
    return _allUnits.where((unit) {
      final matchFilter =
          _activeFilter == 'Semua' || unit['type'] == _activeFilter;
      final query = _searchQuery.toLowerCase();
      final matchSearch =
          query.isEmpty ||
          unit['title'].toString().toLowerCase().contains(query) ||
          unit['type'].toString().toLowerCase().contains(query) ||
          unit['location'].toString().toLowerCase().contains(query) ||
          unit['price'].toString().toLowerCase().contains(query);
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final filtered = _filteredUnits;

    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Bar
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Text(
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
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlack,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar — aktif
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(
                  color: AppTheme.primaryBlack,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari kamar, tipe, lokasi...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(
                            Icons.close,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryBlack,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Filter chips — aktif
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 0, 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Semua', 'Standard', 'Deluxe', 'Premium'].map((
                    label,
                  ) {
                    final isActive = _activeFilter == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeFilter = label),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primaryBlack
                                : Colors.white,
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.primaryBlack
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.textMuted,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Hasil pencarian "$_searchQuery"'
                          : _activeFilter == 'Semua'
                          ? 'Unit Tersedia'
                          : 'Tipe $_activeFilter',
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${filtered.length} unit',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _UnitCard(unit: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada unit yang cocok',
              style: TextStyle(
                color: AppTheme.primaryBlack,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain atau reset filter.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryBlack),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _activeFilter = 'Semua';
                });
              },
              child: const Text(
                'Reset Pencarian',
                style: TextStyle(
                  color: AppTheme.primaryBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Get reviews for this specific unit type
        final unitTitle = unit['title'] as String;
        final unitReviews = auth.reviews
            .where((r) => r.roomType == unitTitle)
            .toList();

        final totalReviews = unitReviews.length;
        final avgRating = totalReviews > 0
            ? unitReviews.fold<double>(0, (sum, r) => sum + r.rating) /
                  totalReviews
            : 0.0;

        // Badge logic:
        // "Terbaik" = rating >= 4.5 AND reviews >= 5
        // "Populer" = rating >= 4.0 AND reviews >= 3
        // "Rekomendasi" = rating >= 3.5 AND reviews >= 2
        String? badgeLabel;
        Color? badgeColor;
        IconData? badgeIcon;

        if (avgRating >= 4.5 && totalReviews >= 5) {
          badgeLabel = 'Terbaik';
          badgeColor = Colors.red.shade600;
          badgeIcon = Icons.stars_rounded;
        } else if (avgRating >= 4.0 && totalReviews >= 3) {
          badgeLabel = 'Populer';
          badgeColor = Colors.orange.shade600;
          badgeIcon = Icons.local_fire_department_rounded;
        } else if (avgRating >= 3.5 && totalReviews >= 2) {
          badgeLabel = 'Rekomendasi';
          badgeColor = Colors.blue.shade600;
          badgeIcon = Icons.thumb_up_rounded;
        }

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
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          unit['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.apartment,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                        // Badge di pojok kanan atas
                        if (badgeLabel != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    badgeIcon,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    badgeLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Rating display di pojok kiri bawah (jika ada review)
                        if (totalReviews > 0)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppTheme.accentGold,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '($totalReviews)',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.accentGold,
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              'Jakarta Timur',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${unit['price']} / bln',
                              style: const TextStyle(
                                color: AppTheme.primaryBlack,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (totalReviews > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: AppTheme.accentGold,
                                  size: 11,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
