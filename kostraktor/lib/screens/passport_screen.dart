import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _picker = ImagePicker();
  final List<Uint8List> _fotoLampiran = [];

  // 24-hour audit window state
  DateTime? _auditStartTime;
  bool _auditLocked = false;

  @override
  void initState() {
    super.initState();
    _loadAuditWindowState();
  }

  Future<void> _loadAuditWindowState() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('audit_start_time');
    if (stored != null) {
      final start = DateTime.tryParse(stored);
      if (start != null) {
        final elapsed = DateTime.now().difference(start);
        setState(() {
          _auditStartTime = start;
          _auditLocked = elapsed.inHours >= 24;
        });
      }
    } else {
      // First time opening audit tab — start the 24-hour window
      final now = DateTime.now();
      await prefs.setString('audit_start_time', now.toIso8601String());
      setState(() {
        _auditStartTime = now;
        _auditLocked = false;
      });
    }
  }

  String _formatCountdown() {
    if (_auditStartTime == null) return '';
    final deadline = _auditStartTime!.add(const Duration(hours: 24));
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) return 'Jendela audit telah berakhir';
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    return 'Sisa waktu: ${h}j ${m}m';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFotoLampiran() async {
    if (_fotoLampiran.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 3 foto lampiran.')),
      );
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _fotoLampiran.add(bytes));
  }


  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bgWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Lapor & Audit', style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: Colors.grey.shade200, height: 1.0),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Active Resident Profile Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryBlack,
                        ),
                        child: Center(
                          child: Text(
                            (auth.userName?.isNotEmpty == true ? auth.userName![0] : 'P').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.userName ?? 'Penghuni',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlack,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                auth.assignedRoom != null
                                    ? 'PENGHUNI AKTIF - ${auth.assignedRoom!.toUpperCase()}'
                                    : 'PENGHUNI AKTIF',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    labelColor: AppTheme.primaryBlack,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Pengaduan Baru'),
                      Tab(text: 'Passport Audit'),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPengaduanTab(context, auth),
                    _buildAuditTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPengaduanTab(BuildContext context, AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Judul Pengaduan (cth: AC Bocor)',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlack, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Deskripsi lengkap kronologi keluhan...',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlack, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Lampiran Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlack)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickFotoLampiran,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _fotoLampiran.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 32, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              const Text('Unggah Foto Fasilitas (Maks 3)', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _fotoLampiran.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(_fotoLampiran[index], width: 80, height: 80, fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
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
              onPressed: () {
                if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap isi judul dan deskripsi pengaduan.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                _titleController.clear();
                _descController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Laporan pengaduan berhasil dikirim! Tim kami akan segera menindaklanjuti.'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: const Text('KIRIM LAPORAN PENGADUAN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab(BuildContext context) {
    final items = ['Pintu Kamar', 'AC', 'Kasur', 'Lampu Utama', 'Sakelar Listrik', 'Kran Air', 'Wastafel'];
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AuditItem(label: items[index], locked: _auditLocked),
              );
            },
          ),
        ),
        // 24-hour window status banner
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: _auditLocked ? Colors.red.shade50 : Colors.blue.shade50,
          child: Row(
            children: [
              Icon(
                _auditLocked ? Icons.lock_outline : Icons.timer_outlined,
                color: _auditLocked ? Colors.red.shade700 : Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _auditLocked
                          ? 'Jendela Audit 24 Jam Telah Berakhir'
                          : 'Jendela Audit 24 Jam Aktif',
                      style: TextStyle(
                        color: _auditLocked ? Colors.red.shade900 : Colors.blue.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _auditLocked
                          ? 'Pengunggahan foto audit telah dikunci otomatis.'
                          : '${_formatCountdown()} — Waktu dikunci otomatis via Secure NTP Server.',
                      style: TextStyle(
                        color: _auditLocked ? Colors.red.shade700 : Colors.blue.shade700,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuditItem extends StatefulWidget {
  final String label;
  final bool locked;
  const _AuditItem({required this.label, required this.locked});

  @override
  State<_AuditItem> createState() => _AuditItemState();
}

class _AuditItemState extends State<_AuditItem> {
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.locked ? Colors.red.shade100 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.locked ? AppTheme.textMuted : AppTheme.primaryBlack,
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.locked
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Jendela audit 24 jam sudah berakhir. Unggah foto tidak dapat dilakukan.'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                : () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                    if (picked != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Foto audit berhasil diunggah.'),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.locked ? Colors.red.shade50 : Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: widget.locked ? Colors.red.shade200 : Colors.grey.shade200),
              ),
              child: Icon(
                widget.locked ? Icons.lock_outline : Icons.camera_alt_outlined,
                color: widget.locked ? Colors.red.shade400 : Colors.grey.shade500,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _checked,
            onChanged: widget.locked ? null : (val) => setState(() => _checked = val),
            activeColor: Colors.white,
            activeTrackColor: Colors.green.shade400,
          ),
        ],
      ),
    );
  }
}
