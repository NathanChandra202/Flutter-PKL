import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'booking_form_screen.dart';
import 'login_screen.dart';

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic>? unitData;
  const DetailScreen({super.key, this.unitData});

  // Fungsi untuk membuka WhatsApp
  Future<void> _openWhatsApp(BuildContext context) async {
    const phoneNumber = '6281234567890'; // Ganti dengan nomor admin
    const message =
        'Halo Admin Kostraktor, saya ingin bertanya tentang sewa kamar.';
    final url = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final title = unitData?['title'] ?? 'Tipe Premium'; 
    final price = unitData?['price'] ?? 'Rp 1.800.000';
    final imageUrl =
        unitData?['image'] ??
        'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png';
    final features =
        (unitData?['features'] as List<dynamic>?) ??
        ['Kamar Tidur', 'Kamar Mandi', 'WiFi', 'AC'];

    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: CustomScrollView(
        slivers: [
          // ─── SliverAppBar (hero image) ───
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryBlack,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.primaryBlack,
                    size: 20,
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  tooltip: 'Bagikan',
                  onPressed: () => _showShareSheet(context, title, price),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey.shade200),
                  ),
                  // Bottom gradient so title is legible
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Content ───
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title + Price
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppTheme.primaryBlack,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: const [
                                Icon(
                                  Icons.location_on,
                                  color: AppTheme.accentGold,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Pasar Rebo, Jakarta Timur',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.accentGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          price,
                          style: const TextStyle(
                            color: AppTheme.primaryBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const _Divider(),

                // About Section
                const _SectionTitle('Tentang Hunian'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    'Kostraktor menghadirkan hunian kost premium dengan fasilitas lengkap dan kualitas konstruksi terbaik. Setiap kamar dirancang dengan ventilasi silang alami, kedap suara, dan bebas banjir. Cocok untuk mahasiswa dan pekerja muda Jakarta Timur.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const _Divider(),

                // Facilities
                const _SectionTitle('Fasilitas'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: features
                        .map<Widget>((f) => _FacilityBadge(label: f.toString()))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 24),
                const _Divider(),

                // Pricing breakdown
                const _SectionTitle('Rincian Biaya'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PriceBox(label: 'Sewa / Bulan', value: price),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _PriceBox(
                          label: 'Deposit Awal',
                          value: 'Rp 1.000.000',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const _Divider(),

                // Lokasi & Transportasi
                const _SectionTitle('Lokasi & Transportasi'),
                const _LocationTransportSection(),

                const SizedBox(height: 24),
                const _Divider(),

                // Rating & Reviews Section
                const _SectionTitle('Rating & Ulasan'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      final reviews = auth.reviews;
                      final avgRating = auth.averageRating;
                      final distribution = auth.ratingDistribution;
                      final totalReviews = reviews.length;

                      return Column(
                        children: [
                          // Rating Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: totalReviews > 0
                                ? Row(
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            avgRating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: AppTheme.primaryBlack,
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          RatingBarIndicator(
                                            rating: avgRating,
                                            itemBuilder: (context, index) =>
                                                const Icon(
                                                  Icons.star,
                                                  color: AppTheme.accentGold,
                                                ),
                                            itemCount: 5,
                                            itemSize: 20.0,
                                            direction: Axis.horizontal,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$totalReviews ulasan',
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _RatingBar(
                                              stars: 5,
                                              percentage: totalReviews > 0
                                                  ? distribution[5]! /
                                                        totalReviews
                                                  : 0,
                                            ),
                                            _RatingBar(
                                              stars: 4,
                                              percentage: totalReviews > 0
                                                  ? distribution[4]! /
                                                        totalReviews
                                                  : 0,
                                            ),
                                            _RatingBar(
                                              stars: 3,
                                              percentage: totalReviews > 0
                                                  ? distribution[3]! /
                                                        totalReviews
                                                  : 0,
                                            ),
                                            _RatingBar(
                                              stars: 2,
                                              percentage: totalReviews > 0
                                                  ? distribution[2]! /
                                                        totalReviews
                                                  : 0,
                                            ),
                                            _RatingBar(
                                              stars: 1,
                                              percentage: totalReviews > 0
                                                  ? distribution[1]! /
                                                        totalReviews
                                                  : 0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 48,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Belum ada ulasan',
                                          style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Add Review Button (for residents and pending residents who have paid)
                          if (auth.isResident ||
                              (auth.isPendingResident &&
                                  auth.bookingData?.waConfirmed == true)) ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppTheme.primaryBlack,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 24,
                                  ),
                                ),
                                onPressed: () => _showReviewDialog(context),
                                icon: const Icon(
                                  Icons.rate_review,
                                  color: AppTheme.primaryBlack,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Tulis Ulasan',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlack,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else if (auth.isLoggedIn && !auth.isResident) ...[
                            // Info untuk user yang belum bisa review
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      auth.isPendingResident
                                          ? 'Selesaikan pembayaran untuk bisa memberikan ulasan'
                                          : 'Sewa kamar terlebih dahulu untuk bisa memberikan ulasan',
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Display Reviews
                          if (reviews.isNotEmpty) ...[
                            ...reviews.map(
                              (review) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ReviewCard(
                                  name: review.userName,
                                  rating: review.rating,
                                  date: _formatReviewDate(review.createdAt),
                                  comment: review.comment,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 120), // space for FAB
              ],
            ),
          ),
        ],
      ),

      // ─── Book Now FAB ───
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol Tanya Admin via WhatsApp
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF25D366), width: 2),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _openWhatsApp(context),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF25D366),
                  size: 20,
                ),
                label: const Text(
                  'Tanya Admin via WhatsApp',
                  style: TextStyle(
                    color: Color(0xFF25D366),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Tombol Ajukan Sewa
            SizedBox(
              width: double.infinity,
              child: Builder(
                builder: (ctx) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black38,
                    ),
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(
                        ctx,
                        listen: false,
                      );
                      if (!auth.isLoggedIn) {
                        _showLoginPrompt(ctx);
                      } else {
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingFormScreen(unitData: unitData),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Ajukan Sewa Sekarang',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Baru saja';
        }
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  void _showReviewDialog(BuildContext context) {
    double rating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlack,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.rate_review,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tulis Ulasan',
                          style: TextStyle(
                            color: AppTheme.primaryBlack,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Berikan Rating',
                    style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: RatingBar.builder(
                      initialRating: 0,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: 40,
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: AppTheme.accentGold),
                      onRatingUpdate: (newRating) {
                        setState(() => rating = newRating);
                      },
                    ),
                  ),
                  if (rating > 0) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '${rating.toInt()} bintang',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Ceritakan Pengalaman Anda',
                    style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText:
                          'Bagaimana pengalaman Anda tinggal di Kostraktor? Ceritakan tentang fasilitas, kebersihan, keamanan, dll.',
                      hintStyle: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlack,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            commentController.dispose();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlack,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (rating == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pilih rating terlebih dahulu'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            final comment = commentController.text.trim();
                            if (comment.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tulis komentar terlebih dahulu',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            final auth = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final error = auth.submitReview(
                              rating: rating,
                              comment: comment,
                            );

                            commentController.dispose();
                            Navigator.pop(context);

                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Terima kasih atas ulasan Anda!',
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Kirim Ulasan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: AppTheme.bgWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlack,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Login Dulu',
                  style: TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Untuk mengajukan sewa, masuk atau buat akun dulu. Gratis dan cepat!',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Masuk / Daftar Akun',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Lanjut Lihat-lihat Dulu',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Share Sheet ──────────────────────────────────────────────────────────
  void _showShareSheet(BuildContext context, String title, String price) {
    final shareText =
        'Cek hunian $title di Kostraktor!\n'
        'Lokasi: Jl. H. Hasan No.36, Pasar Rebo, Jakarta Timur\n'
        'Harga: $price/bulan\n\n'
        'Kostraktor - Hunian Premium Jakarta Timur';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bagikan Hunian',
                  style: TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 20),
                _shareOption(
                  context,
                  icon: Icons.copy_outlined,
                  color: Colors.blueGrey,
                  label: 'Salin Teks',
                  subtitle: 'Salin info hunian ke clipboard',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: shareText));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Teks berhasil disalin!')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                _shareOption(
                  context,
                  icon: Icons.chat_outlined,
                  color: Colors.green,
                  label: 'Bagikan via WhatsApp',
                  subtitle: 'Buka WhatsApp dengan pesan siap kirim',
                  onTap: () async {
                    final encoded = Uri.encodeComponent(shareText);
                    final uri = Uri.parse('https://wa.me/?text=$encoded');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                _shareOption(
                  context,
                  icon: Icons.share_outlined,
                  color: AppTheme.accentGold,
                  label: 'Bagikan ke Aplikasi Lain',
                  subtitle: 'Gunakan menu berbagi sistem',
                  onTap: () async {
                    Navigator.pop(context);
                    await Share.share(shareText,
                        subject: 'Hunian $title - Kostraktor');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shareOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.primaryBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Divider(
    color: Colors.grey.shade200,
    thickness: 1,
    indent: 24,
    endIndent: 24,
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    child: Text(
      text,
      style: const TextStyle(
        color: AppTheme.primaryBlack,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _FacilityBadge extends StatelessWidget {
  final String label;
  const _FacilityBadge({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label,
      style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 13),
    ),
  );
}

class _PriceBox extends StatelessWidget {
  final String label, value;
  const _PriceBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}

class _RatingBar extends StatelessWidget {
  final int stars;
  final double percentage;
  const _RatingBar({required this.stars, required this.percentage});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(
          '$stars',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: AppTheme.accentGold, size: 12),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.accentGold,
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(percentage * 100).toInt()}%',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final double rating;
  final String date;
  final String comment;

  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.date,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: rating,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: AppTheme.accentGold),
                        itemCount: 5,
                        itemSize: 12.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          comment,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

// ─── Lokasi & Transportasi ────────────────────────────────────────────────────

class _LocationTransportSection extends StatelessWidget {
  const _LocationTransportSection();

  static const _address =
      'Jl. H. Hasan No.36, RT.2/RW.9, Pasar Rebo, Jakarta Timur 13780';
  static const _lat = -6.3141;
  static const _lng = 106.8710;

  static const _transports = [
    _TransportInfo(
      icon: Icons.directions_walk,
      color: Colors.teal,
      mode: 'Jalan Kaki',
      distance: '± 0.5 km dari Halte Pasar Rebo',
      duration: '~7 menit',
      note: 'Dari Halte TransJakarta Pasar Rebo',
      mapsMode: 'walking',
    ),
    _TransportInfo(
      icon: Icons.directions_bike,
      color: Colors.green,
      mode: 'Motor / Ojol',
      distance: '± 8 km dari Pusat Jakarta',
      duration: '~20–35 menit',
      note: 'Gojek / Grab tersedia di area ini',
      mapsMode: 'driving',
    ),
    _TransportInfo(
      icon: Icons.directions_car,
      color: Colors.blue,
      mode: 'Mobil',
      distance: '± 8 km dari Pusat Jakarta',
      duration: '~25–45 menit',
      note: 'Akses via Jl. Raya Bogor & TB Simatupang',
      mapsMode: 'driving',
    ),
    _TransportInfo(
      icon: Icons.directions_bus,
      color: Colors.orange,
      mode: 'TransJakarta',
      distance: 'Koridor 7 / 7C',
      duration: '~30–50 menit dari Harmoni',
      note: 'Turun Halte Pasar Rebo, jalan ± 500m',
      mapsMode: 'transit',
    ),
    _TransportInfo(
      icon: Icons.train,
      color: Colors.purple,
      mode: 'KRL Commuter Line',
      distance: '± 4 km dari Stasiun Pasar Minggu',
      duration: '~10 menit ojol dari stasiun',
      note: 'Stasiun Pasar Minggu → ojol ke lokasi',
      mapsMode: 'transit',
    ),
  ];

  Future<void> _openMaps(BuildContext context, String mode) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$_lat,$_lng&travelmode=$mode',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
      );
    }
  }

  Future<void> _openPinpoint(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_lat,$_lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Alamat ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Icon(Icons.location_on,
                          color: Colors.red.shade600, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alamat Lengkap',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(_address,
                              style: TextStyle(
                                  color: AppTheme.primaryBlack,
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Lihat di Google Maps',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _openPinpoint(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text('Pilihan Transportasi',
              style: TextStyle(
                  color: AppTheme.primaryBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Ketuk untuk navigasi di Google Maps',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 12),

          // ── List transportasi ──
          ..._transports.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => _openMaps(context, t.mapsMode),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: t.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: t.color.withValues(alpha: 0.3)),
                          ),
                          child: Icon(t.icon, color: t.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.mode,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppTheme.primaryBlack,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(t.distance,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: t.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              Text(t.note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                      height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: t.color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(t.duration,
                                    maxLines: 2,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                        color: t.color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(Icons.open_in_new,
                                size: 13, color: Colors.grey.shade400),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _TransportInfo {
  final IconData icon;
  final Color color;
  final String mode;
  final String distance;
  final String duration;
  final String note;
  final String mapsMode;

  const _TransportInfo({
    required this.icon,
    required this.color,
    required this.mode,
    required this.distance,
    required this.duration,
    required this.note,
    required this.mapsMode,
  });
}
