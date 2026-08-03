import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_env.dart';

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

  // Override manual: --dart-define=API_BASE_URL=http://...
  // Emulator Android (dev lokal): http://10.0.2.2:8000/api/v1
  // Web/Desktop Flutter (dev lokal): http://127.0.0.1:8000/api/v1
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _devDefaultBaseUrl =
      'https://dev-api-kostraktor.duaenam.id/api/v1';

  // Sementara sama dengan dev; ganti saat URL prod terpisah tersedia.
  static const String _prodDefaultBaseUrl =
      'https://dev-api-kostraktor.duaenam.id/api/v1';

  static String get _baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    return AppEnv.isProd ? _prodDefaultBaseUrl : _devDefaultBaseUrl;
  }

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

  // Reviews storage — populated from backend via fetchReviews()
  final List<Review> _reviews = [];

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

          // --- RESTORE BOOKING DATA ---
          final pending = _pendingApprovals
              .where((p) => p.email == _userEmail)
              .firstOrNull;
          if (pending != null) {
            _bookingData = pending.bookingData;
            _currentRole = UserRole.pendingResident;
            _registeredUsers[_userEmail!]?['role'] = 'pendingResident';
          }

          notifyListeners();
          return null; // success
        } else {
          final errData = json.decode(profileResponse.body);
          return errData['detail'] ?? 'Gagal mengambil profil';
        }
      } else {
        final data = json.decode(response.body);
        return data['detail'] ?? 'Kredensial salah atau pengguna tidak aktif';
      }
    } catch (e) {
      // If backend connection fails, try local login as fallback
      debugPrint('Backend login failed: $e');

      // Try local login
      final user = _registeredUsers[trimmedEmail];
      if (user == null) {
        return 'Server tidak dapat dijangkau. Email tidak terdaftar dalam cache lokal.';
      }
      if (user['password'] != password) {
        return 'Server tidak dapat dijangkau. Password salah untuk cache lokal.';
      }

      // Local login success
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
      return null; // success with local fallback
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '926017391118-jiamtuuvigpkcat4gj83bv1pqqq21e6d.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return 'Pilih akun dibatalkan';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return 'Gagal mendapatkan token Google';
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
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
          if (_registeredUsers.containsKey(_userEmail)) {
            final localRole = _registeredUsers[_userEmail!]?['role'];
            if (localRole != null && localRole != 'calon') {
              _currentRole = _parseRole(localRole);
            }
            _assignedRoom = _registeredUsers[_userEmail!]?['room'] as String?;
          } else {
            // Ensure they exist in local cache
            _registeredUsers[_userEmail!] = {
              'password': '',
              'nama': _userName ?? '',
              'role': _currentRole == UserRole.admin ? 'admin' : 'calon',
            };
          }

          // --- RESTORE BOOKING DATA ---
          final pending = _pendingApprovals
              .where((p) => p.email == _userEmail)
              .firstOrNull;
          if (pending != null) {
            _bookingData = pending.bookingData;
            _currentRole = UserRole.pendingResident;
            _registeredUsers[_userEmail!]?['role'] = 'pendingResident';
          }

          notifyListeners();
          return null; // success
        } else {
          final errData = json.decode(profileResponse.body);
          return errData['detail'] ?? 'Gagal mengambil profil';
        }
      } else {
        final data = json.decode(response.body);
        return data['detail'] ?? 'Gagal verifikasi token Google';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
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
  Future<String?> submitBooking(BookingData data) async {
    if (_accessToken == null) return 'Sesi telah berakhir, silakan login kembali.';

    int? bookingId;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bookings/'),
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

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final errData = json.decode(response.body);
          return errData['detail'] ?? 'Gagal menyimpan data booking ke server.';
        } catch (_) {
          return 'Gagal menyimpan data booking ke server (Status ${response.statusCode}).';
        }
      }
      
      final responseData = json.decode(response.body);
      bookingId = responseData['id'];
    } catch (e) {
      print('Error submitting booking: $e');
      return 'Terjadi kesalahan jaringan. Gagal menyimpan booking.';
    }

    if (bookingId != null && (data.ktpBytes != null || data.selfieBytes != null || data.buktiBayarBytes != null)) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/bookings/$bookingId/upload-documents'),
        );
        request.headers['Authorization'] = 'Bearer $_accessToken';

        if (data.ktpBytes != null) {
          request.files.add(http.MultipartFile.fromBytes('ktp_image', data.ktpBytes!, filename: 'ktp.jpg'));
        }
        if (data.selfieBytes != null) {
          request.files.add(http.MultipartFile.fromBytes('selfie_image', data.selfieBytes!, filename: 'selfie.jpg'));
        }
        if (data.buktiBayarBytes != null) {
          request.files.add(http.MultipartFile.fromBytes('bukti_bayar', data.buktiBayarBytes!, filename: 'bukti.jpg'));
        }

        final streamedResponse = await request.send();
        if (streamedResponse.statusCode != 200) {
          return 'Booking berhasil dibuat, namun gagal mengunggah dokumen (Status ${streamedResponse.statusCode}). Silakan upload ulang nanti.';
        }
      } catch (e) {
        print('Error uploading documents: $e');
        return 'Booking berhasil, tetapi terjadi kesalahan jaringan saat mengunggah dokumen.';
      }
    }

    _bookingData = data;
    _currentRole = UserRole.pendingResident;

    if (_userEmail != null && _registeredUsers.containsKey(_userEmail)) {
      _registeredUsers[_userEmail!]!['role'] = 'pendingResident';
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
    return null; // success
  }

  Future<void> loadPendingBookings() async {
    // We intentionally do not wipe _pendingApprovals and fetch from backend here
    // because the backend does not store the KTP/Selfie/Payment bytes yet.
    // The local memory list contains the full data needed for the Admin panel.
    notifyListeners();
  }

  Future<String?> updateBookingStatus(int bookingId, String status) async {
    if (_accessToken == null) return 'Sesi telah berakhir, silakan login kembali.';
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bookings/$bookingId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({'status': status}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      } else {
        try {
          final errData = json.decode(response.body);
          return errData['detail'] ?? 'Gagal mengupdate status (Status ${response.statusCode}).';
        } catch (_) {
          return 'Gagal mengupdate status (Status ${response.statusCode}).';
        }
      }
    } catch (e) {
      print('Error updating booking status: $e');
      return 'Terjadi kesalahan jaringan saat mengupdate status.';
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
    if (_accessToken == null) throw Exception('Sesi telah berakhir, silakan login kembali.');
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        try {
          final errData = json.decode(response.body);
          throw Exception(errData['detail'] ?? 'Gagal membuat jastip (Status ${response.statusCode}).');
        } catch (_) {
          throw Exception('Gagal membuat jastip (Status ${response.statusCode}).');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      print('Error creating jastip: $e');
      throw Exception('Terjadi kesalahan jaringan.');
    }
  }

  Future<String?> deleteJastipListing(int listingId) async {
    if (_accessToken == null) return 'Sesi telah berakhir, silakan login kembali.';
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/jastip/$listingId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return null;
      } else {
        try {
          final errData = json.decode(response.body);
          return errData['detail'] ?? 'Gagal menghapus jastip (Status ${response.statusCode}).';
        } catch (_) {
          return 'Gagal menghapus jastip (Status ${response.statusCode}).';
        }
      }
    } catch (e) {
      print('Error deleting jastip: $e');
      return 'Terjadi kesalahan jaringan saat menghapus jastip.';
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

  String get apiOrigin => _baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');

  String resolveMediaUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$apiOrigin$url';
    return '$apiOrigin/$url';
  }

  Future<Map<String, dynamic>?> createRoom(Map<String, dynamic> data) async {
    if (_accessToken == null) throw Exception('Sesi telah berakhir, silakan login kembali.');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rooms/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        try {
          final errData = json.decode(response.body);
          throw Exception(errData['detail'] ?? 'Gagal membuat kamar (Status ${response.statusCode}).');
        } catch (_) {
          throw Exception('Gagal membuat kamar (Status ${response.statusCode}).');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      print('Error creating room: $e');
      throw Exception('Terjadi kesalahan jaringan saat membuat kamar.');
    }
  }

  Future<List<String>?> uploadRoomImages(
    int roomId,
    List<Uint8List> imageBytes, {
    List<String>? filenames,
  }) async {
    if (imageBytes.isEmpty) return [];

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/rooms/$roomId/upload-images'),
      );

      for (var i = 0; i < imageBytes.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            imageBytes[i],
            filename: filenames?[i] ?? 'room_$i.jpg',
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final images = data['additional_images'];
        if (images is List) {
          return images.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      print('Error uploading room images: $e');
    }
    return null;
  }

  Future<bool> deleteRoomImage(int roomId, String imageUrl) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/rooms/$roomId/images',
      ).replace(queryParameters: {'image_url': imageUrl});
      final response = await http.delete(uri);
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting room image: $e');
      return false;
    }
  }

  Future<bool> syncRoomImageFields(int roomId, List<String> allUrls) async {
    if (allUrls.isEmpty) {
      return updateRoom(roomId, {'image_url': '', 'additional_images': ''});
    }

    return updateRoom(roomId, {
      'image_url': allUrls.first,
      'additional_images': allUrls.length > 1
          ? allUrls.sublist(1).join(',')
          : '',
    });
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

  Future<Map<String, dynamic>?> submitTool(String name, String iconName) async {
    if (_accessToken == null) throw Exception('Sesi telah berakhir, silakan login kembali.');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tools/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'name': name,
          'icon_name': iconName,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        try {
          final errData = json.decode(response.body);
          throw Exception(errData['detail'] ?? 'Gagal menambah alat (Status ${response.statusCode}).');
        } catch (_) {
          throw Exception('Gagal menambah alat (Status ${response.statusCode}).');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan jaringan.');
    }
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

  /// Fetch reviews from backend. Call on screen open so data is always fresh.
  Future<void> fetchReviews() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/reviews/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _reviews
          ..clear()
          ..addAll(data.map((r) => Review(
                userName: r['user_name'] ?? 'Anonymous',
                userEmail: r['user_email'] ?? '',
                rating: (r['rating'] as num).toDouble(),
                comment: r['comment'] ?? '',
                createdAt: DateTime.parse(r['created_at']),
                roomType: r['room_type'],
              )));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
    }
  }

  /// Submit a review to the backend (for residents and pending residents
  /// who have confirmed payment). Returns null on success, error string on failure.
  Future<String?> submitReview({
    required double rating,
    required String comment,
  }) async {
    // ── Client-side validations (kept identical to previous logic) ──────────
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

    // Optimistic duplicate check using cached data (backend enforces it too)
    final alreadyReviewed =
        _reviews.any((r) => r.userEmail == _userEmail);
    if (alreadyReviewed) {
      return 'Anda sudah memberikan review sebelumnya.';
    }

    if (_accessToken == null) {
      return 'Anda harus login terlebih dahulu.';
    }

    // ── Send to backend ───────────────────────────────────────────────────
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reviews/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'rating': rating,
          'comment': comment.trim(),
          'room_type': _bookingData?.roomType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh list from backend so everyone sees the same data
        await fetchReviews();
        return null; // success
      } else {
        final data = json.decode(response.body);
        return data['detail'] ?? 'Gagal mengirim review. Coba lagi.';
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }
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
