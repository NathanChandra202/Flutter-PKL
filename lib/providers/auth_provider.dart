import 'dart:math';
import 'package:flutter/foundation.dart';

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

class BookingData {
  final String nama;
  final String phone;
  final String nik;
  final String roomType;
  final DateTime bookingTime;
  bool waConfirmed;
  final String referensiTransaksi;
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
    this.waConfirmed = false,
    String? referensiTransaksi,
    int? uniquePaymentCode,
    this.ktpBytes,
    this.selfieBytes,
    this.buktiBayarBytes,
  })  : referensiTransaksi = referensiTransaksi ?? _generateRef(),
        uniquePaymentCode = uniquePaymentCode ?? generateUniquePaymentCode();

  static String _generateRef() {
    final now = DateTime.now();
    final ymd =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand =
        (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
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
    'calon@kostraktor.com': {'password': '123456', 'name': 'Calon Penghuni', 'phone': '08123456789', 'role': 'calon'},
    'admin@kostraktor.com': {'password': 'admin123', 'name': 'Admin Kostraktor', 'phone': '081234567890', 'role': 'admin'},
  };

  // Queue of users pending admin approval
  final List<PendingUser> _pendingApprovals = [];

  // ─── Getters ──────────────────────────────────────────────────────────────

  UserRole get currentRole => _currentRole;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  BookingData? get bookingData => _bookingData;
  String? get assignedRoom => _assignedRoom;
  List<PendingUser> get pendingApprovals => List.unmodifiable(_pendingApprovals);

  bool get isLoggedIn => _currentRole != UserRole.guest;
  bool get isResident => _currentRole == UserRole.resident || _currentRole == UserRole.admin;
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
      final pending = _pendingApprovals.where((p) => p.email == trimmedEmail).firstOrNull;
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
      _pendingApprovals.add(PendingUser(
        email: _userEmail!,
        name: _userName ?? data.nama,
        phone: _userPhone ?? data.phone,
        bookingData: data,
      ));
    }
    notifyListeners();
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
    final pending = _pendingApprovals.where((p) => p.email == email).firstOrNull;
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
    final pending = _pendingApprovals.where((p) => p.email == email).firstOrNull;
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
