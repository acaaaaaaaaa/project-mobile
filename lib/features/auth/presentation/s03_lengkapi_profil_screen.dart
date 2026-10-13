import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/validators.dart';
import 'auth_controller.dart';
import '../../room/presentation/room_controller.dart';

class S03LengkapiProfilScreen extends ConsumerStatefulWidget {
  const S03LengkapiProfilScreen({super.key});

  @override
  ConsumerState<S03LengkapiProfilScreen> createState() => _S03LengkapiProfilScreenState();
}

class _S03LengkapiProfilScreenState extends ConsumerState<S03LengkapiProfilScreen> {
  late final TextEditingController _nameController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: firebaseUser?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _errorMessage = null);

    final err = FormValidators.validateDisplayName(_nameController.text);
    if (err != null) {
      setState(() => _errorMessage = err);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.completeProfile(_nameController.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'kerkom',
                style: AppTheme.headlineMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Satu langkah lagi',
                style: AppTheme.headlineLarge.copyWith(
                  fontSize: 26,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tentukan nama panggilan Anda yang akan dilihat oleh rekan belajar saat sesi fokus.',
                style: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'NAMA TAMPILAN',
                      style: AppTheme.labelSmall.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: AppTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Farhan Aditya',
                        hintStyle: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.redSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Simpan & Lanjutkan',
                      isLoading: _isLoading,
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
