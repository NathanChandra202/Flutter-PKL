import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

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
    final priceController = TextEditingController(text: room?['price_per_month']?.toString());
    final typeController = TextEditingController(text: room?['room_type'] ?? 'Standard');
    final facilitiesController = TextEditingController(text: room?['facilities']);
    final imageController = TextEditingController(text: room?['image_url'] ?? 'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png');
    bool isAvailable = room?['is_available'] ?? true;

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
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga / Bulan (Rp)', border: OutlineInputBorder()),
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
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: 'URL Gambar', border: OutlineInputBorder()),
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
                        final data = {
                          'name': nameController.text,
                          'description': descController.text,
                          'price_per_month': double.tryParse(priceController.text) ?? 0.0,
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
          : ListView.separated(
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
    );
  }
}
