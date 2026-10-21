import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/destructive_outline_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../presentation/room_controller.dart';

class S07LobiScreen extends ConsumerWidget {
  final String roomId;

  const S07LobiScreen({super.key, required this.roomId});

  void _showBackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kembali ke Halaman Sebelumnya?'),
        content: const Text(
          'Ruang belajar ini tetap aktif dan jadwalnya tersimpan. Anda dapat kembali masuk ke lobi ini kapan saja sebelum atau saat sesi dimulai.',
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
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (context.mounted) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/rooms');
                }
              }
            },
            child: const Text('Ya, Kembali'),
          ),
        ],
      ),
    );
  }

  void _showEndRoomDialog(BuildContext context, WidgetRef ref, bool isHost) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHost ? 'Akhiri & Tutup Ruangan?' : 'Keluar dari Ruangan?'),
        content: Text(
          isHost
              ? 'Ruang belajar akan diakhiri dan dipindahkan ke Riwayat. Anda yakin ingin mengakhiri sesi sekarang?'
              : 'Anda akan keluar dari ruangan ini.',
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
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (isHost) {
                await ref.read(roomRepositoryProvider).endRoom(roomId);
              } else {
                await ref.read(roomRepositoryProvider).leaveRoom(roomId);
              }
              if (context.mounted) context.go('/home');
            },
            child: Text(isHost ? 'Akhiri Ruang' : 'Keluar'),
          ),
        ],
      ),
    );
  }

  String _formatLobbySchedule(int? startAt, int durationMinutes) {
    if (startAt == null || startAt <= 0) return '$durationMinutes menit';
    final dt = DateTime.fromMillisecondsSinceEpoch(startAt);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    final endDt = dt.add(Duration(minutes: durationMinutes));
    final startStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final endStr = '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}';
    return '$dateStr • $startStr - $endStr ($durationMinutes menit)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(activeRoomProvider(roomId));
    final membersAsync = ref.watch(roomMembersProvider(roomId));
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    ref.listen(activeRoomProvider(roomId), (prev, next) {
      final room = next.value;
      if (room?.hasEndedAt(DateTime.now().millisecondsSinceEpoch) == true) {
        context.replace('/session-summary/$roomId?readOnly=true');
      } else if (room != null && room.status == 'kalibrasi') {
        context.go('/calibration/$roomId');
      } else if (room != null && room.status == 'berjalan') {
        context.go('/active-session/$roomId');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => _showBackDialog(context),
        ),
        title: Text(
          'Lobi Ruang',
          style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: roomAsync.when(
          data: (room) {
            if (room == null || room.status == 'selesai') {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 48, color: AppColors.amber),
                      const SizedBox(height: 12),
                      Text(
                        'Ruang tidak ditemukan atau sesi telah selesai.',
                        style: AppTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        text: 'Kembali ke Beranda',
                        onPressed: () => context.go('/home'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isHost = room.hostUid == currentUid;
            final isSessionRunning = room.status == 'berjalan';
            final meetingLink = room.meetingLink?.isNotEmpty == true
                ? room.meetingLink!
                : 'https://kerkom.app/j/${room.code}';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Late Join Amber Banner (If status is 'berjalan')
                  if (isSessionRunning) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.amberSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: AppColors.amber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sesi sedang berjalan (sisa ${(room.remainingSeconds ~/ 60)} menit)',
                                  style: AppTheme.labelMedium.copyWith(color: AppColors.amber),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            text: 'Masuk ke Ruang Sesi',
                            icon: const Icon(Icons.login_rounded, size: 20, color: AppColors.onPrimary),
                            onPressed: () => context.go('/active-session/$roomId'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Room Details Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NAMA RUANG',
                          style: AppTheme.labelSmall.copyWith(letterSpacing: 1.2, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.name,
                          style: AppTheme.headlineMedium.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Jadwal Pelaksanaan
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formatLobbySchedule(room.startAt, room.durationMinutes),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Kode Ruang
                        Text(
                          'KODE RUANG BELAJAR',
                          style: AppTheme.labelSmall.copyWith(letterSpacing: 1.2, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              room.code,
                              style: AppTheme.headlineLarge.copyWith(
                                letterSpacing: 3,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                              tooltip: 'Salin Kode',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: room.code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kode ruang berhasil disalin ke clipboard!'),
                                    backgroundColor: AppColors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                              tooltip: 'Bagikan Undangan',
                              onPressed: () {
                                SharePlus.instance.share(
                                  ShareParams(
                                    text: 'Yuk gabung sesi fokus kelompok "${room.name}" di KerKom!\nKode Ruang: ${room.code}\nLink: $meetingLink',
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // Link Meeting Card Row
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  meetingLink,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: meetingLink));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Link meeting disalin!'),
                                      backgroundColor: AppColors.green,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text('Salin', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Catatan jika ada
                        if (room.note?.isNotEmpty == true) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Catatan: ${room.note!}',
                                  style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'ANGGOTA DI DALAM RUANG',
                    style: AppTheme.labelSmall.copyWith(letterSpacing: 1.2, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),

                  // Realtime Members List
                  Expanded(
                    child: membersAsync.when(
                      data: (members) {
                        return ListView.separated(
                          itemCount: members.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final isMe = member.uid == currentUid;

                            return AppCard(
                              key: ValueKey(member.uid),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  AvatarCircle(
                                    name: member.name,
                                    photoUrl: member.photoUrl,
                                    size: 40,
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
                                                member.name + (isMe ? ' (Anda)' : ''),
                                                style: AppTheme.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          member.isHost ? 'Ketua Ruang' : 'Peserta',
                                          style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (member.isHost)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                                      ),
                                      child: const Text(
                                        '👑 Ketua Ruang',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    )
                                  else
                                    const StatusChip(label: 'Siap', color: StatusChipColor.green),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.red))),
                    ),
                  ),

                  const SizedBox(height: 16),
                  if (isHost && room.status == 'lobi') ...[
                    PrimaryButton(
                      text: 'Mulai Kalibrasi Bersama',
                      icon: const Icon(Icons.sensors_rounded, size: 20, color: AppColors.onPrimary),
                      onPressed: () async {
                        await ref.read(roomRepositoryProvider).startCalibration(roomId);
                      },
                    ),
                  ] else if (!isHost && room.status == 'lobi') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Menunggu host memulai...',
                            style: AppTheme.labelMedium.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ] else if (room.status == 'kalibrasi') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Kalibrasi sesi sedang berlangsung...',
                            style: AppTheme.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  DestructiveOutlineButton(
                    text: isHost ? 'Akhiri Ruangan' : 'Keluar dari Ruangan',
                    onPressed: () => _showEndRoomDialog(context, ref, isHost),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat informasi lobi...',
                    style: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat ruang: $err',
                    style: const TextStyle(color: AppColors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Kembali ke Beranda',
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
