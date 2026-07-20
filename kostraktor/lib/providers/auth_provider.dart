import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Roles in the app
/// - [guest]           : browsing only, not logged in
/// - [calon]           : logged in, hasn't booked yet
/// - [pendingResident] : has submitted booking, waiting for admin confirmation
/// - [resident]        : confirmed active resident
/// - [admin]           : admin panel access
enum UserRole { guest, calon, pendingResident, resident, admin }

/// Tracks all unique codes currently in use across the app session.
/// Guarantees no two active bookings share the same 3-digit code.
final Set<int> _usedUniqueCodes = {};

/// Generates a guaranteed-unique 3-digit code (100–999).
/// Retries on collision — worst case O(n) but collision rate is negligible
/// at kos scale (max ~900 concurrent bookings before exhaustion).
int generateUniquePaymentCode() {
  final rng = Random.secure();
  int code;
  int attempts = 0;
  do {
    code = rng.nextInt(900) + 100; // always 3 digits: 100–999
    attempts++;
    // Safety valve: if somehow exhausted (>900 active bookings), expand to 4 digits
    if (attempts > 1800) {
      code = rng.nextInt(9000) + 1000;
      if (!_usedUniqueCodes.contains(code)) break;
    }
  } while (_usedUniqueCodes.contains(code));

  _usedUniqueCodes.add(code);
  return code;
}

