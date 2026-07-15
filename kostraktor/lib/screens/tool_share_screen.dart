import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';

class ToolShareScreen extends StatefulWidget {
  const ToolShareScreen({super.key});

  @override
  State<ToolShareScreen> createState() => _ToolShareScreenState();
}

class _ToolShareScreenState extends State<ToolShareScreen> {
  // State alat: true = tersedia, false = dipinjam
  final Map<String, bool> _toolStatus = {
    'Vacuum Cleaner': true,
    'Tangga Lipat': false,
    'Bor Listrik': true,
    'Troli Galon': true,
  };

  final Map<String, IconData> _toolIcons = {
    'Vacuum Cleaner': Icons.cleaning_services_outlined,
    'Tangga Lipat': Icons.straighten_outlined,
    'Bor Listrik': Icons.handyman_outlined,
    'Troli Galon': Icons.shopping_cart_outlined,
  };

  final Map<String, Uint8List?> _returnPhotos = {};  // foto kondisi saat dikembalikan

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Peminjaman Alat',
            style: TextStyle(
                color: AppTheme.primaryBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlack),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scan Barcode card di bagian atas
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                if (picked != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Barcode alat berhasil discan. Pilih alat dari daftar di bawah.'),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Barcode Alat',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Ketuk untuk scan QR/barcode pada alat',
                              style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Alat Tersedia',
                      style: TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${_toolStatus.values.where((v) => v).length} Tersedia',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: _toolStatus.keys
                  .map((name) => _buildToolCard(
                        context,
                        name,
                        _toolStatus[name]!,
                        _toolIcons[name]!,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
      BuildContext context, String title, bool isAvailable, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          final prevPhoto = _returnPhotos[title];
          if (prevPhoto != null) {
            _showChainOfCustodyDialog(context, title, prevPhoto);
          } else {
            _showScanPopup(context, title);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title sedang dipinjam penghuni lain.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isAvailable
                  ? Colors.grey.shade200
                  : Colors.orange.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isAvailable
                      ? Colors.grey.shade50
                      : Colors.orange.shade50,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Icon(icon,
                    size: 48,
                    color: isAvailable
                        ? Colors.grey.shade400
                        : Colors.orange.shade300),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: isAvailable
                              ? Colors.green.shade200
                              : Colors.orange.shade200),
                    ),
                    child: Text(
                      isAvailable ? 'Tersedia' : 'Dipinjam',
                      style: TextStyle(
                          color: isAvailable
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!isAvailable) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showReturnPopup(context, title),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text('Kembalikan',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChainOfCustodyDialog(BuildContext context, String title, Uint8List prevPhoto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Row(
          children: [
            Icon(Icons.camera_enhance_outlined, color: Colors.orange.shade700, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Cek Kondisi Alat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Ini foto kondisi $title dari peminjam sebelumnya. Apakah kondisi alat saat ini MULUS dan sesuai dengan foto ini?',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(prevPhoto, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text('Foto dari peminjam sebelumnya',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          // Alat Rusak — lock tool + blame previous user
          TextButton.icon(
            icon: Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 18),
            label: Text('Tidak, Alat Rusak', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _toolStatus[title] = false; // lock as maintenance
                _returnPhotos.remove(title);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title dikunci — status MAINTENANCE. Laporan dikirim ke peminjam sebelumnya.'),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlack,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Ya, Kondisi Baik', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              _showScanPopup(context, title);
            },
          ),
        ],
      ),
    );
  }

  void _showReturnPopup(BuildContext context, String title) {
    Uint8List? returnBytes;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Text('Kembalikan $title',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlack, fontSize: 18)),
                  const SizedBox(height: 6),
                  const Text(
                    'Foto kondisi barang saat dikembalikan sebagai chain of custody.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                      if (picked == null) return;
                      final bytes = await picked.readAsBytes();
                      setModalState(() => returnBytes = bytes);
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: returnBytes != null ? Colors.transparent : Colors.grey.shade100,
                        border: Border.all(
                          color: returnBytes != null ? Colors.blue.shade300 : Colors.grey.shade300,
                          width: returnBytes != null ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: returnBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(returnBytes!, fit: BoxFit.cover),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.blue.shade600, shape: BoxShape.circle),
                                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text('Tap untuk foto kondisi barang (wajib)',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: returnBytes == null
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              setState(() {
                                _toolStatus[title] = true;
                                _returnPhotos[title] = returnBytes;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$title berhasil dikembalikan. Foto kondisi tersimpan sebagai bukti.'),
                                  backgroundColor: Colors.blue.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                      child: const Text('Konfirmasi Pengembalian',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    returnBytes == null ? 'Foto kondisi barang wajib diambil sebelum mengembalikan.' : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade400, fontSize: 11),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showScanPopup(BuildContext context, String title) {
    Uint8List? scanBytes;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Text('Pinjam $title',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack,
                          fontSize: 18)),
                  const SizedBox(height: 6),
                  const Text(
                    'Foto kondisi barang sebelum dipinjam sebagai bukti.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.camera, imageQuality: 75);
                      if (picked == null) return;
                      final bytes = await picked.readAsBytes();
                      setModalState(() => scanBytes = bytes);
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: scanBytes != null
                            ? Colors.transparent
                            : Colors.grey.shade100,
                        border: Border.all(
                            color: scanBytes != null
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                            width: scanBytes != null ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: scanBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(scanBytes!, fit: BoxFit.cover),
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
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text('Tap untuk foto kondisi barang',
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlack,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: scanBytes == null
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              // Update status alat jadi dipinjam
                              setState(() => _toolStatus[title] = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$title berhasil dipinjam! Kembalikan dalam 2 jam.'),
                                  backgroundColor: Colors.green.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                      child: const Text('Pinjam Sekarang',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scanBytes == null ? 'Foto kondisi barang wajib diambil sebelum meminjam.' : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade400, fontSize: 11),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
