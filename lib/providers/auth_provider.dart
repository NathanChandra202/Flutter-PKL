import 'package:flutter/foundation.dart';

/// Roles in the app
/// - [guest]           : browsing only, not logged in
/// - [calon]           : logged in, hasn't booked yet
/// - [pendingResident] : has submitted booking, waiting for admin confirmation
/// - [resident]        : confirmed active resident
/// - [admin]           : admin panel access
enum UserRole { guest, calon, pendingResident, resident, admin }

class BookingData {
  final String nama;
  final String phone;
  final String nik;
  final String roomType;
  final DateTime bookingTime;
  bool waConfirmed; // user has sent WA to penjaga kos

  BookingData({
    required this.nama,
    required this.phone,
    required this.nik,
    required this.roomType,
    required this.bookingTime,
    this.waConfirmed = false,
  });
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
    if (nama.trim().isEmpty || phone.trim().isEmpty || password.length < 6) {
      return 'Pastikan semua data diisi dengan benar dan password minimal 6 karakter.';
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
