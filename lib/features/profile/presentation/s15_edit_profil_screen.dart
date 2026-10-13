import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/domain/validators.dart';
import '../../auth/presentation/auth_controller.dart';

class S15EditProfilScreen extends ConsumerStatefulWidget {
  const S15EditProfilScreen({super.key});

  @override
  ConsumerState<S15EditProfilScreen> createState() => _S15EditProfilScreenState();
}

class _S15EditProfilScreenState extends ConsumerState<S15EditProfilScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _photoUrlController;
  String _selectedPhotoUrl = '';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _avatarAssets = const [
    'assets/avatar/avatar-ce1.png',
    'assets/avatar/avatar-ce2.png',
    'assets/avatar/avatar-ce3.png',
    'assets/avatar/avatar-co1.png',
    'assets/avatar/avatar-co2.png',
    'assets/avatar/avatar-co3.png',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _selectedPhotoUrl = user?.photoUrl ?? '';
    _photoUrlController = TextEditingController(text: _selectedPhotoUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Avatar Karakter',
                textAlign: TextAlign.center,
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gunakan salah satu avatar karakter resmi KerKom',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _avatarAssets.length,
                itemBuilder: (context, index) {
                  final assetPath = _avatarAssets[index];
                  final isSelected = _selectedPhotoUrl == assetPath;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPhotoUrl = assetPath;
                        _photoUrlController.text = assetPath;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFE2EDF9),
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: [
                          if (isSelected)
                            const BoxShadow(
                              color: Color(0x332463FF),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(assetPath, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showCustomUrlDialog() {
    final tempController = TextEditingController(text: _selectedPhotoUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tautan Foto Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan tautan (URL) gambar untuk foto profil Anda:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tempController,
              decoration: InputDecoration(
                hintText: 'https://example.com/avatar.jpg',
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _selectedPhotoUrl = tempController.text.trim();
                _photoUrlController.text = _selectedPhotoUrl;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Gunakan'),
          ),
        ],
      ),
    );
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
      await authRepo.updateProfile(
        displayName: _nameController.text.trim(),
        photoUrl: _selectedPhotoUrl.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: AppColors.green,
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final email = user?.email ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.navy),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profil',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Preview & Controls Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          AvatarCircle(
                            name: _nameController.text.isNotEmpty ? _nameController.text : 'Pengguna',
                            photoUrl: _selectedPhotoUrl.isNotEmpty ? _selectedPhotoUrl : null,
                            size: 96,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showAvatarPicker,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33101653),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showAvatarPicker,
                          icon: const Icon(Icons.face_retouching_natural_rounded, size: 16),
                          label: const Text('Pilih Avatar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: Color(0xFFE2EDF9)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _showCustomUrlDialog,
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: const Text('URL Foto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: Color(0xFFE2EDF9)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        if (_selectedPhotoUrl.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedPhotoUrl = '';
                                _photoUrlController.clear();
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            child: const Text('Kosongkan'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Inputs Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'USERNAME / NAMA TAMPILAN',
                      style: AppTheme.labelSmall.copyWith(
                        letterSpacing: 1.1,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama pengguna',
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.navy, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'EMAIL (READ-ONLY)',
                      style: AppTheme.labelSmall.copyWith(
                        letterSpacing: 1.1,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: email),
                      readOnly: true,
                      enabled: false,
                      style: AppTheme.bodyLarge.copyWith(color: AppColors.textMuted),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                        suffixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18),
                        helperText: 'Email akun KerKom tidak dapat diubah.',
                        helperStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
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
                      text: 'Simpan Perubahan',
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
