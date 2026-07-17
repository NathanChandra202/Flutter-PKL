import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'main_navigation.dart';
import 'admin_panel_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button + Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlack),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Image.network(
                    'https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/logo/kostraktor.jpeg',
                    height: 28,
                    errorBuilder: (_, __, ___) => const Text(
                      'Kostraktor',
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textMuted,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'Masuk'),
                    Tab(text: 'Daftar Baru'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LoginForm(),
                  _RegisterForm(onSwitchToLogin: () => _tabController.animateTo(0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Login Form ──────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleLogin() {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = auth.login(email, password);

    setState(() => _isLoading = false);

    if (error == null) {
      // Success — route based on role
      Widget dest;
      if (auth.currentRole == UserRole.admin) {
        dest = const AdminPanelScreen();
      } else {
        dest = const MainNavigation();
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => dest),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Selamat datang\nkembali',
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Masuk untuk melanjutkan ke akun Anda.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Credentials hint
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Akun Demo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade900)),
                const SizedBox(height: 6),
                Text('Calon Penghuni: calon@kostraktor.com | 123456',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                Text('Admin: admin@kostraktor.com | admin123',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Email
          _InputField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          // Password
          _InputField(
            controller: _passwordController,
            hintText: 'Kata Sandi',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Lupa Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Masukkan email akun kamu. Kami akan simulasikan pengiriman link reset kata sandi.'),
                        const SizedBox(height: 16),
                        TextField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email aktif kamu',
                            hintStyle: const TextStyle(color: AppTheme.textMuted),
                            prefixIcon: const Icon(Icons.mail_outline, color: AppTheme.textMuted, size: 20),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryBlack)),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlack, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Link reset kata sandi telah dikirim ke email kamu.'),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        child: const Text('Kirim Link Reset'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Lupa Kata Sandi?', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('MASUK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.0)),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              ),
              child: const Text(
                'Lanjutkan tanpa akun',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Register Form ────────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const _RegisterForm({required this.onSwitchToLogin});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleRegister() {
    final nama = _namaController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    // Validasi nama: minimal 3 kata, hanya huruf dan spasi
    final namaWords = nama.split(' ').where((w) => w.isNotEmpty).toList();
    if (namaWords.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap minimal 3 kata.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(nama)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama hanya boleh mengandung huruf.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Validasi password min 8 karakter + huruf & angka
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    if (password.length < 8 || !hasLetter || !hasDigit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 8 karakter, kombinasi huruf dan angka.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = auth.register(
      _namaController.text,
      _emailController.text,
      _phoneController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (error == null) {
      // Show email confirmation simulation dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Icon(Icons.mark_email_read_outlined, color: Colors.green.shade600, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Cek Email Konfirmasi!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Link konfirmasi telah dikirim ke\n${_emailController.text.trim()}\n\nSilakan cek inbox (atau folder spam) untuk mengaktifkan akun Anda.',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                      (route) => false,
                    );
                  },
                  child: const Text('Lanjutkan ke Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Buat akun baru',
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gratis! Daftar sekarang dan jelajahi unit Kostraktor.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 32),

          _InputField(controller: _namaController, hintText: 'Nama Lengkap', prefixIcon: Icons.person_outline),
          const SizedBox(height: 14),
          _InputField(controller: _emailController, hintText: 'Email Aktif', prefixIcon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _InputField(controller: _phoneController, hintText: 'Nomor HP (WhatsApp)', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _InputField(
            controller: _passwordController,
            hintText: 'Kata Sandi (min. 8 karakter, huruf & angka)',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMuted, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _confirmPasswordController,
            hintText: 'Konfirmasi Kata Sandi',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('DAFTAR SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: widget.onSwitchToLogin,
              child: const Text('Sudah punya akun? Masuk', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Input Field ─────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(prefixIcon, color: AppTheme.textMuted, size: 20),
        suffixIcon: suffixIcon,
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
          borderSide: const BorderSide(color: AppTheme.primaryBlack, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
