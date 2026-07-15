import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'tool_share_screen.dart';

class _JastipItem {
  final String title;
  final String desc;
  final String author;
  final String harga;
  final String waNumber;
  final DateTime postedAt;

  _JastipItem({
    required this.title,
    required this.desc,
    required this.author,
    required this.harga,
    required this.waNumber,
    required this.postedAt,
  });
}

class JastipScreen extends StatefulWidget {
  const JastipScreen({super.key});

  @override
  State<JastipScreen> createState() => _JastipScreenState();
}

class _JastipScreenState extends State<JastipScreen> {
  final List<_JastipItem> _listings = [
    _JastipItem(
      title: 'Jastip Warmindo jam 10 malam',
      desc: 'Mumpung hujan, ongkir hanya Rp 2.000, slot terbatas 3 orang saja',
      author: 'Kamar 105',
      harga: 'Rp 2.000',
      waNumber: '6281234500105',
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _JastipItem(
      title: 'Jasa Pembersihan & Cuci Sneakers',
      desc: 'Premium deep clean selesai 1 hari',
      author: 'Kamar 202',
      harga: 'Rp 15.000',
      waNumber: '6281234500202',
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  void _addListing(_JastipItem item) {
    setState(() => _listings.insert(0, item));
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Komunitas & Jastip',
          style: TextStyle(
              color: AppTheme.primaryBlack, fontWeight: FontWeight.bold),
        ),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.blue.withOpacity(0.05),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notice Board Komunitas Kostraktor - Khusus Penghuni Aktif',
                    style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _listings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_outlined,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Belum ada listing jastip.',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 14)),
                        const SizedBox(height: 6),
                        const Text('Jadi yang pertama buka lapak!',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    itemCount: _listings.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final item = _listings[i];
                      return _buildJastipCard(
                        context,
                        item,
                        _timeAgo(item.postedAt),
                        auth,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'lapak',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _BukaLapakSheet(onSubmit: _addListing),
              );
            },
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryBlack,
            elevation: 2,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Buka Lapak Jastip',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'alat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ToolShareScreen()),
              );
            },
            backgroundColor: AppTheme.primaryBlack,
            icon: const Icon(Icons.handyman_outlined,
                color: Colors.white, size: 20),
            label: const Text('Peminjaman Alat',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildJastipCard(BuildContext context, _JastipItem item,
      String timeAgo, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(item.author,
                      style: const TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              Text(timeAgo,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 10)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final msg = Uri.encodeComponent(
                      'Halo, saya tertarik dengan jastip "${item.title}" yang kamu tawarkan. Apakah masih tersedia?');
                  final url = Uri.parse(
                      'https://wa.me/${item.waNumber}?text=$msg');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url,
                        mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Tidak dapat membuka WhatsApp.')),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF25D366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF25D366)
                            .withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 14, color: Color(0xFF1A8A4A)),
                      SizedBox(width: 4),
                      Text('Chat WA',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A8A4A))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.title,
              style: const TextStyle(
                  color: AppTheme.primaryBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(item.desc,
              style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.accentGold.withOpacity(0.4)),
                ),
                child: Text(item.harga,
                    style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              // Only the poster (or admin) can close their listing
              if (auth.isAdmin)
                GestureDetector(
                  onTap: () {
                    setState(() => _listings.remove(item));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Listing "${item.title}" dihapus.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.red.shade200),
                    ),
                    child: Text('Hapus',
                        style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Buka Lapak Bottom Sheet ───────────────────────────────────────────────

class _BukaLapakSheet extends StatefulWidget {
  final void Function(_JastipItem) onSubmit;
  const _BukaLapakSheet({required this.onSubmit});

  @override
  State<_BukaLapakSheet> createState() => _BukaLapakSheetState();
}

class _BukaLapakSheetState extends State<_BukaLapakSheet> {
  final _judulCtrl = TextEditingController();
  final _deskCtrl = TextEditingController();
  final _hargaCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _kamarCtrl = TextEditingController();

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskCtrl.dispose();
    _hargaCtrl.dispose();
    _waCtrl.dispose();
    _kamarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Buka Lapak Jastip',
                  style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 4),
              const Text('Isi semua detail untuk ditampilkan di board komunitas.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              _field(_judulCtrl, 'Judul Jastip (cth: Jastip Warmindo)',
                  Icons.storefront_outlined),
              const SizedBox(height: 12),
              _field(_deskCtrl, 'Deskripsi singkat layanan',
                  Icons.description_outlined,
                  maxLines: 3),
              const SizedBox(height: 12),
              _field(_hargaCtrl, 'Harga / tarif (cth: Rp 2.000)',
                  Icons.payments_outlined),
              const SizedBox(height: 12),
              _field(_kamarCtrl, 'Nomor Kamar (cth: Kamar 101)',
                  Icons.door_sliding_outlined),
              const SizedBox(height: 12),
              _field(_waCtrl, 'Nomor WhatsApp (cth: 6281234567890)',
                  Icons.phone_outlined,
                  isNumber: true),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final judul = _judulCtrl.text.trim();
                  final desk = _deskCtrl.text.trim();
                  final harga = _hargaCtrl.text.trim();
                  final kamar = _kamarCtrl.text.trim();
                  final wa = _waCtrl.text.trim();

                  if (judul.isEmpty ||
                      desk.isEmpty ||
                      harga.isEmpty ||
                      kamar.isEmpty ||
                      wa.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Semua field wajib diisi.'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    return;
                  }

                  final newItem = _JastipItem(
                    title: judul,
                    desc: desk,
                    author: kamar,
                    harga: harga,
                    waNumber: wa,
                    postedAt: DateTime.now(),
                  );

                  Navigator.pop(context);
                  widget.onSubmit(newItem);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Lapak jastip berhasil dibuka!'),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: const Text('Buka Lapak Sekarang',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: AppTheme.textMuted, size: 20)
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppTheme.primaryBlack, width: 1.5)),
      ),
    );
  }
}
