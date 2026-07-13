import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'main_navigation.dart';

class CountdownScreen extends StatefulWidget {
  final Map<String, dynamic>? unitData;
  final BookingData? bookingData;
  const CountdownScreen({super.key, this.unitData, this.bookingData});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  // Generate unique payment code based on booking time
  late final int _uniqueCode;
  bool _waContacted = false;

  @override
  void initState() {
    super.initState();
    _uniqueCode = (widget.bookingData?.bookingTime.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch) % 1000;
  }

  int _getBaseAmount() {
    final price = widget.unitData?['price'] as String? ?? 'Rp 800.000';
    final cleaned = price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 800000;
  }

  String _formatRupiah(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  Future<void> _openWhatsApp() async {
    if (mounted) {
      Provider.of<AuthProvider>(context, listen: false).markWaConfirmed();
      setState(() => _waContacted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Konfirmasi terkirim! Tunggu verifikasi dari admin.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseAmount = _getBaseAmount();
    final totalAmount = baseAmount + _uniqueCode;
    final totalFormatted = _formatRupiah(totalAmount);
    final depositFormatted = _formatRupiah(baseAmount);
    final auth = Provider.of<AuthProvider>(context);

    final isApproved = auth.isResident;

    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pembayaran', style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlack),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            if (isApproved)
              _buildSuccessBanner(auth)
            else
              _buildPendingBanner(),
            const SizedBox(height: 24),

            // Bank Transfer Info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.yellow.shade700, borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(child: Text('Bank Mandiri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlack))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Nomor Rekening', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Builder(builder: (context) {
                    final w = MediaQuery.of(context).size.width;
                    return SelectableText(
                      '123-00-998877-1',
                      style: TextStyle(
                        fontSize: w < 360 ? 18 : 24,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryBlack,
                      ),
                    );
                  }),
                  const Text('PT KOSTRAKTOR JAYA UTAMA',
                      style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildPayRow('Sewa Bulanan', depositFormatted),
                  const SizedBox(height: 8),
                  _buildPayRow('Kode Unik Identifikasi', '+$_uniqueCode'),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL TRANSFER', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlack, fontSize: 13)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(totalFormatted,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlack, fontSize: 16),
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Transfer nominal TEPAT termasuk kode unik agar sistem kami dapat memverifikasi pembayaran Anda.',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 11, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!isApproved) ...[
              // Step indicator
              _buildStepIndicator(),
              const SizedBox(height: 20),

              // WhatsApp Confirmation Button (primary action)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _waContacted ? Colors.green.shade700 : const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: Icon(_waContacted ? Icons.check_circle : Icons.check_circle_outline, size: 20),
                  label: Text(
                    _waContacted
                        ? 'Konfirmasi Terkirim'
                        : 'Konfirmasi Bukti Transfer',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _waContacted ? null : _openWhatsApp,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _waContacted
                    ? 'Konfirmasi diterima! Admin akan segera memproses booking kamu.'
                    : 'Setelah transfer, tekan tombol di atas untuk konfirmasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _waContacted ? Colors.green.shade700 : AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: _waContacted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ] else ...[
              // Approved — go to main
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                      (route) => false,
                    );
                  },
                  child: const Text('SELAMAT DATANG! MASUK KE BERANDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Langkah Selanjutnya', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlack, fontSize: 13)),
          const SizedBox(height: 12),
          _stepRow('1', 'Transfer ke rekening di atas dengan nominal tepat', true),
          const SizedBox(height: 8),
          _stepRow('2', 'Konfirmasi bukti transfer ke penjaga kos', _waContacted),
        ],
      ),
    );
  }

  Widget _stepRow(String num, String text, bool done) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: done ? Colors.green.shade600 : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 13)
                : Text(num, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: done ? Colors.green.shade700 : AppTheme.textMuted,
              fontSize: 12,
              height: 1.4,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBanner(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
          const SizedBox(height: 12),
          Text('Status Diupgrade!', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Selamat ${auth.userName ?? 'Penghuni'}! Anda kini menjadi Penghuni Aktif Kostraktor.\n${auth.assignedRoom != null ? "Kamar: ${auth.assignedRoom}" : ""}',
            style: TextStyle(color: Colors.green.shade700, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.pending_actions, color: Colors.orange.shade600, size: 48),
          const SizedBox(height: 12),
          Text('Menunggu Konfirmasi Admin', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Booking Anda telah diterima. Lakukan transfer dan konfirmasi ke penjaga kos via WhatsApp untuk mempercepat proses.',
            style: TextStyle(color: Colors.orange.shade700, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPayRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

