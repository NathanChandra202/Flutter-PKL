import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ToolShareScreen extends StatelessWidget {
  const ToolShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Peminjaman Alat', style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'Alat Tersedia',
              style: TextStyle(color: AppTheme.primaryBlack, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildToolCard(context, 'Vacuum Cleaner', true, Icons.cleaning_services_outlined),
                _buildToolCard(context, 'Tangga Lipat', false, Icons.kitchen_outlined),
                _buildToolCard(context, 'Bor Listrik', true, Icons.handyman_outlined),
                _buildToolCard(context, 'Troli Galon', true, Icons.shopping_cart_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String title, bool isAvailable, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          _showScanPopup(context, title);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Icon(icon, size: 48, color: Colors.grey.shade400),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlack), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: isAvailable ? Colors.green.shade200 : Colors.grey.shade300),
                    ),
                    child: Text(
                      isAvailable ? 'Tersedia' : 'Dipinjam',
                      style: TextStyle(
                        color: isAvailable ? Colors.green.shade700 : Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScanPopup(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Scan Alat (Mock)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack,
                          fontSize: 18)),
                  const SizedBox(height: 14),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '[ Kamera Terbuka ]\nScan kondisi barang sebelum dipinjam',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Pinjam Sekarang',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
