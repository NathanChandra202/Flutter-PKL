import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  PendingUser? _selectedUser;
  final _roomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadPendingBookings();
    });
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _handleApprove(BuildContext context, AuthProvider auth) {
    if (_selectedUser == null) return;
    if (_roomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nomor kamar terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Approve', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Setujui booking ${_selectedUser!.name} dan assign ke ${_roomController.text.trim()}?\n\nStatus pengguna akan berubah menjadi Penghuni Aktif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              
              if (_selectedUser!.id != null) {
                await auth.updateBookingStatus(_selectedUser!.id!, 'APPROVED');
                await auth.loadPendingBookings();
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_selectedUser!.name} berhasil di-approve sebagai Penghuni Aktif!'),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              setState(() {
                _selectedUser = null;
                _roomController.clear();
              });
            },
            child: const Text('Ya, Approve'),
          ),
        ],
      ),
    );
  }

  void _handleReject(BuildContext context, AuthProvider auth) {
    if (_selectedUser == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Tolak booking ${_selectedUser!.name}?\n\nStatus pengguna akan kembali menjadi Calon Penghuni.',
        ),
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
            onPressed: () async {
              Navigator.pop(ctx);
              
              if (_selectedUser!.id != null) {
                await auth.updateBookingStatus(_selectedUser!.id!, 'REJECTED');
                await auth.loadPendingBookings();
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Booking ${_selectedUser!.name} ditolak.'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              setState(() {
                _selectedUser = null;
                _roomController.clear();
              });
            },
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pending = auth.pendingApprovals;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Panel Admin',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${pending.length} Booking Menunggu Konfirmasi',
                          style: TextStyle(
                            color: pending.isEmpty ? Colors.white38 : Colors.orange.shade300,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Admin badge
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withOpacity(0.5),
                        border: Border.all(color: Colors.blue.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        auth.userName ?? 'Admin',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'Keluar',
                    onPressed: () {
                      auth.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: pending.isEmpty && _selectedUser == null
                  ? _buildEmptyState()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive: side by side on wide screens, stacked on narrow
                          final isWide = constraints.maxWidth > 600;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: _buildPendingList(pending)),
                                const SizedBox(width: 16),
                                Expanded(flex: 3, child: _buildDetailPane(context, auth)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                SizedBox(height: 200, child: _buildPendingList(pending)),
                                const SizedBox(height: 12),
                                Expanded(child: _buildDetailPane(context, auth)),
                              ],
                            );
                          }
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada booking\nyang menunggu konfirmasi',
            style: TextStyle(color: Colors.white38, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Semua booking sudah diproses.',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList(List<PendingUser> pending) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Antrian Booking',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: pending.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final user = pending[index];
                final isSelected = _selectedUser?.email == user.email;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUser = user;
                      _roomController.clear();
                    });
                  },
                  child: Container(
                    color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange.shade700),
                          ),
                          child: Center(
                            child: Text(
                              (user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
                              style: TextStyle(color: Colors.orange.shade300, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(user.bookingData.roomType, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                      ],
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

  Widget _buildDetailPane(BuildContext context, AuthProvider auth) {
    if (_selectedUser == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Text(
            'Pilih pengguna dari daftar\nuntuk melihat detail',
            style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final user = _selectedUser!;
    final booking = user.bookingData;
    final bookingDateStr =
        '${booking.bookingTime.day}/${booking.bookingTime.month}/${booking.bookingTime.year} ${booking.bookingTime.hour.toString().padLeft(2, '0')}:${booking.bookingTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.shade600),
                  ),
                  child: Center(
                    child: Text(
                      (user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
                      style: TextStyle(color: Colors.orange.shade300, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(user.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // KTP + Selfie split view
            const Text('Dokumen Identitas', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildDocPreview('Foto KTP', booking.ktpBytes, Icons.credit_card, Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _buildDocPreview('Selfie Liveness', booking.selfieBytes, Icons.face_retouching_natural, Colors.purple)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // Data Pemohon
            const Text('Data Pemohon', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            _adminInfoRow('Nama', booking.nama),
            _adminInfoRow('No HP', booking.phone),
            _adminInfoRow('NIK', booking.nik),
            _adminInfoRow('Unit Dipesan', booking.roomType),
            _adminInfoRow('Tanggal Booking', bookingDateStr),
            const SizedBox(height: 4),
            // Referensi Transaksi badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: Colors.amber.shade400, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Referensi Transaksi', style: TextStyle(color: Colors.amber.shade300, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(booking.referensiTransaksi, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // Bukti Bayar
            const Text('Bukti Pembayaran', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            _buildDocPreview('Bukti Bayar', booking.buktiBayarBytes, Icons.receipt_outlined, Colors.green),
            const SizedBox(height: 16),
            Divider(color: Colors.white12),
            const SizedBox(height: 16),

            // Assign room
            const Text('Assign Kamar', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: _roomController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'cth: Kamar 204',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.meeting_room_outlined, color: Colors.white38, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white54, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('TOLAK', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _handleReject(context, auth),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('APPROVE & AKTIFKAN', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _handleApprove(context, auth),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocPreview(String label, Uint8List? bytes, IconData icon, MaterialColor color) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade700.withOpacity(0.4)),
        color: color.shade900.withOpacity(0.15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: bytes != null
            ? Stack(fit: StackFit.expand, children: [
                Image.memory(bytes, fit: BoxFit.cover),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    color: Colors.black54,
                    child: Text(label, textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: color.shade600, size: 28),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(color: color.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Tidak tersedia', style: TextStyle(color: Colors.white30, fontSize: 9)),
              ]),
      ),
    );
  }

  Widget _adminInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
