import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/validators.dart';
import 'auth_controller.dart';
import '../../room/presentation/room_controller.dart';

class S18DaftarScreen extends ConsumerStatefulWidget {
  const S18DaftarScreen({super.key});

  @override
  ConsumerState<S18DaftarScreen> createState() => _S18DaftarScreenState();
}

class _S18DaftarScreenState extends ConsumerState<S18DaftarScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  // Requirement 7: Default checkbox adalah kosong terlebih dahulu (false)
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
    _confirmPasswordController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _emailController.removeListener(_onFormChanged);
    _passwordController.removeListener(_onFormChanged);
    _confirmPasswordController.removeListener(_onFormChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Requirement 7: Semua field terisi & checkbox dicentang baru tombol bisa diklik
  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      _agreedToTerms;

  Future<void> _handleRegister() async {
    if (!_isFormValid) return;

    setState(() => _errorMessage = null);

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Harap setujui ketentuan layanan dan pemrosesan data.');
      return;
    }

    final nameErr = FormValidators.validateDisplayName(_nameController.text);
    if (nameErr != null) {
      setState(() => _errorMessage = nameErr);
      return;
    }

    final emailErr = FormValidators.validateEmail(_emailController.text);
    if (emailErr != null) {
      setState(() => _errorMessage = emailErr);
      return;
    }

    final passErr = FormValidators.validatePassword(_passwordController.text);
    if (passErr != null) {
      setState(() => _errorMessage = passErr);
      return;
    }

    final confirmErr = FormValidators.validateConfirmPassword(
      _passwordController.text,
      _confirmPasswordController.text,
    );
    if (confirmErr != null) {
      setState(() => _errorMessage = confirmErr);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signUpWithEmail(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        final pendingCode = ref.read(pendingInviteCodeProvider);
        if (pendingCode != null && pendingCode.isNotEmpty) {
          try {
            final room = await ref.read(roomRepositoryProvider).joinRoomByCode(pendingCode);
            ref.read(pendingInviteCodeProvider.notifier).state = null;
            if (mounted) {
              context.go('/lobby/${room.id}');
              return;
            }
          } catch (_) {}
        }
        if (!mounted) return;
        context.go('/home');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleRegister() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();

      if (!mounted) return;
      final pendingCode = ref.read(pendingInviteCodeProvider);
      if (pendingCode != null && pendingCode.isNotEmpty) {
        try {
          final room = await ref.read(roomRepositoryProvider).joinRoomByCode(pendingCode);
          ref.read(pendingInviteCodeProvider.notifier).state = null;
          if (mounted) {
            context.go('/lobby/${room.id}');
            return;
          }
        } catch (_) {}
      }
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF071930),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Gambar Background 'BG-login dan register.png'
            Positioned.fill(
              child: Image.asset(
                'assets/images/BG-login dan register.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/bg_login_register.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  );
                },
              ),
            ),

            // Tombol Kembali di Header Atas (Positioned agar tidak mengecilkan Stack)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/landing');
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'Kembali',
                              style: AppTheme.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Card Putih Melengkung Utama
            Positioned(
              top: size.height * 0.18,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Judul & Subjudul Biru Rata Tengah (Requirement 3)
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Mulai Sekarang',
                                textAlign: TextAlign.center,
                                style: AppTheme.headlineLarge.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0077B6),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Buat akun Kerkom untuk kolaborasi fokus bersama',
                                textAlign: TextAlign.center,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: const Color(0xFF0077B6).withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pesan Error Inline
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: const Color(0xFFB91C1C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Field Nama Lengkap (Label Sejajar Border Grid Box - Requirement 5)
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                          decoration: _buildInputDecoration(
                            labelText: 'Nama Lengkap',
                            hintText: 'Nama Lengkap Mahasiswa',
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Field Email (Label Sejajar Border Grid Box - Requirement 5)
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                          decoration: _buildInputDecoration(
                            labelText: 'Email',
                            hintText: 'nama@kampus.ac.id',
                            prefixIcon: Icons.mail_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Field Kata Sandi (Label Sejajar Border Grid Box - Requirement 5)
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                          decoration: _buildInputDecoration(
                            labelText: 'Kata Sandi',
                            hintText: 'Minimal 8 karakter',
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF0077B6),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Field Konfirmasi Kata Sandi (Label Sejajar Border Grid Box - Requirement 5)
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleRegister(),
                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                          decoration: _buildInputDecoration(
                            labelText: 'Konfirmasi Kata Sandi',
                            hintText: 'Ulangi kata sandi Anda',
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF0077B6),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Checkbox Persetujuan Ketentuan (Requirement 4 & 7)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _agreedToTerms,
                                checkColor: Colors.white,
                                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const Color(0xFF0077B6);
                                  }
                                  return Colors.transparent;
                                }),
                                side: const BorderSide(
                                  color: Color(0xFF0077B6),
                                  width: 1.8,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                    _agreedToTerms = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _agreedToTerms = !_agreedToTerms;
                                  });
                                },
                                child: Text(
                                  'Saya menyetujui pemrosesan data pribadi & ketentuan layanan.',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: const Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Tombol Daftar Utama (Aktif hanya jika form lengkap & checkbox dicentang - Requirement 7)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (_isLoading || !_isFormValid) ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0077B6),
                              disabledBackgroundColor: const Color(0xFFCBD5E1),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    'Daftar',
                                    style: AppTheme.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Divider Alternatif
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0),
                              child: Text(
                                'Atau daftar dengan',
                                style: AppTheme.bodySmall.copyWith(
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Opsi Alternatif: Google Icon Custom (Requirement 2)
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleGoogleRegister,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildGoogleIcon(),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Daftar dengan Google',
                                    style: AppTheme.labelLarge.copyWith(
                                      color: const Color(0xFF1E293B),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Link Footer: Sudah punya akun? Masuk
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: RichText(
                              text: TextSpan(
                                text: 'Sudah punya akun? ',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Masuk',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: const Color(0xFF0077B6),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: Color(0xFF0077B6),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF0077B6),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF0077B6), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0077B6), width: 1.8),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Image.asset(
      'assets/images/Google-icon.png',
      width: 22,
      height: 22,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/google_icon.png',
          width: 22,
          height: 22,
        );
      },
    );
  }
}
