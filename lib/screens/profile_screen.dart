import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isLoggedIn) {
      return _buildGuestView(context);
    }

    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil', style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            _buildStatusBanner(auth),
            const SizedBox(height: 24),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBlack,
                    ),
                    child: Center(
                      child: Text(
                        (auth.userName?.isNotEmpty == true ? auth.userName![0] : auth.userEmail![0]).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.userName ?? 'Pengguna',
                          style: const TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(auth.userEmail ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        if (auth.userPhone != null) ...[
                          const SizedBox(height: 2),
                          Text(auth.userPhone!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                        const SizedBox(height: 8),
                        _buildRoleBadge(auth.currentRole),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Booking Info for pending/resident
            if (auth.bookingData != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Info Booking', style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    _infoRow(Icons.apartment_outlined, 'Unit', auth.bookingData!.roomType),
                    const SizedBox(height: 10),
                    _infoRow(Icons.location_on_outlined, 'Lokasi', 'Pasar Rebo, Jakarta Timur'),
                    if (auth.assignedRoom != null) ...[
                      const SizedBox(height: 10),
                      _infoRow(Icons.meeting_room_outlined, 'Kamar', auth.assignedRoom!),
                    ],
                    const SizedBox(height: 10),
                    _infoRow(Icons.calendar_today_outlined, 'Tanggal Booking',
                        '${auth.bookingData!.bookingTime.day}/${auth.bookingData!.bookingTime.month}/${auth.bookingData!.bookingTime.year}'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Menu Items (only show relevant ones)
            if (auth.isResident) ...[
              _menuTile(Icons.receipt_long, 'Riwayat Pembayaran', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Fitur riwayat pembayaran akan segera hadir.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }),
              const SizedBox(height: 12),
              _menuTile(Icons.build_circle_outlined, 'Status Pengaduan', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Lihat status pengaduan di tab Lapor.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
                  trailing: _statusBadge('Processing', Colors.amber)),
              const SizedBox(height: 12),
              _menuTile(Icons.support_agent, 'Hubungi Manajemen', () async {
                final name = auth.userName ?? 'Penghuni';
                final room = auth.assignedRoom ?? 'kamar saya';
                final message = Uri.encodeComponent(
                  'Halo Admin Kostraktor, saya $name ($room) ingin menghubungi manajemen.',
                );
                final url = Uri.parse('https://wa.me/6281234567890?text=$message');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak dapat membuka WhatsApp. Hubungi 081234567890')),
                    );
                  }
                }
              }),
              const SizedBox(height: 12),
            ] else if (auth.isPendingResident) ...[
              _menuTile(Icons.pending_actions, 'Status Pembayaran', () {},
                  trailing: _statusBadge('Menunggu Konfirmasi', Colors.orange)),
              const SizedBox(height: 12),
              _menuTile(Icons.chat, 'Chat Penjaga Kos via WA', () async {
                final booking = auth.bookingData;
                final message = Uri.encodeComponent(
                  'Halo Kak Admin Kostraktor\n\nSaya ${booking?.nama ?? auth.userName ?? 'pengguna'} ingin menanyakan status booking saya (${booking?.roomType ?? 'unit'}).\n\nMohon bantuannya ya, terima kasih',
                );
                final url = Uri.parse('https://wa.me/6281234567890?text=$message');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak dapat membuka WhatsApp. Hubungi 081234567890')),
                    );
                  }
                }
              }),
              const SizedBox(height: 12),
            ] else ...[
              _menuTile(Icons.search, 'Cari Kamar Tersedia', () {
                // Go back to home tab (index 0) via popping to root
                Navigator.of(context).popUntil((route) => route.isFirst);
              }),
              const SizedBox(height: 12),
            ],
            
            _menuTile(Icons.settings_outlined, 'Pengaturan Akun', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Pengaturan akun akan segera hadir.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }),
            const SizedBox(height: 40),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Provider.of<AuthProvider>(context, listen: false).logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Keluar dari Akun', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.red.withOpacity(0.05),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline, size: 40, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              const Text('Belum Masuk', style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 8),
              const Text(
                'Masuk atau daftar akun untuk melihat profil dan riwayat booking Anda.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Masuk / Daftar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(AuthProvider auth) {
    String title, subtitle;
    Color bgColor, borderColor;
    IconData icon;

    switch (auth.currentRole) {
      case UserRole.resident:
        title = 'Penghuni Aktif';
        subtitle = auth.assignedRoom != null ? 'Kamar: ${auth.assignedRoom}' : 'Kamar telah dikonfirmasi';
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        icon = Icons.check_circle;
        break;
      case UserRole.pendingResident:
        title = 'Booking Diterima';
        subtitle = 'Menunggu konfirmasi pembayaran dari admin';
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        icon = Icons.pending_actions;
        break;
      case UserRole.admin:
        title = 'Admin Kostraktor';
        subtitle = 'Akses penuh ke panel admin';
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade200;
        icon = Icons.admin_panel_settings;
        break;
      default:
        title = 'Calon Penghuni';
        subtitle = 'Jelajahi unit dan ajukan sewa untuk jadi penghuni';
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade200;
        icon = Icons.person_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: borderColor, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlack)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    String label;
    Color color;
    switch (role) {
      case UserRole.resident:
        label = 'Penghuni Aktif';
        color = Colors.green;
        break;
      case UserRole.pendingResident:
        label = 'Pending Konfirmasi';
        color = Colors.orange;
        break;
      case UserRole.admin:
        label = 'Admin';
        color = Colors.blue;
        break;
      default:
        label = 'Calon Penghuni';
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: (color as MaterialColor).shade700, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlack, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.w500, fontSize: 14))),
            if (trailing != null) trailing,
            if (trailing == null) const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade300),
      ),
      child: Text(label, style: TextStyle(color: color.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
