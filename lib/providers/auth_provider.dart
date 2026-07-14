import 'package:flutter/foundation.dart';

/// Roles in the app
/// - [guest]           : browsing only, not logged in
/// - [calon]           : logged in, hasn't booked yet
/// - [pendingResident] : has submitted booking, waiting for admin confirmation
/// - [resident]        : confirmed active resident
/// - [admin]           : admin panel access
enum UserRole { guest, calon, pendingResident, resident, admin }

class Review {
  final String userName;
  final String userEmail;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? roomType;

  Review({
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.roomType,
  });
}

class BookingData {
  final String nama;
  final String phone;
  final String nik;
  final String roomType;
  final DateTime bookingTime;
  final DateTime? tanggalMulaiMenghuni; // NEW: Tanggal mulai menghuni
  bool waConfirmed; // user has sent WA to penjaga kos
  final String referensiTransaksi; // auto-generated reference number
  final Uint8List? ktpBytes;
  final Uint8List? selfieBytes;
  final Uint8List? buktiBayarBytes;

  BookingData({
    required this.nama,
    required this.phone,
    required this.nik,
    required this.roomType,
    required this.bookingTime,
    this.tanggalMulaiMenghuni,
    this.waConfirmed = false,
    String? referensiTransaksi,
    this.ktpBytes,
    this.selfieBytes,
    this.buktiBayarBytes,
  }) : referensiTransaksi = referensiTransaksi ?? _generateRef();

  static String _generateRef() {
    final now = DateTime.now();
    final ymd =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = (now.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'KST-$ymd-$rand';
  }
}

class PendingUser {
  final String email;
  final String name;
  final String phone;
  final BookingData bookingData;

  PendingUser({
    required this.email,
    required this.name,
    required this.phone,
    required this.bookingData,
  });
}

class AuthProvider extends ChangeNotifier {
  UserRole _currentRole = UserRole.guest;
  String? _userEmail;
  String? _userName;
  String? _userPhone;
  BookingData? _bookingData;
  String? _assignedRoom;

  // Simulated user database (for registration)
  final Map<String, Map<String, String>> _registeredUsers = {
    'calon@kostraktor.com': {
      'password': '123456',
      'name': 'Calon Penghuni',
      'phone': '08123456789',
      'role': 'calon',
    },
    'admin@kostraktor.com': {
      'password': 'admin123',
      'name': 'Admin Kostraktor',
      'phone': '081234567890',
      'role': 'admin',
    },
  };

  // Queue of users pending admin approval
  final List<PendingUser> _pendingApprovals = [];

  // Reviews storage (in-memory, real data from user submissions)
  final List<Review> _reviews = [
    // Dummy reviews untuk demonstrasi badge
    Review(
      userName: 'Ahmad Rizki',
      userEmail: 'ahmad@example.com',
      rating: 5.0,
      comment: 'Kost terbaik! Bersih, nyaman, dan pelayanan ramah.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      roomType: 'Tipe Premium',
    ),
    Review(
      userName: 'Siti Nurhaliza',
      userEmail: 'siti@example.com',
      rating: 5.0,
      comment: 'Fasilitasnya lengkap, WiFi cepat, kamar mandi bersih.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      roomType: 'Tipe Deluxe',
    ),
    Review(
      userName: 'Budi Santoso',
      userEmail: 'budi@example.com',
      rating: 4.5,
      comment: 'Lokasi strategis dekat dengan stasiun. Recommended!',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      roomType: 'Tipe Standard',
    ),
    Review(
      userName: 'Diana Putri',
      userEmail: 'diana@example.com',
      rating: 5.0,
      comment: 'Penjaga kost ramah, tempatnya aman dan nyaman.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      roomType: 'Tipe Premium',
    ),
    Review(
      userName: 'Eko Prasetyo',
      userEmail: 'eko@example.com',
      rating: 4.5,
      comment: 'Suasananya tenang, cocok untuk WFH.',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      roomType: 'Tipe Deluxe',
    ),
    Review(
      userName: 'Fitri Handayani',
      userEmail: 'fitri@example.com',
      rating: 5.0,
      comment: 'AC dingin, kasur empuk, parkir luas. Top!',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      roomType: 'Tipe Premium',
    ),
    Review(
      userName: 'Gani Kusuma',
      userEmail: 'gani@example.com',
      rating: 4.0,
      comment: 'Harga sesuai dengan fasilitas yang diberikan.',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      roomType: 'Tipe Standard',
    ),
    Review(
      userName: 'Hani Maulida',
      userEmail: 'hani@example.com',
      rating: 5.0,
      comment: 'Kamar luas, ventilasi bagus, keamanan 24 jam.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      roomType: 'Tipe Deluxe',
    ),
    Review(
      userName: 'Indra Gunawan',
      userEmail: 'indra@example.com',
      rating: 4.5,
      comment: 'Pelayanan cepat, maintenance rutin, sangat puas.',
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
      roomType: 'Tipe Premium',
    ),
    Review(
      userName: 'Julia Rahmawati',
      userEmail: 'julia@example.com',
      rating: 5.0,
      comment: 'Lingkungan bersih, tetangga friendly, suka banget!',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      roomType: 'Tipe Premium',
    ),
    Review(
      userName: 'Kevin Aditya',
      userEmail: 'kevin@example.com',
      rating: 4.5,
      comment: 'Dekat dengan fasilitas umum, akses mudah ke mana-mana.',
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
      roomType: 'Tipe Deluxe',
    ),
  ];

