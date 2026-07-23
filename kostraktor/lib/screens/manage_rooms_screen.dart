import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

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

  void _showRoomForm({Map<String, dynamic>? room}) {
    final isEditing = room != null;
    final nameController = TextEditingController(text: room?['name']);
    final descController = TextEditingController(text: room?['description']);

    // Format harga existing ke format ribuan saat edit
    final existingPrice = room?['price_per_month'];
    final initialPriceText = existingPrice != null
        ? NumberFormat('#,###', 'id_ID').format(existingPrice.toInt())
        : '';
    final priceController = TextEditingController(text: initialPriceText);

    final typeController = TextEditingController(text: room?['room_type'] ?? 'Standard');
    final facilitiesController = TextEditingController(text: room?['facilities']);
    // imageController tetap dipakai untuk menyimpan URL hasil upload / URL existing
    final imageController = TextEditingController(
      text: room?['image_url'] ?? '',
    );
    bool isAvailable = room?['is_available'] ?? true;
    XFile? pickedImage; // gambar yang dipilih dari galeri/kamera
    bool isUploading = false;

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
                    // ── Poin 5: Image Picker + Preview ─────────────────────────
                    const Text(
                      'Gambar Kamar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    // Preview area
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final source = await showModalBottomSheet<ImageSource>(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library_outlined),
                                  title: const Text('Pilih dari Galeri'),
                                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt_outlined),
                                  title: const Text('Ambil Foto'),
                                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (source == null) return;
                        final picked = await picker.pickImage(
                          source: source,
                          imageQuality: 80,
                        );
                        if (picked != null) {
                          setModalState(() {
                            pickedImage = picked;
                            isUploading = true;
                          });
                          // TODO: Upload gambar ke backend.
                          // Endpoint upload gambar untuk rooms BELUM TERSEDIA di backend.
                          // Perlu endpoint POST /rooms/upload-image atau sejenisnya.
                          // Setelah endpoint tersedia, lakukan:
                          //   final url = await auth.uploadRoomImage(picked);
                          //   imageController.text = url;
                          // Untuk sementara, placeholder URL kosong:
                          imageController.text = ''; // akan diisi setelah upload
                          setModalState(() => isUploading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Gambar dipilih. Upload endpoint belum tersedia — hubungi backend developer.',
                                ),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: pickedImage != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(File(pickedImage!.path), fit: BoxFit.cover),
                                    if (isUploading)
                                      const ColoredBox(
                                        color: Color(0x88000000),
                                        child: Center(
                                          child: CircularProgressIndicator(color: Colors.white),
                                        ),
                                      ),
                                  ],
                                )
                              : imageController.text.isNotEmpty
                                  ? Image.network(
                                      imageController.text,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                                    )
                                  : _imagePlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Fallback: juga bisa ketik URL manual
                    TextField(
                      controller: imageController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Atau ketik URL gambar manual',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
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
                      onPressed: () async {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        // Strip titik ribuan sebelum parse ke double
                        final rawPrice = priceController.text.replaceAll('.', '');
                        final data = {
                          'name': nameController.text,
                          'description': descController.text,
                          'price_per_month': double.tryParse(rawPrice) ?? 0.0,
                          'facilities': facilitiesController.text,
                          'room_type': typeController.text,
                          'image_url': imageController.text,
                          'is_available': isAvailable,
                        };

                        bool success;
                        if (isEditing) {
                          success = await auth.updateRoom(room['id'], data);
                        } else {
                          success = await auth.createRoom(data);
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
                      child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah Kamar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'Ketuk untuk pilih gambar',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ],
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                            room['image_url'] ?? '',
                            width: 70, height: 70, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.meeting_room, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(room['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Rp ${room['price_per_month']}', style: const TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.w600)),
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
