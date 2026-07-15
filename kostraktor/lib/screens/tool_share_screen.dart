
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';

class ToolShareScreen extends StatefulWidget {
  const ToolShareScreen({super.key});

  @override
  State<ToolShareScreen> createState() => _ToolShareScreenState();
}

class _ToolShareScreenState extends State<ToolShareScreen> {
  List<Map<String, dynamic>> _tools = [];
  bool _isLoading = true;

  final Map<String, IconData> _toolIcons = {
    'cleaning_services': Icons.cleaning_services_outlined,
    'straighten': Icons.straighten_outlined,
    'handyman': Icons.handyman_outlined,
    'shopping_cart': Icons.shopping_cart_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await auth.fetchTools();
    if (mounted) {
      setState(() {
        _tools = data;
        _isLoading = false;
      });
    }
  }

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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${_tools.where((t) => t['is_available'] == true).length} Tersedia',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTools,
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                      children: _tools
                          .map((tool) => _buildToolCardFromApi(context, tool))
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCardFromApi(BuildContext context, Map<String, dynamic> tool) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return GestureDetector(
      onTap: () async {
        final id = tool['id'];
        final isAvailable = tool['is_available'] == true;
        if (isAvailable) {
          try {
            await auth.borrowTool(id);
            await _loadTools();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${tool['name']} berhasil dipinjam!'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${tool['name']} sedang dipinjam penghuni lain.'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            }
          }
        } else {
          // Show return dialog
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Kembalikan Alat'),
              content: Text('Kembalikan ${tool['name']}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlack),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await auth.returnTool(id);
                    await _loadTools();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${tool['name']} berhasil dikembalikan.'),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));
                    }
                  },
                  child: const Text('Kembalikan', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      },
      child: _buildToolCard(
        context,
        tool['name'] ?? 'Unknown',
        tool['is_available'] == true,
        _toolIcons[tool['icon_name']] ?? Icons.handyman_outlined,
      ),
    );
  }

  Widget _buildToolCard(
      BuildContext context, String title, bool isAvailable, IconData icon) {
    return Container(
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
                ],
              ),
            ),
          ],
        ),
    );
  }
}
