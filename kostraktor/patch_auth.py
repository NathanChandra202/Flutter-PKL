import re

with open('lib/providers/auth_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update login()
login_replacement = """            // Ensure they exist in local cache
            _registeredUsers[_userEmail!] = {
              'password': password,
              'nama': _userName ?? '',
              'role': _currentRole == UserRole.admin ? 'admin' : 'calon',
            };
          }

          // --- RESTORE BOOKING DATA ---
          final pending = _pendingApprovals.where((p) => p.email == _userEmail).firstOrNull;
          if (pending != null) {
            _bookingData = pending.bookingData;
            _currentRole = UserRole.pendingResident;
            _registeredUsers[_userEmail!]?['role'] = 'pendingResident';
          }"""
          
content = re.sub(
    r'            // Ensure they exist in local cache\n            _registeredUsers\[_userEmail!\] = \{\n              \'password\': password,\n              \'nama\': _userName \?\? \'\',\n              \'role\': _currentRole == UserRole\.admin \? \'admin\' : \'calon\',\n            \};\n          \}',
    login_replacement,
    content
)

# 2. Update signInWithGoogle()
google_replacement = """            // Ensure they exist in local cache
            _registeredUsers[_userEmail!] = {
              'password': '',
              'nama': _userName ?? '',
              'role': _currentRole == UserRole.admin ? 'admin' : 'calon',
            };
          }

          // --- RESTORE BOOKING DATA ---
          final pending = _pendingApprovals.where((p) => p.email == _userEmail).firstOrNull;
          if (pending != null) {
            _bookingData = pending.bookingData;
            _currentRole = UserRole.pendingResident;
            _registeredUsers[_userEmail!]?['role'] = 'pendingResident';
          }"""

content = re.sub(
    r'            // Ensure they exist in local cache\n            _registeredUsers\[_userEmail!\] = \{\n              \'password\': \'\',\n              \'nama\': _userName \?\? \'\',\n              \'role\': _currentRole == UserRole\.admin \? \'admin\' : \'calon\',\n            \};\n          \}',
    google_replacement,
    content
)

# 3. Update submitBooking()
submit_replacement = """    _bookingData = data;
    _currentRole = UserRole.pendingResident;
    
    if (_userEmail != null && _registeredUsers.containsKey(_userEmail)) {
      _registeredUsers[_userEmail!]!['role'] = 'pendingResident';
    }"""

content = re.sub(
    r'    _bookingData = data;\n    _currentRole = UserRole\.pendingResident;',
    submit_replacement,
    content
)

with open('lib/providers/auth_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("auth_provider patched")
