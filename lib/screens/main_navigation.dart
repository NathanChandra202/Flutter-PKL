import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

import 'home_screen.dart';
import 'jastip_screen.dart';
import 'passport_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'admin_panel_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _allScreens = [
    const HomeScreen(),
    const JastipScreen(),
    const PassportScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isResident = auth.isResident;

    // If somehow an admin lands here, redirect to admin panel
    if (auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
          (route) => false,
        );
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          _allScreens[_currentIndex],
          // Pending resident floating banner
          if (auth.isPendingResident)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildPendingBanner(context, auth),
            ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.home_outlined, 'Home', 0),
              _navItem(
                Icons.groups_outlined,
                'Komunitas',
                1,
                locked: !isResident,
                lockMessage: 'Fitur ini hanya untuk Penghuni Aktif',
              ),
              _navItem(
                Icons.assignment_outlined,
                'Lapor',
                2,
                locked: !isResident,
                lockMessage: 'Fitur ini hanya untuk Penghuni Aktif',
              ),
              _navItem(Icons.person_outline, 'Profil', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingBanner(BuildContext context, AuthProvider auth) {
    return SafeArea(
      child: GestureDetector(
        onTap: () {
          // Tap banner → go to profile to see status & WA button
          setState(() => _currentIndex = 3);
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Menunggu konfirmasi admin - Ketuk untuk lihat status',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index,
      {bool locked = false, String? lockMessage}) {
    final isActive = _currentIndex == index;
    final iconColor = locked
        ? Colors.grey.shade400
        : (isActive ? AppTheme.primaryBlack : AppTheme.textMuted);

    return GestureDetector(
      onTap: () {
        if (locked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lockMessage ?? 'Fitur terkunci'),
              action: SnackBarAction(
                label: 'Sewa Dulu',
                onPressed: () {},
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor, size: 24),
                if (locked)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.lock, color: Colors.white, size: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
