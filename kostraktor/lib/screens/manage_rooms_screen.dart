import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/format_utils.dart';

// ── Top-level isolate function — harus di luar class agar bisa dipakai compute()
/// Decode gambar apa pun (termasuk HDR/wide-gamut) lalu re-encode ke JPEG sRGB
/// standar dengan lebar maksimal 1600 px. Berjalan di isolate terpisah sehingga
/// UI thread tidak freeze saat memproses foto 4K.
Uint8List? _decodeAndEncodeIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  // Konversi ke sRGB eksplisit (hilangkan color profile non-standard)
  final srgb = img.Image.from(decoded);
  // Batasi lebar supaya ukuran upload tetap wajar
  final resized = srgb.width > 1600
      ? img.copyResize(srgb, width: 1600)
      : srgb;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}

/// Wrapper async yang menjalankan decode+re-encode di isolate terpisah.
Future<Uint8List?> _reencodeToJpeg(Uint8List originalBytes) {
  return compute(_decodeAndEncodeIsolate, originalBytes);
}

/// Formatter pemisah ribuan Indonesia (titik) untuk input harga.
/// Hanya menyimpan digit, lalu format ulang dengan NumberFormat.
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip semua karakter non-digit
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final number = int.parse(digits);
    final formatted = _fmt.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final rooms = await auth.fetchRooms(all: true);
    if (mounted) {
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    }
  }

  List<String> _roomImageUrls(Map<String, dynamic> room, AuthProvider auth) {
    final urls = <String>[];
    final main = room['image_url']?.toString() ?? '';
    if (main.isNotEmpty) urls.add(main);
    urls.addAll(parseAdditionalImages(room['additional_images']));
    return urls;
  }

  void _showRoomForm({Map<String, dynamic>? room}) {
    final isEditing = room != null;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nameController = TextEditingController(text: room?['name']);
    final descController = TextEditingController(text: room?['description']);

    final existingPrice = room?['price_per_month'];
    final initialPriceText = existingPrice != null
        ? NumberFormat('#,###', 'id_ID').format(existingPrice.toInt())
        : '';
    final priceController = TextEditingController(text: initialPriceText);

    final typeController = TextEditingController(text: room?['room_type'] ?? 'Standard');
    final facilitiesController = TextEditingController(text: room?['facilities']);

    List<String> serverImageUrls =
        isEditing ? _roomImageUrls(room, auth) : <String>[];
    // Bytes JPEG bersih hasil re-encode — bukan XFile path asli
    List<Uint8List> pendingImages = [];
    final picker = ImagePicker();

    bool isAvailable = room?['is_available'] ?? true;
    bool isSubmitting = false;
    final editingRoomId = isEditing ? room['id'] as int : null;


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24, left: 24, right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Edit Kamar' : 'Tambah Kamar Baru',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Kamar (Tipe)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    // ── Poin 4: Format harga otomatis (pemisah ribuan) ──────────
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_ThousandsSeparatorFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Harga / Bulan (Rp)',
                        hintText: 'cth: 1.200.000',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: facilitiesController,
                      decoration: const InputDecoration(labelText: 'Fasilitas (Pisahkan dgn koma)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: 'Kategori (Putra/Putri/Campur)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gambar Kamar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (serverImageUrls.isNotEmpty || pendingImages.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: serverImageUrls.length + pendingImages.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final isServerImage = idx < serverImageUrls.length;
                            final imageIndex = idx;
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: isServerImage
                                      ? Image.network(
                                          auth.resolveMediaUrl(serverImageUrls[idx]),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        )
                                      : Image.memory(
                                          pendingImages[idx - serverImageUrls.length],
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (isServerImage) {
                                        final url = serverImageUrls[imageIndex];
                                        if (editingRoomId != null &&
                                            url.startsWith('/uploads/')) {
                                          await auth.deleteRoomImage(editingRoomId, url);
                                        }
                                        setModalState(() {
                                          serverImageUrls.removeAt(imageIndex);
                                        });
                                      } else {
                                        setModalState(() {
                                          pendingImages.removeAt(
                                            imageIndex - serverImageUrls.length,
                                          );
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                                if (idx == 0)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Utama', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(child: Text('Belum ada gambar')),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await picker.pickMultiImage(imageQuality: 85);
                        if (picked.isEmpty) return;

                        // Tampilkan loading singkat selama re-encode berjalan
                        setModalState(() => isSubmitting = true);

                        final reencoded = <Uint8List>[];
                        for (final file in picked) {
                          final raw = await file.readAsBytes();
                          // Re-encode di isolate terpisah — bypass native ImageDecoder
                          final jpeg = await _reencodeToJpeg(raw);
                          if (jpeg != null) reencoded.add(jpeg);
                        }

                        setModalState(() {
                          isSubmitting = false;
                          pendingImages.addAll(reencoded);
                        });
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Pilih dari Galeri (bisa banyak)'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Tersedia (Available)'),
                      value: isAvailable,
                      onChanged: (val) => setModalState(() => isAvailable = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlack,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                        setModalState(() => isSubmitting = true);
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final rawPrice = priceController.text.replaceAll('.', '');
                        final data = {
                          'name': nameController.text,
                          'description': descController.text,
                          'price_per_month': double.tryParse(rawPrice) ?? 0.0,
                          'facilities': facilitiesController.text,
                          'room_type': typeController.text,
                          'image_url': serverImageUrls.isNotEmpty ? serverImageUrls.first : '',
                          'additional_images': serverImageUrls.length > 1
                              ? serverImageUrls.sublist(1).join(',')
                              : '',
                          'is_available': isAvailable,
                        };

                        bool success = false;
                        int? roomId;

                        if (isEditing) {
                          roomId = editingRoomId;
                          success = await auth.updateRoom(roomId!, data);
                        } else {
                          final created = await auth.createRoom(data);
                          if (created != null) {
                            roomId = created['id'] as int?;
                            success = roomId != null;
                          }
                        }

                        if (success && roomId != null && pendingImages.isNotEmpty) {
                          // pendingImages sudah berupa Uint8List JPEG bersih — langsung upload
                          final names = List.generate(
                            pendingImages.length,
                            (i) => 'room_${roomId}_$i.jpg',
                          );

                          final uploaded = await auth.uploadRoomImages(
                            roomId,
                            pendingImages,
                            filenames: names,
                          );

                          if (uploaded != null) {
                            final mainUrl = serverImageUrls.isNotEmpty
                                ? serverImageUrls.first
                                : '';
                            final finalUrls = mainUrl.isNotEmpty
                                ? [mainUrl, ...uploaded]
                                : uploaded;
                            success = await auth.syncRoomImageFields(roomId, finalUrls);
                          } else {
                            success = false;
                          }
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isEditing ? 'Kamar diubah!' : 'Kamar ditambahkan!')),
                            );
                            _loadRooms();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Terjadi kesalahan'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Simpan Perubahan' : 'Tambah Kamar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Kamar?'),
        content: Text('Kamar "$name" akan disembunyikan dari aplikasi (Soft delete). Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await Provider.of<AuthProvider>(context, listen: false).deleteRoom(id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamar dinonaktifkan')));
                _loadRooms();
              }
            },
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        title: const Text('Kelola Kamar', style: TextStyle(color: AppTheme.primaryBlack)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlack),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoomForm(),
        backgroundColor: AppTheme.primaryBlack,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRooms,
              color: AppTheme.primaryBlack,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _rooms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final room = _rooms[index];
                  final isAvailable = room['is_available'] ?? true;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            auth.resolveMediaUrl(room['image_url'] ?? ''),
                            width: 70, height: 70, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.meeting_room, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(room['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(formatRupiah(room['price_per_month']), style: const TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                                  style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showRoomForm(room: room),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(room['id'], room['name'] ?? ''),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
