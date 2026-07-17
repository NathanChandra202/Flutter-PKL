import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'countdown_screen.dart';
import 'liveness_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic>? unitData;
  const BookingFormScreen({super.key, this.unitData});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _namaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  final _tanggalController = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedDate;

  // Verification state
  Uint8List? _ktpBytes;
  Uint8List? _selfieBytes;
  bool _verificationPassed = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userName != null) _namaController.text = auth.userName!;
    if (auth.userPhone != null) _phoneController.text = auth.userPhone!;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = DateTime(now.year + 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlack,
              onPrimary: Colors.white,
              onSurface: AppTheme.primaryBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Format tanggal manual tanpa dependency locale
        final months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        _tanggalController.text =
            '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      });
    }
  }

  Future<void> _openLiveness() async {
    final result = await Navigator.push<LivenessResult>(
      context,
      MaterialPageRoute(builder: (_) => LivenessScreen(ktpBytes: _ktpBytes)),
    );
    if (result == null) return;

    if (result.ktpBytesRaw == null || result.selfieBytes == null) {
      return;
    }

    if (!mounted) return;

    // Show loading dialog — AI face detection can take 10-30 seconds
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const CircularProgressIndicator(
                color: AppTheme.primaryBlack,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                'Memverifikasi Wajah...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'AI sedang mencocokkan wajah KTP dengan selfie Anda.\nProses ini memerlukan waktu 10–30 detik.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    final auth = Provider.of<AuthProvider>(context, listen: false);
    // Use raw KTP bytes (no watermark) for better face detection accuracy
    final error = await auth.verifyFaceMatch(result.ktpBytesRaw!, result.selfieBytes!);

    if (!mounted) return;
    Navigator.of(context).pop(); // close loading dialog

    if (error == null) {
      // ✅ Verification passed
      setState(() {
        _ktpBytes = result.ktpBytes;      // watermarked for display
        _selfieBytes = result.selfieBytes;
        _verificationPassed = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Verifikasi Wajah Berhasil! ✅', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      // ❌ Verification failed — show detailed dialog
      if (!mounted) return;
      _showVerificationErrorDialog(error);
    }
  }

  void _showVerificationErrorDialog(String errorMessage) {
    // Split message and suggestion if present
    final parts = errorMessage.split('\n\n');
    final mainMsg = parts.isNotEmpty ? parts[0] : errorMessage;
    final suggestion = parts.length > 1 ? parts.sublist(1).join('\n\n') : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Verifikasi Gagal',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mainMsg, style: const TextStyle(fontSize: 13, height: 1.5)),
              if (suggestion != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 15),
                          const SizedBox(width: 6),
                          Text('Tips', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(suggestion, style: TextStyle(fontSize: 12, color: Colors.blue.shade800, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlack,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              _openLiveness();
            },
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    final nama = _namaController.text.trim();
    final phone = _phoneController.text.trim();
    final nik = _nikController.text.trim();

    if (nama.isEmpty || phone.isEmpty || nik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data diri.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor HP minimal 10 digit.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (nik.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor KTP harus tepat 16 digit.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih tanggal mulai menghuni.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_verificationPassed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Harap selesaikan verifikasi identitas terlebih dahulu.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Verifikasi',
            textColor: Colors.white,
            onPressed: _openLiveness,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final booking = BookingData(
      nama: _namaController.text.trim().toUpperCase(),
      phone: _phoneController.text.trim(),
      nik: _nikController.text.trim(),
      roomType: widget.unitData?['title'] ?? 'Tipe Standard',
      bookingTime: DateTime.now(),
      tanggalMulaiMenghuni: _selectedDate,
      ktpBytes: _ktpBytes,
      selfieBytes: _selfieBytes,
    );

    await auth.submitBooking(booking);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CountdownScreen(unitData: widget.unitData, bookingData: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitTitle = widget.unitData?['title'] ?? 'Tipe Standard';
    final unitPrice = widget.unitData?['price'] ?? 'Rp 800.000';

    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pengajuan Sewa',
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
            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProgressStep('1', true, 'Data Diri'),
                _buildProgressLine(true),
                _buildProgressStep('2', false, 'Pembayaran'),
                _buildProgressLine(false),
                _buildProgressStep('3', false, 'Konfirmasi'),
              ],
            ),
            const SizedBox(height: 24),

            // Selected Room Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlack,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unitTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pasar Rebo, Jakarta Timur',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        unitPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack,
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        '/bulan',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data Diri
            Container(
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Data Diri Lengkap',
                    style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sesuai dengan KTP/Identitas resmi',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  _buildInput(
                    _namaController,
                    Icons.person_outline,
                    'Nama Lengkap (Sesuai KTP)',
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    _phoneController,
                    Icons.phone_outlined,
                    'Nomor HP (min. 10 digit)',
                    isPhone: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    _nikController,
                    Icons.credit_card_outlined,
                    'NIK (16 digit angka)',
                    isNumber: true,
                    maxLength: 16,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _tanggalController,
                            decoration: InputDecoration(
                              hintText: 'Tap untuk pilih tanggal',
                              hintStyle: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              suffixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event,
                                      color: Colors.blue.shade700,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pilih',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              filled: true,
                              fillColor: _selectedDate != null
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _selectedDate != null
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade500,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 13,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ketuk field di atas untuk memilih kapan Anda mulai tinggal',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verifikasi Identitas + Liveness
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _verificationPassed
                      ? Colors.green.shade300
                      : Colors.grey.shade200,
                  width: _verificationPassed ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verifikasi Identitas',
                              style: TextStyle(
                                color: AppTheme.primaryBlack,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Foto KTP + Foto Selfie (wajib)',
                              style: TextStyle(
                                color: _verificationPassed
                                    ? Colors.green.shade700
                                    : AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_verificationPassed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Terverifikasi',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Preview thumbnails if verified
                  if (_verificationPassed &&
                      _ktpBytes != null &&
                      _selfieBytes != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _thumbPreview(
                            _ktpBytes!,
                            'KTP',
                            Icons.credit_card,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _thumbPreview(
                            _selfieBytes!,
                            'Selfie',
                            Icons.face,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  GestureDetector(
                    onTap: _openLiveness,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _verificationPassed
                            ? Colors.green.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _verificationPassed
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _verificationPassed
                                ? Icons.verified_user
                                : Icons.face_retouching_natural,
                            color: _verificationPassed
                                ? Colors.green.shade600
                                : Colors.grey.shade500,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _verificationPassed
                                ? 'Ulangi Verifikasi'
                                : 'Mulai Verifikasi KTP & Wajah',
                            style: TextStyle(
                              color: _verificationPassed
                                  ? Colors.green.shade700
                                  : AppTheme.primaryBlack,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!_verificationPassed) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Wajib diselesaikan sebelum submit',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verificationPassed
                      ? AppTheme.primaryBlack
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: _verificationPassed ? 2 : 0,
                ),
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_verificationPassed)
                            const Icon(Icons.lock, size: 16),
                          if (!_verificationPassed) const SizedBox(width: 6),
                          const Text(
                            'LANJUT KE PEMBAYARAN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _thumbPreview(
    Uint8List bytes,
    String label,
    IconData icon,
    MaterialColor color,
  ) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.black45,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    IconData icon,
    String hint, {
    bool isPhone = false,
    bool isNumber = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isPhone
          ? TextInputType.phone
          : (isNumber ? TextInputType.number : TextInputType.text),
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      buildCounter: maxLength != null
          ? (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => Text(
              '$currentLength / $maxLength',
              style: TextStyle(
                color: currentLength == maxLength
                    ? Colors.green.shade700
                    : AppTheme.textMuted,
                fontSize: 11,
              ),
            )
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlack, width: 2),
        ),
      ),
    );
  }

  Widget _buildProgressStep(String step, bool isActive, String label) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryBlack : Colors.white,
            border: Border.all(
              color: isActive ? AppTheme.primaryBlack : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppTheme.primaryBlack : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? AppTheme.primaryBlack : Colors.grey.shade300,
    );
  }
}
