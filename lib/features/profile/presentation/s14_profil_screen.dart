import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../stats/domain/stats_model.dart';
import '../../stats/presentation/stats_controller.dart';

class S14ProfilScreen extends ConsumerWidget {
  const S14ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    final statsAsync = ref.watch(userStatsStreamProvider);
    final stats = statsAsync.valueOrNull ?? const UserStats();

    // Real dynamic stats from Firebase RTDB nodes
    final createdRoomsCount = stats.roomsCreated;
    final joinedRoomsCount = stats.roomsJoined;
    final totalSessionsCount = stats.sessionsCompleted;

    final displayName = user?.displayName.isNotEmpty == true ? user!.displayName : 'Pengguna';
    final email = user?.email.isNotEmpty == true ? user!.email : '-';
    final photoUrl = user?.photoUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header: K KerKom logo and Notification Bell (NO settings gear)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/kerkom_logo.png',
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.groups_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KerKom',
                        style: AppTheme.headlineMedium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/notifications'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2EDF9)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A101653),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 22),
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text(
                'Profil',
                style: AppTheme.headlineMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  fontSize: 24,
                ),
              ),

              const SizedBox(height: 16),

              // User Profile Info Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () => context.push('/edit-profile'),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          AvatarCircle(
                            name: displayName,
                            photoUrl: photoUrl,
                            size: 64,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2EDF9), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.headlineSmall.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Real Statistics Card (Ruang Dibuat, Ruang Diikuti, Total Sesi)
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        count: createdRoomsCount.toString(),
                        label: 'Ruang Dibuat',
                      ),
                    ),
                    Container(width: 1, height: 32, color: const Color(0xFFE2EDF9)),
                    Expanded(
                      child: _buildStatColumn(
                        count: joinedRoomsCount.toString(),
                        label: 'Ruang Diikuti',
                      ),
                    ),
                    Container(width: 1, height: 32, color: const Color(0xFFE2EDF9)),
                    Expanded(
                      child: _buildStatColumn(
                        count: totalSessionsCount.toString(),
                        label: 'Total Sesi',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Streak Card (Aktivitas minggu berjalan)
              Builder(
                builder: (context) {
                  final activeDaysCount = stats.weeklyActivity.where((a) => a).length;
                  final title = activeDaysCount > 0
                      ? '$activeDaysCount hari aktif minggu ini'
                      : 'Mulai sesi fokus minggu ini';

                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StreakDay(day: 'Sen', isActive: stats.weeklyActivity[0]),
                            _StreakDay(day: 'Sel', isActive: stats.weeklyActivity[1]),
                            _StreakDay(day: 'Rab', isActive: stats.weeklyActivity[2]),
                            _StreakDay(day: 'Kam', isActive: stats.weeklyActivity[3]),
                            _StreakDay(day: 'Jum', isActive: stats.weeklyActivity[4]),
                            _StreakDay(day: 'Sab', isActive: stats.weeklyActivity[5]),
                            _StreakDay(day: 'Min', isActive: stats.weeklyActivity[6]),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Menu List Card: Sensitivitas Sensor, Pengaturan Alarm, Integrasi Kalender, Tentang Aplikasi, Keluar Akun, Hapus Akun
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.speed_rounded,
                      title: 'Sensitivitas Sensor',
                      onTap: () => context.push('/sensor-sensitivity'),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2EDF9)),
                    _buildMenuTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Pengaturan Alarm',
                      onTap: () => context.push('/alarm-settings'),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2EDF9)),
                    _buildMenuTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Integrasi Kalender',
                      onTap: () => context.push('/calendar-integration'),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2EDF9)),
                    _buildMenuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang Aplikasi',
                      onTap: () => context.push('/about-app'),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2EDF9)),
                    _buildMenuTile(
                      icon: Icons.logout_rounded,
                      title: 'Keluar Akun',
                      textColor: AppColors.navy,
                      onTap: () => _showSignOutDialog(context, ref),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2EDF9)),
                    _buildMenuTile(
                      icon: Icons.delete_outline_rounded,
                      title: 'Hapus Akun',
                      iconColor: AppColors.red,
                      textColor: AppColors.red,
                      onTap: () => _showDeleteAccountDialog(context, ref),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({required String count, required String label}) {
    return Column(
      children: [
        Text(
          count,
          style: AppTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? AppColors.navy),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor ?? AppColors.navy,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StreakDay extends StatelessWidget {
  final String day;
  final bool isActive;

  const _StreakDay({required this.day, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : const Color(0xFFF1F5F9),
            border: Border.all(
              color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: AppTheme.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
