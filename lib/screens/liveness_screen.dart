import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
 
/// Result returned when liveness check completes
class LivenessResult {
  final Uint8List? ktpBytes;
  final Uint8List? selfieBytes;
  final bool passed;

  const LivenessResult({
    this.ktpBytes,
    this.selfieBytes,
    required this.passed,
  });
}

class LivenessScreen extends StatefulWidget {
  final Uint8List? ktpBytes;
  const LivenessScreen({super.key, this.ktpBytes});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();

  // Steps: 0 = KTP, 1 = instruction, 2 = selfie, 3 = result
  int _step = 0;

  Uint8List? _ktpBytes;
  Uint8List? _selfieBytes;

  late final String _challenge;
  bool _isProcessing = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  static const _challenges = [
    'Lihat ke kamera dan SENYUM',
    'Lihat ke kamera dan BERKEDIP 2x',
    'Lihat ke kamera dan MENGANGGUK pelan',
  ];

  @override
  void initState() {
    super.initState();
    _ktpBytes = widget.ktpBytes;
    if (_ktpBytes != null) _step = 1;

    _challenge = _challenges[Random().nextInt(_challenges.length)];

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickKtp({bool gallery = false}) async {
    final picked = await _picker.pickImage(
      source: gallery ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return;
    final rawBytes = await picked.readAsBytes();
    final watermarked = await _applyKtpWatermark(rawBytes);
    setState(() {
      _ktpBytes = watermarked;
      _step = 1;
    });
  }

  /// Stamps "KOSTRAKTOR - UNTUK VERIFIKASI SAJA" + timestamp watermark on the KTP image.
  Future<Uint8List> _applyKtpWatermark(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Draw original image
    canvas.drawImage(src, Offset.zero, paint);

    final w = src.width.toDouble();
    final h = src.height.toDouble();

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw watermark text across the image
    final now = DateTime.now();
    final timestamp =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final lines = ['KOSTRAKTOR', 'UNTUK VERIFIKASI SAJA', timestamp];

    // Background strip at bottom
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.80, w, h * 0.20),
      Paint()..color = const Color(0xCC000000),
    );

    double yOffset = h * 0.82;
    for (final line in lines) {
      textPainter.text = TextSpan(
        text: line,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: w * 0.05,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      );
      textPainter.layout(maxWidth: w);
      textPainter.paint(canvas, Offset((w - textPainter.width) / 2, yOffset));
      yOffset += textPainter.height + w * 0.008;
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(src.width, src.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _takeSelfie() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _selfieBytes = bytes;
      _isProcessing = true;
    });

    // Simulate liveness processing
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _step = 3;
    });
  }

  void _retake() {
    setState(() {
      _selfieBytes = null;
      _step = 2;
    });
  }

  void _confirm() {
    Navigator.pop(
      context,
      LivenessResult(
        ktpBytes: _ktpBytes,
        selfieBytes: _selfieBytes,
        passed: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Verifikasi Identitas',
          style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlack),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildKtpStep();
      case 1: return _buildInstructionStep();
      case 2: return _buildSelfieStep();
      case 3: return _buildResultStep();
      default: return _buildKtpStep();
    }
  }

  // ─── Step 0: Upload KTP ───────────────────────────────────────────────────

  Widget _buildKtpStep() {
    return SingleChildScrollView(
      key: const ValueKey('ktp'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            step: '1 / 2',
            title: 'Foto KTP Anda',
            subtitle: 'Pastikan foto jelas, tidak buram, dan seluruh kartu terlihat.',
            icon: Icons.credit_card_outlined,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),

          // Preview or placeholder
          GestureDetector(
            onTap: () => _pickKtp(),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _ktpBytes != null ? Colors.green.shade400 : Colors.grey.shade300,
                  width: _ktpBytes != null ? 2 : 1,
                ),
              ),
              child: _ktpBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_ktpBytes!, fit: BoxFit.cover),
                          Positioned(
                            top: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.green.shade600, shape: BoxShape.circle),
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Ketuk untuk foto KTP',
                            style: TextStyle(
                                color: AppTheme.primaryBlack,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Gunakan kamera belakang',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          _buildTipBox([
            'Letakkan KTP di permukaan datar dengan cahaya cukup',
            'Hindari pantulan cahaya pada kartu',
            'Pastikan semua teks terbaca dengan jelas',
          ]),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    foregroundColor: AppTheme.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () => _pickKtp(gallery: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Foto Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _pickKtp(),
                ),
              ),
            ],
          ),

          if (_ktpBytes != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _step = 1),
              child: const Text('Lanjut ke Verifikasi Wajah',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 1: Instruction ──────────────────────────────────────────────────

  Widget _buildInstructionStep() {
    return SingleChildScrollView(
      key: const ValueKey('instruction'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            step: '2 / 2',
            title: 'Verifikasi Wajah (Liveness)',
            subtitle: 'Kami perlu memastikan kamu adalah orang yang memegang KTP tersebut.',
            icon: Icons.face_retouching_natural,
            color: Colors.purple,
          ),
          const SizedBox(height: 28),

          // Challenge card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade700, Colors.purple.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.record_voice_over, color: Colors.white, size: 36),
                const SizedBox(height: 12),
                const Text('Tantangan Liveness',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  _challenge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cara Melakukan Selfie:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlack,
                        fontSize: 13)),
                const SizedBox(height: 12),
                _buildHowRow('1', 'Posisikan wajah di dalam lingkaran panduan'),
                const SizedBox(height: 8),
                _buildHowRow('2', 'Lakukan: $_challenge'),
                const SizedBox(height: 8),
                _buildHowRow('3', 'Ambil foto saat melakukan gerakan tersebut'),
                const SizedBox(height: 8),
                _buildHowRow('4', 'Pastikan pencahayaan cukup, wajah terlihat jelas'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.camera_front, size: 20),
            label: const Text('Mulai Selfie Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            onPressed: () => setState(() => _step = 2),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Take Selfie ──────────────────────────────────────────────────

  Widget _buildSelfieStep() {
    return SingleChildScrollView(
      key: const ValueKey('selfie'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Challenge reminder
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.task_alt, color: Colors.purple.shade600, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lakukan saat foto: $_challenge',
                    style: TextStyle(
                        color: Colors.purple.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Selfie frame
          Center(
            child: ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purple.shade400, width: 3),
                  color: Colors.grey.shade100,
                ),
                child: ClipOval(
                  child: _selfieBytes != null
                      ? Image.memory(_selfieBytes!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.face, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text('Wajah Anda',
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posisikan wajah di dalam lingkaran',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 32),

          if (_isProcessing) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            const Text('Memverifikasi liveness...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted)),
          ] else ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.camera_front, size: 20),
              label: Text(
                _selfieBytes == null ? 'Ambil Selfie' : 'Foto Ulang',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: _takeSelfie,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 3: Result ───────────────────────────────────────────────────────

  Widget _buildResultStep() {
    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade300, width: 2),
              ),
              child: Icon(Icons.verified_user,
                  color: Colors.green.shade600, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verifikasi Berhasil',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlack),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Identitas kamu telah diverifikasi. Data akan diteruskan ke admin untuk konfirmasi.',
            style: TextStyle(
                color: AppTheme.textMuted, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Preview both images
          Row(
            children: [
              Expanded(
                child: _buildPreviewCard(
                  label: 'Foto KTP',
                  icon: Icons.credit_card,
                  bytes: _ktpBytes,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreviewCard(
                  label: 'Selfie Liveness',
                  icon: Icons.face_retouching_natural,
                  bytes: _selfieBytes,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                _checkRow('Foto KTP berhasil diunggah'),
                const SizedBox(height: 8),
                _checkRow('Liveness check: $_challenge'),
                const SizedBox(height: 8),
                _checkRow('Keaslian identitas terverifikasi'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlack,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _confirm,
            child: const Text('Lanjut ke Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _retake,
            icon: Icon(Icons.refresh, size: 16, color: AppTheme.textMuted),
            label: const Text('Foto Ulang Selfie',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildStepHeader({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              color: color.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: color.shade200)),
          child: Icon(icon, color: color.shade600, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step,
                  style: TextStyle(
                      color: color.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipBox(List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 16),
            const SizedBox(width: 6),
            Text('Tips',
                style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('- ', style: TextStyle(color: Colors.blue.shade600)),
                    Expanded(
                        child: Text(t,
                            style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 11,
                                height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHowRow(String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(
              color: AppTheme.primaryBlack, shape: BoxShape.circle),
          child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12, height: 1.4))),
      ],
    );
  }

  Widget _buildPreviewCard({
    required String label,
    required IconData icon,
    required Uint8List? bytes,
    required MaterialColor color,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
        color: color.shade50,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: bytes != null
            ? Stack(fit: StackFit.expand, children: [
                Image.memory(bytes, fit: BoxFit.cover),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.black54,
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: color.shade300, size: 32),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(color: color.shade400, fontSize: 11)),
              ]),
      ),
    );
  }

  Widget _checkRow(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600))),
      ],
    );
  }
}
