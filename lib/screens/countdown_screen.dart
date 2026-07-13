import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _confirmed = false;

  // Countdown timer — 2 jam = 7200 detik
  late int _remainingSeconds;
  Timer? _timer;
  bool _timedOut = false;

  // Referensi transaksi
  final _refController = TextEditingController();
  bool _refError = false;
  String _refErrorMsg = '';

  // Bukti bayar
  Uint8List? _buktiBayarBytes;
  final _picker = ImagePicker();

  // Simulasi referensi yang sudah dipakai
  final Set<String> _usedRefs = {'TRF20240001', 'TRF20240002'};

  @override
  void initState() {
    super.initState();
    _uniqueCode = (widget.bookingData?.bookingTime.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch) %
        1000;
    _remainingSeconds = 7200; // 2 jam
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timedOut = true;
          t.cancel();
          // Batalkan booking otomatis
          if (!_confirmed) {
            Provider.of<AuthProvider>(context, listen: false).cancelBooking();
          }
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

  String get _timerDisplay {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds > 1800) return Colors.green.shade700;
    if (_remainingSeconds > 600) return Colors.orange.shade700;
    return Colors.red.shade700;
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

  Future<void> _pickBukti() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _buktiBayarBytes = bytes);
  }

  void _handleKonfirmasi() {
    final ref = _refController.text.trim();
    setState(() {
      _refError = false;
      _refErrorMsg = '';
    });

    if (ref.isEmpty) {
      setState(() {
        _refError = true;
        _refErrorMsg = 'Nomor referensi transaksi wajib diisi.';
      });
      return;
    }

    if (_usedRefs.contains(ref.toUpperCase())) {
      setState(() {
        _refError = true;
        _refErrorMsg =
            'Nomor transaksi ini sudah pernah digunakan oleh pengguna lain!';
      });
      return;
    }

    if (_buktiBayarBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Upload bukti transfer terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Simpan ref ke set agar tidak bisa dipakai ulang
    _usedRefs.add(ref.toUpperCase());
    Provider.of<AuthProvider>(context, listen: false).markWaConfirmed();
    _timer?.cancel();
    setState(() => _confirmed = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Konfirmasi diterima! Admin akan segera memproses booking kamu.'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        title: const Text('Pembayaran',
            style: TextStyle(
                color: AppTheme.primaryBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlack),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: _timedOut && !_confirmed && !isApproved
          ? _buildTimeoutView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status banner
                  if (isApproved)
                    _buildSuccessBanner(auth)
                  else
                    _buildPendingBanner(),
                  const SizedBox(height: 16),

                  // Timer
                  if (!isApproved && !_confirmed)
                    _buildTimer(),
                  const SizedBox(height: 16),

                  // Bank info
                  _buildBankCard(depositFormatted, totalFormatted),
                  const SizedBox(height: 20),

                  if (!isApproved && !_confirmed) ...[
                    // Langkah selanjutnya
                    _buildStepIndicator(),
                    const SizedBox(height: 20),

                    // Upload bukti
                    _buildUploadBukti(),
                    const SizedBox(height: 16),

                    // Input referensi
                    _buildRefInput(),
                    const SizedBox(height: 20),

                    // Tombol konfirmasi
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlack,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text('Konfirmasi Bukti Transfer',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: _handleKonfirmasi,
                      ),
                    ),
                  ] else if (_confirmed && !isApproved) ...[
                    _buildConfirmedState(),
                  ] else if (isApproved) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlack,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MainNavigation()),
                            (route) => false,
                          );
                        },
                        child: const Text('MASUK KE BERANDA',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: _timedOut ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _timedOut ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: _timerColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batas Waktu Pembayaran',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  _timerDisplay,
                  style: TextStyle(
                    color: _timerColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (_remainingSeconds <= 600)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Segera!',
                  style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildBankCard(String depositFormatted, String totalFormatted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: Colors.yellow.shade700,
                    borderRadius: BorderRadius.circular(8)),
                child: const Center(
                    child: Text('M',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18))),
              ),
              const SizedBox(width: 12),
              const Flexible(
                  child: Text('Bank Mandiri',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Nomor Rekening',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Builder(builder: (context) {
                final w = MediaQuery.of(context).size.width;
                return SelectableText(
                  '123-00-998877-1',
                  style: TextStyle(
                    fontSize: w < 360 ? 18 : 22,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlack,
                  ),
                );
              }),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      const ClipboardData(text: '12300998877 1'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Nomor rekening disalin'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(Icons.copy_outlined,
                    size: 18, color: Colors.grey.shade500),
              ),
            ],
          ),
          const Text('PT KOSTRAKTOR JAYA UTAMA',
              style: TextStyle(
                  color: AppTheme.primaryBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
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
              const Text('TOTAL TRANSFER',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                      fontSize: 13)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(totalFormatted,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlack,
                        fontSize: 16),
                    textAlign: TextAlign.end),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200)),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.orange.shade700, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transfer nominal TEPAT termasuk kode unik agar sistem kami dapat memverifikasi pembayaran.',
                    style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 11,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBukti() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Upload Bukti Transfer',
            style: TextStyle(
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickBukti,
          child: Container(
            height: _buktiBayarBytes != null ? 160 : 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _buktiBayarBytes != null
                    ? Colors.green.shade400
                    : Colors.grey.shade300,
                width: _buktiBayarBytes != null ? 1.5 : 1,
              ),
            ),
            child: _buktiBayarBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_buktiBayarBytes!, fit: BoxFit.cover),
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 14),
                          ),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.black45,
                            child: const Text('Ketuk untuk ganti',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_outlined,
                          size: 28, color: Colors.grey.shade400),
                      const SizedBox(height: 6),
                      const Text('Ketuk untuk upload screenshot struk',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nomor Referensi Transaksi',
            style: TextStyle(
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 4),
        const Text('ID transaksi dari m-banking (contoh: TRF20240003)',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 8),
        TextField(
          controller: _refController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
              color: AppTheme.primaryBlack, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Masukkan nomor referensi...',
            hintStyle:
                const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.receipt_long_outlined,
                color: AppTheme.textMuted, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _refError
                      ? Colors.redAccent
                      : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _refError
                      ? Colors.redAccent
                      : AppTheme.primaryBlack,
                  width: 1.5),
            ),
            errorText: _refError ? _refErrorMsg : null,
          ),
          onChanged: (_) {
            if (_refError) setState(() => _refError = false);
          },
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
          const Text('Langkah Selanjutnya',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                  fontSize: 13)),
          const SizedBox(height: 12),
          _stepRow('1', 'Transfer ke rekening di atas dengan nominal tepat',
              true),
          const SizedBox(height: 8),
          _stepRow('2', 'Upload screenshot struk transfer', _buktiBayarBytes != null),
          const SizedBox(height: 8),
          _stepRow('3', 'Isi nomor referensi transaksi bank', _refController.text.isNotEmpty),
          const SizedBox(height: 8),
          _stepRow('4', 'Tekan tombol konfirmasi di bawah', _confirmed),
        ],
      ),
    );
  }

  Widget _buildConfirmedState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Konfirmasi Diterima',
                    style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text('Admin akan memverifikasi dan mengaktifkan kamarmu.',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off_outlined,
                size: 64, color: Colors.red.shade400),
            const SizedBox(height: 20),
            Text('Waktu Habis',
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Batas waktu pembayaran 2 jam telah habis. Booking otomatis dibatalkan dan kamar dirilis kembali ke publik.',
              style: TextStyle(
                  color: AppTheme.textMuted, fontSize: 13, height: 1.5),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MainNavigation()),
                    (route) => false,
                  );
                },
                child: const Text('Kembali ke Beranda',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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
          Text('Status Diupgrade!',
              style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Selamat ${auth.userName ?? 'Penghuni'}! Anda kini menjadi Penghuni Aktif Kostraktor.\n${auth.assignedRoom != null ? "Kamar: ${auth.assignedRoom}" : ""}',
            style:
                TextStyle(color: Colors.green.shade700, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions, color: Colors.orange.shade600, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menunggu Konfirmasi Admin',
                    style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  'Lengkapi bukti transfer dan nomor referensi di bawah.',
                  style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
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
                : Text(num,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
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
}
