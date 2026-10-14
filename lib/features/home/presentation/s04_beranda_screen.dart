import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../room/domain/room_models.dart';
import '../../stats/domain/stats_model.dart';
import '../../stats/presentation/stats_controller.dart';
import '../../room/presentation/room_controller.dart';
import '../../room/presentation/s05_sheet_buat_ruang.dart';
import '../../room/presentation/s06_sheet_gabung_kode.dart';

class S04BerandaScreen extends ConsumerWidget {
  const S04BerandaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final activeRoomBannerAsync = ref.watch(userActiveRoomBannerProvider);
    final userRoomsAsync = ref.watch(userRoomsStreamProvider);
    final userStatsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header: Logo K & Nama KerKom di kiri, Notifikasi dengan Unread Dot di kanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/kerkom_logo.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'KerKom',
                        style: AppTheme.headlineMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      context.push('/notifications');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08101653),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.navy,
                            size: 24,
                          ),
                          // Indikator unread red dot
                          Positioned(
                            top: 10,
                            right: 11,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
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
              const SizedBox(height: 20),

              // 2. Profil Pengguna: Avatar asli, Sapaan "Halo, [nama pengguna]" dan Teks singkat
              Builder(
                builder: (context) {
                  final user = userAsync.valueOrNull;
                  final rawName = user?.displayName ?? '';
                  final firstName = rawName.trim().isNotEmpty
                      ? rawName.trim().split(' ').first
                      : 'Farhan';

                  return Row(
                    children: [
                      AvatarCircle(
                        name: rawName.isNotEmpty ? rawName : 'Farhan',
                        photoUrl: user?.photoUrl,
                        size: 48,
                        onTap: () => context.go('/profile'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go('/profile'),
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $firstName',
                                style: AppTheme.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navy,
                                  fontSize: 19,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Siap kerja kelompok hari ini?',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              // Amber Active Room Banner (Jika ada sesi berjalan)
              activeRoomBannerAsync.when(
                data: (activeData) {
                  if (activeData == null) return const SizedBox.shrink();
                  final status = activeData['status']?.toString();
                  if (status == 'lobi' || status == 'kalibrasi' || status == 'berjalan') {
                    final roomId = activeData['roomId']?.toString();
                    final roomName = activeData['roomName']?.toString() ?? 'Ruang Belajar';
                    final roomCode = activeData['roomCode']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: GestureDetector(
                        onTap: () {
                          if (roomId != null) context.push('/lobby/$roomId');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C101653),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sesi sedang berjalan - Kembali',
                                      style: AppTheme.labelMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$roomName ($roomCode)',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),

              // 3. Kalender Performa (Mockup 3)
              AppCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Performa & Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Performa',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8FD),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            'Minggu Ini',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Persentase Kenaikan Performa (Dihitung dari data aktual)
                    Builder(
                      builder: (context) {
                        final stats = userStatsAsync.valueOrNull ?? const UserStats();
                        final percent = stats.sessionsCompleted > 0
                            ? stats.performancePercent
                            : (stats.roomsCreated > 0 || stats.roomsJoined > 0 ? 100.0 : 0.0);
                        final percentStr = (stats.sessionsCompleted > 0 || stats.roomsCreated > 0)
                            ? '+${percent.toStringAsFixed(1).replaceAll('.', ',')}%'
                            : '0%';

                        return Row(
                          children: [
                            Text(
                              percentStr,
                              style: AppTheme.headlineMedium.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.green,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_outward_rounded,
                              color: AppColors.green,
                              size: 20,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Heatmap Aktivitas Mingguan (7 Kolom x 4 Baris)
                    _buildWeeklyHeatmap(userStatsAsync.valueOrNull ?? const UserStats()),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Aksi Utama: Dua Card Berdampingan ("Buat Ruang" & "Gabung dengan Kode")
              Row(
                children: [
                  // Card 1: "Buat Ruang" (Navy/Oceanic Blue Card)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        BottomSheetHelper.show(
                          context: context,
                          child: const S05SheetBuatRuang(),
                        );
                      },
                      child: Container(
                        height: 130,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF073860), Color(0xFF03223D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F073860),
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.videocam_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Text(
                              'Buat Ruang',
                              style: AppTheme.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Card 2: "Gabung dengan Kode" (White Card)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        BottomSheetHelper.show(
                          context: context,
                          child: const S06SheetGabungKode(),
                        );
                      },
                      child: Container(
                        height: 130,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A101653),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEBF3FE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gabung',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'dengan Kode',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Jadwal Terdekat: Daftar Jadwal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jadwal Terdekat',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                      fontSize: 16,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go('/history'),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'Lihat Semua',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List Kartu Jadwal
              _buildScheduleList(userRoomsAsync, context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Heatmap Mingguan (7 Kolom: Sen s/d Min x 4 Baris) berdasarkan sesi real
  Widget _buildWeeklyHeatmap(UserStats stats) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    Color getColorForLevel(int level) {
      switch (level) {
        case 1:
          return const Color(0xFFD6E4FD); // Biru muda halus
        case 2:
          return const Color(0xFF99BFFD); // Biru medium
        case 3:
          return const Color(0xFF2463FF); // Biru elektrik
        case 4:
          return const Color(0xFF0D47A1); // Deep blue
        default:
          return const Color(0xFFF1F5F9); // Kosong / abu sangat muda
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (colIndex) {
            final minutes = stats.dailyMinutes[colIndex];
            int activeBars = 0;
            int level = 0;
            if (minutes > 0) {
              if (minutes < 15) {
                activeBars = 1;
                level = 1;
              } else if (minutes < 30) {
                activeBars = 2;
                level = 2;
              } else if (minutes < 60) {
                activeBars = 3;
                level = 3;
              } else {
                activeBars = 4;
                level = 4;
              }
            }

            return Column(
              children: [
                ...List.generate(4, (rowIndex) {
                  // Lit from bottom to top (row 3, 2, 1, 0)
                  final isLit = (3 - rowIndex) < activeBars;
                  return Container(
                    width: 24,
                    height: 8,
                    margin: const EdgeInsets.only(bottom: 3),
                    decoration: BoxDecoration(
                      color: isLit ? getColorForLevel(level) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Text(
                  days[colIndex],
                  style: AppTheme.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Daftar Jadwal Terdekat dari data real Firebase
  Widget _buildScheduleList(AsyncValue<List<UserRoomIndex>> userRoomsAsync, BuildContext context) {
    return userRoomsAsync.when(
      data: (rooms) {
        // Hanya tampilkan ruangan aktif (belum selesai) untuk jadwal terdekat
        final activeRooms = rooms.where((r) => r.status.toLowerCase() != 'selesai').toList();

        if (activeRooms.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 38, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text(
                  'Belum ada jadwal ruangan aktif',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Buat ruang baru atau gabung dengan kode untuk memulai sesi belajar.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Urutkan jadwal terdekat: jadwal yang paling dekat dari hari & jam saat ini berada di paling atas
        final sorted = [...activeRooms]..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
        final displayList = sorted.take(5).toList();

        return Column(
          children: displayList.map((room) {
            final date = DateTime.fromMillisecondsSinceEpoch(room.scheduledStart);
            final dayStr = date.day.toString().padLeft(2, '0');
            final monthStr = months[date.month - 1];

            final roomDay = DateTime(date.year, date.month, date.day);
            final diffDays = roomDay.difference(today).inDays;
            final isToday = diffDays == 0;
            final isTomorrow = diffDays == 1;
            final isYesterday = diffDays == -1;

            final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
            final prefix = isToday
                ? 'Hari Ini, $timeStr'
                : (isTomorrow
                    ? 'Besok, $timeStr'
                    : (isYesterday ? 'Kemarin, $timeStr' : '$dayStr $monthStr, $timeStr'));

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                borderRadius: 18,
                onTap: () {
                  if (room.status == 'selesai') {
                    context.push('/history-detail/${room.roomId}');
                  } else if (room.status == 'berjalan') {
                    context.push('/active-session/${room.roomId}');
                  } else {
                    context.push('/lobby/${room.roomId}');
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF3FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayStr,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              height: 1.1,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            monthStr,
                            style: AppTheme.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.name,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                prefix,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: AppColors.textMuted,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Text(
                                '${room.durationMin} menit',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            'Belum ada ruangan yang dibuat',
            style: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
