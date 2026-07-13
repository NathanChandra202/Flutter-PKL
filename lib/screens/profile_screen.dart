import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'admin_panel_screen.dart';

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
                _showRiwayatSheet(context, auth);
              }),
              const SizedBox(height: 12),
              _menuTile(Icons.build_circle_outlined, 'Status Pengaduan', () {
                // Navigasi ke tab Lapor (index 2) di MainNavigation
                Navigator.of(context).popUntil((route) => route.isFirst);
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
              _menuTile(Icons.pending_actions, 'Status Pembayaran', () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Status Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dialogInfoRow('Unit', auth.bookingData?.roomType ?? '-'),
                        const SizedBox(height: 8),
                        _dialogInfoRow('Tanggal Booking', auth.bookingData != null
                            ? '${auth.bookingData!.bookingTime.day}/${auth.bookingData!.bookingTime.month}/${auth.bookingData!.bookingTime.year}'
                            : '-'),
                        const SizedBox(height: 8),
                        _dialogInfoRow('Status', 'Menunggu konfirmasi admin'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            'Admin sedang memverifikasi pembayaran kamu. Proses biasanya selesai dalam 1x24 jam.',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlack,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Oke'),
                      ),
                    ],
                  ),
                );
              },
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
              _showPengaturanSheet(context, auth);
            }),
            const SizedBox(height: 12),
            // Tombol simulasi admin untuk demo interview
            _menuTile(Icons.admin_panel_settings_outlined, 'Simulasi Akun Admin (Demo)', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              );
            }, trailingColor: Colors.blue),
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

  void _showRiwayatSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Riwayat Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlack)),
            const SizedBox(height: 16),
            if (auth.bookingData != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                        const SizedBox(width: 8),
                        Text('Pembayaran Diterima', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _dialogInfoRow('Unit', auth.bookingData!.roomType),
                    const SizedBox(height: 4),
                    _dialogInfoRow('Tanggal', '${auth.bookingData!.bookingTime.day}/${auth.bookingData!.bookingTime.month}/${auth.bookingData!.bookingTime.year}'),
                    if (auth.assignedRoom != null) ...[
                      const SizedBox(height: 4),
                      _dialogInfoRow('Kamar', auth.assignedRoom!),
                    ],
                    const SizedBox(height: 4),
                    _dialogInfoRow('Status', auth.isResident ? 'Lunas & Aktif' : 'Menunggu Konfirmasi'),
                  ],
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text('Belum ada riwayat pembayaran', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPengaturanSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Pengaturan Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlack)),
              const SizedBox(height: 16),
              _settingTile(Icons.person_outline, 'Nama', auth.userName ?? '-'),
              const SizedBox(height: 10),
              _settingTile(Icons.mail_outline, 'Email', auth.userEmail ?? '-'),
              const SizedBox(height: 10),
              _settingTile(Icons.phone_outlined, 'Nomor HP', auth.userPhone ?? '-'),
              const SizedBox(height: 10),
              _settingTile(Icons.badge_outlined, 'Status Akun', _roleLabel(auth.currentRole)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Untuk mengubah data akun, hubungi manajemen Kostraktor.',
                          style: TextStyle(color: Colors.blue.shade800, fontSize: 11, height: 1.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Text('$label  ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _dialogInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 12, fontWeight: FontWeight.w600))),
      ],
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.resident: return 'Penghuni Aktif';
      case UserRole.pendingResident: return 'Menunggu Konfirmasi';
      case UserRole.admin: return 'Admin';
      default: return 'Calon Penghuni';
    }
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
        // Use auth context to get room number for the label
        label = 'PENGHUNI AKTIF';
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
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final displayLabel = (role == UserRole.resident && auth.assignedRoom != null)
            ? 'ACTIVE RESIDENT - ${auth.assignedRoom!.toUpperCase()}'
            : label;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(displayLabel,
              style: TextStyle(
                  color: color == Colors.green
                      ? Colors.green.shade700
                      : color == Colors.orange
                          ? Colors.orange.shade700
                          : color == Colors.blue
                              ? Colors.blue.shade700
                              : Colors.grey.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        );
      },
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

  Widget _menuTile(IconData icon, String title, VoidCallback onTap, {Widget? trailing, Color? trailingColor}) {
    final iconCol = trailingColor ?? AppTheme.primaryBlack;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: trailingColor != null ? trailingColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: trailingColor != null ? trailingColor.withOpacity(0.3) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconCol, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(color: iconCol, fontWeight: FontWeight.w500, fontSize: 14))),
            if (trailing != null) trailing,
            if (trailing == null) Icon(Icons.arrow_forward_ios, color: trailingColor ?? AppTheme.textMuted, size: 14),
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
