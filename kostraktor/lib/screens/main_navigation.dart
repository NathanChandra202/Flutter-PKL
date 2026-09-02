import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'jastip_screen.dart';
import 'lapor_screen.dart';
import 'profile_screen.dart';
import 'admin_panel_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _pollTimer;
  UserRole? _lastKnownRole; // track role changes to show notification

  final List<Widget> _allScreens = [
    const HomeScreen(),
    const JastipScreen(),
    const LaporScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStatus();
      _startPollingIfPending();
      _listenForApproval();
      _maybeShowWaChannelPopup();
    });
  }

  /// Tampilkan pop-up join Grup WA hanya sekali saat user baru jadi resident.
  Future<void> _maybeShowWaChannelPopup() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isResident) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'wa_group_popup_shown_${auth.userEmail}';
    final alreadyShown = prefs.getBool(key) ?? false;
    if (alreadyShown) return;

    // Tandai sudah pernah ditampilkan sebelum show dialog
    await prefs.setBool(key, true);

    if (!mounted) return;
    _showWaChannelPopup();
  }

  void _showWaChannelPopup() {
    const waChannelUrl = 'https://whatsapp.com/channel/0029Vb8zTM46RGJP43usFe1L';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Selamat Datang, Penghuni! 🎉',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Body
              const Text(
                'Kamu sudah resmi jadi penghuni kost kami!\n\n'
                'Gabung ke Grup WhatsApp kost untuk dapat update fasilitas, pengumuman, dan laporan kerusakan secara transparan.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Tombol Gabung
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Gabung Grup WA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final url = Uri.parse(waChannelUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Nanti
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Nanti Aja',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
      _startPollingIfPending();
    } else if (state == AppLifecycleState.paused) {
      // Stop polling when app goes to background to save battery
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Start a 30-second polling loop only when user is pendingResident.
  /// Stops automatically once they become a resident.
  void _startPollingIfPending() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isPendingResident) return;

    // Avoid double timers
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      final a = Provider.of<AuthProvider>(context, listen: false);
      if (!a.isPendingResident) {
        // Approved! Stop polling
        _pollTimer?.cancel();
        _pollTimer = null;
        return;
      }
      await a.refreshUserStatus();
      // Re-check after refresh
      if (!a.isPendingResident) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    });
  }

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn) {
      await auth.refreshUserStatus();
      // If still pending after refresh, ensure polling is running
      if (auth.isPendingResident) {
        _startPollingIfPending();
      }
    }
  }

  /// Listen to AuthProvider changes:
  /// 1. calon → pendingResident: booking baru dibuat, mulai polling segera
  /// 2. pendingResident → resident: booking diapprove, tampilkan notifikasi
  void _listenForApproval() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _lastKnownRole = auth.currentRole;

    auth.addListener(() {
      if (!mounted) return;
      final newRole = auth.currentRole;

      // ── Booking baru dibuat (calon/guest → pendingResident) ──────────────
      if (_lastKnownRole != UserRole.pendingResident &&
          newRole == UserRole.pendingResident) {
        // Mulai polling segera, tidak perlu tunggu 30 detik pertama
        _pollTimer?.cancel();
        _pollTimer = null;
        _startPollingIfPending();
      }

      // ── Booking diapprove (pendingResident → resident) ───────────────────
      if (_lastKnownRole == UserRole.pendingResident &&
          newRole == UserRole.resident) {
        _pollTimer?.cancel();
        _pollTimer = null;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Text('🎉', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Booking disetujui! Selamat datang sebagai penghuni.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      _lastKnownRole = newRole;
    });
  }

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
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Menunggu konfirmasi admin - Ketuk untuk lihat status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index, {
    bool locked = false,
    String? lockMessage,
  }) {
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
                onPressed: () {
                  setState(() => _currentIndex = 0);
                },
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 8,
                      ),
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
