import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
  late final int _uniqueCode;
  bool _waContacted = false;

  // Countdown timer — 2 hours = 7200 seconds
  static const _totalSeconds = 7200;
  int _secondsLeft = _totalSeconds;
  Timer? _timer;
  bool _expired = false;

  // Bukti bayar & referensi
  Uint8List? _buktiBayarBytes;
  final _refController = TextEditingController();
  bool _refDuplicate = false;
  // Simple in-memory used-refs store (shared across instances via static)
  static final Set<String> _usedReferensi = {};

  @override
  void initState() {
    super.initState();
    _uniqueCode =
        (widget.bookingData?.bookingTime.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch) %
        1000;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _expired = true;
          t.cancel();
          // Auto-cancel booking
          Provider.of<AuthProvider>(context, listen: false).cancelBooking();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refController.dispose();
    super.dispose();
  }

  String get _timerString {
    final h = _secondsLeft ~/ 3600;
    final m = (_secondsLeft % 3600) ~/ 60;
    final s = _secondsLeft % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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

  Future<void> _pickBuktiBayar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _buktiBayarBytes = bytes);
  }

  void _handleKonfirmasi() {
    final ref = _refController.text.trim().toUpperCase();
    if (ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nomor referensi transaksi bank.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_buktiBayarBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unggah bukti transfer terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    // UNIQUE CONSTRAINT check
    if (_usedReferensi.contains(ref)) {
      setState(() => _refDuplicate = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Nomor transaksi ini sudah pernah digunakan oleh pengguna lain!',
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    setState(() => _refDuplicate = false);
    _usedReferensi.add(ref);

    // Update booking with bukti bayar + referensi
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.markWaConfirmed();
    setState(() => _waContacted = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Konfirmasi terkirim! Tunggu verifikasi dari admin.',
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text disalin ke clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
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
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            // Status / Timer banner
            if (_expired)
              _buildExpiredBanner()
            else if (isApproved)
              _buildSuccessBanner(auth)
            else
              _buildTimerBanner(),
            const SizedBox(height: 24),

            // Bank Transfer Card
            _buildBankCard(depositFormatted, totalFormatted),
            const SizedBox(height: 24),

            if (!isApproved && !_expired) ...[
              // Progress steps
              _buildStepIndicator(),
              const SizedBox(height: 20),

              // Upload bukti bayar
              _buildBuktiBayarSection(),
              const SizedBox(height: 16),

              // Referensi Transaksi input
              _buildReferensiSection(),
              const SizedBox(height: 20),

              // Konfirmasi button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _waContacted
                        ? Colors.green.shade700
                        : const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: Icon(
                    _waContacted ? Icons.check_circle : Icons.send_outlined,
                    size: 20,
                  ),
                  label: Text(
                    _waContacted
                        ? 'Konfirmasi Terkirim'
                        : 'Kirim Konfirmasi Pembayaran',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: _waContacted ? null : _handleKonfirmasi,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _waContacted
                    ? 'Admin akan memverifikasi dan mengaktifkan akun kamu.'
                    : 'Isi bukti bayar dan nomor referensi sebelum konfirmasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _waContacted
                      ? Colors.green.shade700
                      : AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ] else if (isApproved) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                    (route) => false,
                  ),
                  child: const Text(
                    'SELAMAT DATANG! MASUK KE BERANDA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildTimerBanner() {
    final isUrgent = _secondsLeft < 600; // under 10 min
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Selesaikan Pembayaran',
            style: TextStyle(
              color: isUrgent ? Colors.red.shade800 : Colors.orange.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _timerString,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: isUrgent ? Colors.red.shade700 : Colors.orange.shade700,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Booking otomatis dibatalkan jika waktu habis.',
            style: TextStyle(
              color: isUrgent ? Colors.red.shade600 : Colors.orange.shade700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.timer_off_outlined, color: Colors.red.shade600, size: 40),
          const SizedBox(height: 10),
          Text(
            'Waktu Pembayaran Habis',
            style: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Booking kamu telah dibatalkan otomatis. Silakan ajukan sewa kembali.',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
          Text(
            'Pembayaran Terverifikasi!',
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selamat ${auth.userName ?? 'Penghuni'}! Anda kini Penghuni Aktif Kostraktor.\n${auth.assignedRoom != null ? "Kamar: ${auth.assignedRoom}" : ""}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(String depositFormatted, String totalFormatted) {
    const rekening = '123-00-998877-1';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.yellow.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Bank Mandiri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nomor Rekening',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  rekening,
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(rekening),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Salin',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'PT KOSTRAKTOR JAYA UTAMA',
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _buildPayRow('Sewa Bulanan', depositFormatted),
          const SizedBox(height: 8),
          _buildPayRow('Kode Unik Identifikasi', '+$_uniqueCode'),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL TRANSFER',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  totalFormatted,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _copyToClipboard(totalFormatted),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transfer nominal TEPAT termasuk kode unik agar sistem dapat memverifikasi. Ketuk untuk salin total.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuktiBayarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Upload Bukti Transfer',
          style: TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickBuktiBayar,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              color: _buktiBayarBytes != null
                  ? Colors.transparent
                  : Colors.grey.shade50,
              border: Border.all(
                color: _buktiBayarBytes != null
                    ? Colors.green.shade400
                    : Colors.grey.shade300,
                width: _buktiBayarBytes != null ? 1.5 : 1,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buktiBayarBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_buktiBayarBytes!, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.black54,
                            child: const Text(
                              'Bukti Transfer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        size: 36,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ketuk untuk unggah screenshot struk m-banking',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferensiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nomor Referensi Transaksi Bank',
          style: TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _refController,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() => _refDuplicate = false),
          style: const TextStyle(
            color: AppTheme.primaryBlack,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            hintText: 'cth: TRF123456789ABC',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: const Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.textMuted,
              size: 20,
            ),
            filled: true,
            fillColor: _refDuplicate ? Colors.red.shade50 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _refDuplicate
                    ? Colors.red.shade400
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _refDuplicate
                    ? Colors.red.shade600
                    : AppTheme.primaryBlack,
                width: 1.5,
              ),
            ),
            errorText: _refDuplicate
                ? 'Nomor transaksi ini sudah pernah digunakan!'
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kode unik dari mutasi e-banking Anda. Wajib diisi.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
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
          const Text(
            'Langkah Selanjutnya',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _stepRow(
            '1',
            'Transfer ke rekening di atas dengan nominal tepat',
            true,
          ),
          const SizedBox(height: 8),
          _stepRow('2', 'Unggah foto bukti transfer', _buktiBayarBytes != null),
          const SizedBox(height: 8),
          _stepRow(
            '3',
            'Masukkan nomor referensi transaksi bank',
            _refController.text.isNotEmpty,
          ),
          const SizedBox(height: 8),
          _stepRow('4', 'Tekan tombol Kirim Konfirmasi', _waContacted),
        ],
      ),
    );
  }

  Widget _stepRow(String num, String text, bool done) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done ? Colors.green.shade600 : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 13)
                : Text(
                    num,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

  Widget _buildPayRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
