import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/validators.dart';
import 'auth_controller.dart';

class S02SheetLupaKataSandi extends ConsumerStatefulWidget {
  const S02SheetLupaKataSandi({super.key});

  @override
  ConsumerState<S02SheetLupaKataSandi> createState() => _S02SheetLupaKataSandiState();
}

class _S02SheetLupaKataSandiState extends ConsumerState<S02SheetLupaKataSandi> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    setState(() => _errorMessage = null);

    final emailErr = FormValidators.validateEmail(_emailController.text);
    if (emailErr != null) {
      setState(() => _errorMessage = emailErr);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordResetEmail(_emailController.text);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
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
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag Indicator Pill
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 22),

              if (!_isSent) ...[
                // Ikon Gembok / Pemulihan Kata Sandi
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Color(0xFF0077B6),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),

                // Judul & Subjudul Biru Rata Tengah
                Text(
                  'Lupa Password',
                  textAlign: TextAlign.center,
                  style: AppTheme.headlineMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0077B6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan email akun Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: const Color(0xFF0077B6).withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),

                // Pesan Error Inline jika ada
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
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
                ],

                // Input Field Email (Label Sejajar Border Grid Box)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSendResetLink(),
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Email',
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
                    hintText: 'nama@kampus.ac.id',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF0077B6), size: 20),
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
                  ),
                ),
                const SizedBox(height: 22),

                // Tombol Kirim Tautan
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
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
                            'Kirim',
                            style: AppTheme.labelLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Batal
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Batal',
                    style: AppTheme.bodyMedium.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                // Tampilan Sukses (Pesan Netral Sesuai Alur)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: Color(0xFF16A34A),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),

                // Pesan Netral Sesuai Permintaan
                Text(
                  'Jika email terdaftar, kami sudah mengirim tautan reset',
                  textAlign: TextAlign.center,
                  style: AppTheme.headlineSmall.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0077B6),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Periksa kotak masuk atau folder spam email Anda. Buka tautan dari Firebase untuk membuat kata sandi baru, lalu kembali ke halaman masuk.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),

                // Tombol Kembali ke Halaman Masuk
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Kembali ke Halaman Masuk',
                      style: AppTheme.labelLarge.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
