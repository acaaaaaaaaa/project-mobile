import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/auth_controller.dart';

class S25PengaturanAkunScreen extends ConsumerWidget {
  const S25PengaturanAkunScreen({super.key});

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun?'),
        content: const Text(
          'Anda perlu masuk kembali untuk mengakses sesi belajar kelompok.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Akun Permanen?',
          style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tindakan ini berbahaya dan tidak dapat dibatalkan. Seluruh data profil dan riwayat sesi fokus Anda di KerKom akan dihapus secara permanen.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authRepositoryProvider).deleteAccount();
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (e.toString() == 'requires-recent-login') {
                  if (context.mounted) _showReauthDialog(context, ref);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );
  }

  void _showReauthDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Kata Sandi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demi keamanan, masukkan kata sandi akun Anda untuk memverifikasi penghapusan akun:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Kata sandi Anda',
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
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final password = passwordController.text;
              Navigator.pop(ctx);
              try {
                await ref.read(authRepositoryProvider).deleteAccount(
                      passwordForReauth: password,
                    );
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal verifikasi: $e'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Verifikasi & Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Pengaturan Akun',
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
              Text(
                'PREFERENSI SESI & SENSOR',
                style: AppTheme.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildTile(
                      icon: Icons.sensors_rounded,
                      iconColor: AppColors.primary,
                      title: 'Sensitivitas Sensor',
                      subtitle: 'Toleransi sudut kemiringan fisik & kalibrasi',
                      onTap: () => context.push('/sensor-settings'),
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.notifications_active_outlined,
                      iconColor: AppColors.primary,
                      title: 'Pengaturan Alarm',
                      subtitle: 'Audio, getaran, volume & tes alarm',
                      onTap: () => context.push('/alarm-settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'MANAJEMEN AKUN',
                style: AppTheme.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildTile(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.navy,
                      title: 'Keluar Akun',
                      subtitle: 'Keluar dari sesi perangkat saat ini',
                      onTap: () => _showSignOutDialog(context, ref),
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.delete_forever_outlined,
                      iconColor: AppColors.red,
                      title: 'Hapus Akun',
                      titleColor: AppColors.red,
                      subtitle: 'Hapus akun dan seluruh riwayat secara permanen',
                      onTap: () => _showDeleteAccountDialog(context, ref),
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

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      color: titleColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