  // ─── Getters ──────────────────────────────────────────────────────────────

  UserRole get currentRole => _currentRole;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  BookingData? get bookingData => _bookingData;
  String? get assignedRoom => _assignedRoom;
  List<PendingUser> get pendingApprovals =>
      List.unmodifiable(_pendingApprovals);
  List<Review> get reviews => List.unmodifiable(_reviews);

  // Calculate average rating
  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );
    return total / _reviews.length;
  }

  // Get rating distribution
  Map<int, int> get ratingDistribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in _reviews) {
      dist[review.rating.round()] = (dist[review.rating.round()] ?? 0) + 1;
    }
    return dist;
  }

  bool get isLoggedIn => _currentRole != UserRole.guest;
  bool get isResident =>
      _currentRole == UserRole.resident || _currentRole == UserRole.admin;
  bool get isPendingResident => _currentRole == UserRole.pendingResident;
  bool get isCalonPenghuni => _currentRole == UserRole.calon;
  bool get isAdmin => _currentRole == UserRole.admin;

  // ─── Auth Actions ──────────────────────────────────────────────────────────

  /// Returns null on success, error message on failure
  String? login(String email, String password) {
    final trimmedEmail = email.trim().toLowerCase();
    final user = _registeredUsers[trimmedEmail];

    if (user == null) {
      return 'Email tidak terdaftar.';
    }
    if (user['password'] != password) {
      return 'Password salah.';
    }

    _userEmail = trimmedEmail;
    _userName = user['name'];
    _userPhone = user['phone'];
    _currentRole = _parseRole(user['role'] ?? 'calon');

    // Restore assigned room for residents
    if (_currentRole == UserRole.resident && user['room'] != null) {
      _assignedRoom = user['room'];
    }

    // Restore booking data if pending
    if (_currentRole == UserRole.pendingResident) {
      final pending = _pendingApprovals
          .where((p) => p.email == trimmedEmail)
          .firstOrNull;
      if (pending != null) {
        _bookingData = pending.bookingData;
      }
    }

    notifyListeners();
    return null; // success
  }

  /// Returns null on success, error message on failure
  String? register(String nama, String email, String phone, String password) {
    final trimmedEmail = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(trimmedEmail)) {
      return 'Email sudah terdaftar. Silakan masuk.';
    }
    if (nama.trim().isEmpty || phone.trim().isEmpty || password.length < 8) {
      return 'Pastikan semua data diisi dengan benar dan password minimal 8 karakter kombinasi huruf dan angka.';
    }

    // Register the new user
    _registeredUsers[trimmedEmail] = {
      'password': password,
      'name': nama.trim(),
      'phone': phone.trim(),
      'role': 'calon',
    };

    // Auto-login after registration
    _userEmail = trimmedEmail;
    _userName = nama.trim();
    _userPhone = phone.trim();
    _currentRole = UserRole.calon;
    notifyListeners();
    return null; // success
  }

  /// Called after booking form is submitted — upgrades status to pendingResident
  void submitBooking(BookingData data) {
    _bookingData = data;
    _currentRole = UserRole.pendingResident;

    // Update registered user role
    if (_userEmail != null) {
      _registeredUsers[_userEmail!]?['role'] = 'pendingResident';

      // Add to pending approvals queue (remove old entry if exists)
      _pendingApprovals.removeWhere((p) => p.email == _userEmail);
      _pendingApprovals.add(
        PendingUser(
          email: _userEmail!,
          name: _userName ?? data.nama,
          phone: _userPhone ?? data.phone,
          bookingData: data,
        ),
      );
    }
    notifyListeners();
  }

  /// Mark that user has sent WA confirmation to penjaga kos
  void markWaConfirmed() {
    _bookingData?.waConfirmed = true;
    notifyListeners();
  }

  /// Cancel booking — revert status back to calon
  void cancelBooking() {
    _currentRole = UserRole.calon;
    _bookingData = null;
    if (_userEmail != null) {
      _registeredUsers[_userEmail!]?['role'] = 'calon';
      _pendingApprovals.removeWhere((p) => p.email == _userEmail);
    }
    notifyListeners();
  }

  /// Called by admin to approve a pending user — upgrades them to full resident
  void adminApproveUser(String email, String roomNumber) {
    final userEntry = _registeredUsers[email];
    if (userEntry == null) return;

    userEntry['role'] = 'resident';
    userEntry['room'] = roomNumber;

    // Remove from pending queue
    _pendingApprovals.removeWhere((p) => p.email == email);

    // If the current logged-in user is the one being approved, upgrade in-session too
    if (_userEmail == email) {
      _currentRole = UserRole.resident;
      _assignedRoom = roomNumber;
    }

    notifyListeners();
  }

  /// Called by admin to reject a pending user — reverts them to calon
  void adminRejectUser(String email) {
    final userEntry = _registeredUsers[email];
    if (userEntry == null) return;

    userEntry['role'] = 'calon';
    userEntry.remove('room');

    // Remove from pending queue
    _pendingApprovals.removeWhere((p) => p.email == email);

    // If the current logged-in user is the one being rejected, revert in-session too
    if (_userEmail == email) {
      _currentRole = UserRole.calon;
      _bookingData = null;
    }

    notifyListeners();
  }

  void logout() {
    _currentRole = UserRole.guest;
    _userEmail = null;
    _userName = null;
    _userPhone = null;
    _bookingData = null;
    _assignedRoom = null;
    notifyListeners();
  }

  /// Submit a review (for residents and pending residents who have confirmed payment)
  String? submitReview({required double rating, required String comment}) {
    if (!isResident &&
        !(isPendingResident && _bookingData?.waConfirmed == true)) {
      return 'Hanya penghuni atau calon penghuni yang sudah konfirmasi pembayaran yang bisa memberikan review.';
    }
    if (comment.trim().isEmpty) {
      return 'Komentar tidak boleh kosong.';
    }
    if (rating < 1 || rating > 5) {
      return 'Rating harus antara 1-5 bintang.';
    }

    // Check if user already reviewed
    final existingReview = _reviews
        .where((r) => r.userEmail == _userEmail)
        .firstOrNull;
    if (existingReview != null) {
      return 'Anda sudah memberikan review sebelumnya.';
    }

    final review = Review(
      userName: _userName ?? 'Anonymous',
      userEmail: _userEmail!,
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
      roomType: _bookingData?.roomType,
    );

    _reviews.insert(0, review); // Add to beginning (newest first)
    notifyListeners();
    return null; // Success
  }

  UserRole _parseRole(String role) {
    switch (role) {
      case 'resident':
        return UserRole.resident;
      case 'admin':
        return UserRole.admin;
      case 'pendingResident':
        return UserRole.pendingResident;
      default:
        return UserRole.calon;
    }
  }
}