/// Release a code when booking is cancelled/expired/approved so it can be reused.
void releaseUniquePaymentCode(int code) {
  _usedUniqueCodes.remove(code);
}

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
  final DateTime? tanggalMulaiMenghuni; // Tanggal mulai menghuni
  bool waConfirmed; // user has sent WA to penjaga kos
  final String referensiTransaksi; // auto-generated reference number
  final int uniquePaymentCode; // guaranteed unique 3-digit code
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
    int? uniquePaymentCode,
    this.ktpBytes,
    this.selfieBytes,
    this.buktiBayarBytes,
  }) : referensiTransaksi = referensiTransaksi ?? _generateRef(),
       uniquePaymentCode = uniquePaymentCode ?? generateUniquePaymentCode();

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
  final int? id;
  final String email;
  final String name;
  final String phone;
  final BookingData bookingData;

  PendingUser({
    this.id,
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
  String? _accessToken;

  // PENTING: Sesuaikan URL backend berikut:
  //   - Emulator Android       : gunakan 10.0.2.2  (alias ke 127.0.0.1 PC)
  //   - Device fisik (HP nyata): gunakan IP lokal PC, cth: 192.168.101.15
  //   - Web/Desktop Flutter    : gunakan 127.0.0.1
  // SYARAT device fisik: HP & PC harus konek ke WiFi yang SAMA!
  static const String _baseUrl = 'http://192.168.101.15:8000/api/v1';

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
  Future<String?> login(String email, String password) async {
    final trimmedEmail = email.trim().toLowerCase();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': trimmedEmail, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];

        // Fetch user profile
        final profileResponse = await http.get(
          Uri.parse('$_baseUrl/auth/me'),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );

        if (profileResponse.statusCode == 200) {
          final profile = json.decode(profileResponse.body);
          _userEmail = profile['email'];
          _userName = profile['nama_lengkap'];
          _currentRole = _parseRole(profile['role'] ?? 'Customer');

          // --- LOCAL OVERRIDE ---
          // Since the backend doesn't fully support room assignment yet,
          // apply the local upgrade if they were approved by the admin locally.
          if (_registeredUsers.containsKey(_userEmail)) {
            final localRole = _registeredUsers[_userEmail!]?['role'];
            if (localRole != null && localRole != 'calon') {
              _currentRole = _parseRole(localRole);
            }
            _assignedRoom = _registeredUsers[_userEmail!]?['room'] as String?;
          } else {
            // Ensure they exist in local cache
            _registeredUsers[_userEmail!] = {
              'password': password,
              'nama': _userName ?? '',
              'role': _currentRole == UserRole.admin ? 'admin' : 'calon',
            };
          }

          notifyListeners();
          return null; // success
        } else {
          return 'Gagal memuat profil pengguna.';
        }
      } else {
        final error = json.decode(response.body);
        return error['detail'] ?? 'Email atau password salah.';
      }
    } catch (e) {
      return 'Terjadi kesalahan koneksi. Pastikan server backend menyala.';
    }
  }

  /// Returns null on success, error message on failure
  Future<String?> register(
    String nama,
    String email,
    String phone,
    String password,
  ) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (nama.trim().isEmpty || phone.trim().isEmpty || password.length < 8) {
      return 'Pastikan semua data diisi dengan benar dan password minimal 8 karakter kombinasi huruf dan angka.';
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': trimmedEmail,
          'password': password,
          'nama_lengkap': nama.trim(),
          'nik': '', // NIK will be updated later when taking KTP
          'role_name': 'Customer',
        }),
      );

      if (response.statusCode == 200) {
        // Auto-login after registration
        return await login(trimmedEmail, password);
      } else {
        final error = json.decode(response.body);
        return error['detail'] ?? 'Gagal mendaftar.';
      }
    } catch (e) {
      return 'Terjadi kesalahan koneksi. Pastikan server backend menyala.';
    }
  }

  /// Called after booking form is submitted — upgrades status to pendingResident
  Future<void> submitBooking(BookingData data) async {
    _bookingData = data;
    _currentRole = UserRole.pendingResident;

    if (_accessToken != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/bookings'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
          body: json.encode({
            'room_name': data.roomType,
            'start_date':
                data.tanggalMulaiMenghuni?.toIso8601String() ??
                DateTime.now().toIso8601String(),
          }),
        );
      } catch (e) {
        // Fallback for offline mode
        print('Error submitting booking: $e');
      }
    }

    // Always add to local pending approvals queue so Admin can see the full data
    // (including images which aren't saved to the backend)
    final emailForQueue =
        _userEmail ??
        'guest_${DateTime.now().millisecondsSinceEpoch}@example.com';
    _pendingApprovals.removeWhere(
      (p) => p.email == emailForQueue || p.name == data.nama,
    );
    _pendingApprovals.add(
      PendingUser(
        email: emailForQueue,
        name: _userName ?? data.nama,
        phone: _userPhone ?? data.phone,
        bookingData: data,
      ),
    );

    notifyListeners();
  }

  Future<void> loadPendingBookings() async {
    // We intentionally do not wipe _pendingApprovals and fetch from backend here
    // because the backend does not store the KTP/Selfie/Payment bytes yet.
    // The local memory list contains the full data needed for the Admin panel.
    notifyListeners();
  }

  Future<bool> updateBookingStatus(int bookingId, String status) async {
    if (_accessToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bookings/$bookingId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  // ─── Jastip API ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchJastipListings() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/jastip/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching jastip: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> createJastipListing({
    required String title,
    required String description,
    required String price,
    required String waNumber,
  }) async {
    if (_accessToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/jastip/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'price': price,
          'wa_number': waNumber,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error creating jastip: $e');
    }
    return null;
  }

  Future<bool> deleteJastipListing(int listingId) async {
    if (_accessToken == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/jastip/$listingId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting jastip: $e');
      return false;
    }
  }

  // ─── Rooms API ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchRooms({bool all = false}) async {
    try {
      final url = all ? '$_baseUrl/rooms/?all=true' : '$_baseUrl/rooms/';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching rooms: $e');
    }
    return [];
  }

  Future<bool> createRoom(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rooms/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating room: $e');
      return false;
    }
  }

  Future<bool> updateRoom(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/rooms/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating room: $e');
      return false;
    }
  }

  Future<bool> deleteRoom(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/rooms/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting room: $e');
      return false;
    }
  }

  // ─── Tools API ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchTools() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/tools/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching tools: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> borrowTool(int toolId) async {
    if (_accessToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tools/$toolId/borrow'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) return json.decode(response.body);
      if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['detail']);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<Map<String, dynamic>?> returnTool(int toolId) async {
    if (_accessToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tools/$toolId/return'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      print('Error returning tool: $e');
    }
    return null;
  }

  // ─── My Bookings History ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchMyBookings() async {
    if (_accessToken == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bookings/me'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching my bookings: $e');
    }
    return [];
  }

  /// Mark that user has sent WA confirmation to penjaga kos
  void markWaConfirmed() {
    _bookingData?.waConfirmed = true;
    notifyListeners();
  }

  /// Save bukti bayar + referensi transaksi to the active booking data
  /// and sync back to the pending approvals queue so admin can see it.
  void updateBuktiBayar({
    required Uint8List buktiBayarBytes,
    required String referensiTransaksi,
  }) {
    if (_bookingData == null) return;

    // Replace BookingData with updated copy containing bukti bayar
    _bookingData = BookingData(
      nama: _bookingData!.nama,
      phone: _bookingData!.phone,
      nik: _bookingData!.nik,
      roomType: _bookingData!.roomType,
      bookingTime: _bookingData!.bookingTime,
      tanggalMulaiMenghuni: _bookingData!.tanggalMulaiMenghuni,
      waConfirmed: true,
      referensiTransaksi: referensiTransaksi,
      uniquePaymentCode: _bookingData!.uniquePaymentCode,
      ktpBytes: _bookingData!.ktpBytes,
      selfieBytes: _bookingData!.selfieBytes,
      buktiBayarBytes: buktiBayarBytes,
    );

    // Sync back to the pending approvals queue so admin sees the latest data
    if (_userEmail != null) {
      final idx = _pendingApprovals.indexWhere((p) => p.email == _userEmail);
      if (idx != -1) {
        _pendingApprovals[idx] = PendingUser(
          email: _pendingApprovals[idx].email,
          name: _pendingApprovals[idx].name,
          phone: _pendingApprovals[idx].phone,
          bookingData: _bookingData!,
        );
      }
    }

    notifyListeners();
  }

  /// Cancel booking — revert status back to calon
  void cancelBooking() {
    // Release the unique code back to the pool so it can be reused
    if (_bookingData != null) {
      releaseUniquePaymentCode(_bookingData!.uniquePaymentCode);
    }
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

    // Release the unique code — booking is now complete, code can be reused
    final pending = _pendingApprovals
        .where((p) => p.email == email)
        .firstOrNull;
    if (pending != null) {
      releaseUniquePaymentCode(pending.bookingData.uniquePaymentCode);
    }

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

    // Release the unique code back to the pool
    final pending = _pendingApprovals
        .where((p) => p.email == email)
        .firstOrNull;
    if (pending != null) {
      releaseUniquePaymentCode(pending.bookingData.uniquePaymentCode);
    }

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

  /// Check out — reverts an active resident back to calon status
  void checkOut() {
    // Release the unique payment code back to the pool if there's an active booking
    if (_bookingData != null) {
      releaseUniquePaymentCode(_bookingData!.uniquePaymentCode);
    }
    _currentRole = UserRole.calon;
    _bookingData = null;
    _assignedRoom = null;
    if (_userEmail != null) {
      _registeredUsers[_userEmail!]?['role'] = 'calon';
      _registeredUsers[_userEmail!]?.remove('room');
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

  /// Verifies face match between KTP and Selfie using FastAPI backend
  Future<String?> verifyFaceMatch(
    Uint8List ktpBytes,
    Uint8List selfieBytes,
  ) async {
    if (_accessToken == null) return 'Anda harus login terlebih dahulu.';

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/verify/face-match'),
      );
      request.headers['Authorization'] = 'Bearer $_accessToken';

      request.files.add(
        http.MultipartFile.fromBytes(
          'ktp_image',
          ktpBytes,
          filename: 'ktp.jpg',
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'selfie_image',
          selfieBytes,
          filename: 'selfie.jpg',
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return null; // success
        } else {
          return data['message'] ?? 'Wajah tidak cocok atau KTP tidak terbaca.';
        }
      } else {
        try {
          final data = json.decode(response.body);
          return data['message'] ??
              data['detail'] ??
              'Gagal melakukan verifikasi wajah di server.';
        } catch (_) {
          return 'Gagal melakukan verifikasi wajah di server.';
        }
      }
    } catch (e) {
      return 'Terjadi kesalahan koneksi saat verifikasi wajah.';
    }
  }

  UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'resident':
        return UserRole.resident;
      case 'admin':
        return UserRole.admin;
      case 'pendingresident':
        return UserRole.pendingResident;
      default:
        return UserRole.calon;
    }
  }
}
