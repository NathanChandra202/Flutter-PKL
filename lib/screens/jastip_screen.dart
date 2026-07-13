import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'tool_share_screen.dart'; 

class JastipScreen extends StatelessWidget {
  const JastipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Komunitas & Jastip', style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.blue.withOpacity(0.05),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notice Board Komunitas Kostraktor - Khusus Penghuni Aktif',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _buildJastipCard(
                  context,
                  'Jastip Warmindo jam 10 malam',
                  'Mumpung hujan, ongkir hanya Rp 2.000, slot terbatas 3 orang saja',
                  'Kamar 105',
                ),
                const SizedBox(height: 16),
                _buildJastipCard(
                  context,
                  'Jasa Pembersihan & Cuci Sneakers',
                  'Premium deep clean Rp 15.000 saja selesai 1 hari',
                  'Kamar 202',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ToolShareScreen()),
          );
        },
        backgroundColor: AppTheme.primaryBlack,
        icon: const Icon(Icons.handyman_outlined, color: Colors.white, size: 20),
        label: const Text('Peminjaman Alat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildJastipCard(BuildContext context, String title, String desc, String author) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(author,
                      style: const TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.primaryBlack),
                    SizedBox(width: 4),
                    Text('Chat WA',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
