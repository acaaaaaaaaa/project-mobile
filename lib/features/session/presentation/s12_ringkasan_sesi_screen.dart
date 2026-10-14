import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../room/presentation/room_controller.dart';
import 'session_controller.dart';

class TimelineEntry {
  final int timestamp;
  final String title;
  final String timeString;
  final bool isViolation;

  TimelineEntry({
    required this.timestamp,
    required this.title,
    required this.timeString,
    this.isViolation = false,
  });
}

class S12RingkasanSesiScreen extends ConsumerWidget {
  final String roomId;
  final bool readOnly;

  const S12RingkasanSesiScreen({
    super.key,
    required this.roomId,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider(roomId));
    final eventsAsync = ref.watch(roomEventsProvider(roomId));
    final membersAsync = ref.watch(roomMembersProvider(roomId));
    final userSessionsAsync = ref.watch(userSessionsProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final room = roomAsync.value;
    final events = eventsAsync.value ?? [];
    final members = membersAsync.value ?? [];

    // Fallback jika room sudah dibersihkan dari RTDB aktif
    final sessionRecord = userSessionsAsync.value?.where((s) => s.roomId == roomId).firstOrNull;

    final roomName = room?.name ?? sessionRecord?.roomName ?? 'Sesi Fokus Kelompok';
    final durationMin = room?.durationMinutes ?? sessionRecord?.durationDoneMin ?? 25;
    final totalViolations = events.isNotEmpty ? events.length : (sessionRecord?.violationCount ?? 0);

    final startMs = room?.startAt ?? sessionRecord?.startAt ?? (DateTime.now().millisecondsSinceEpoch - durationMin * 60 * 1000);
    final endMs = room?.endAt ?? (sessionRecord?.completedAt ?? (startMs + durationMin * 60 * 1000));

    // Susun timeline murni dari data riil
    final timelineEntries = <TimelineEntry>[];

    // 1. Sesi dimulai
    timelineEntries.add(
      TimelineEntry(
        timestamp: startMs,
        title: members.isNotEmpty
            ? 'Sesi dimulai bersama ${members.length} anggota'
            : 'Sesi fokus dimulai',
        timeString: DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(startMs)),
      ),
    );

    // 2. Anggota bergabung (jika join setelah sesi berjalan)
    for (final member in members) {
      if (member.joinedAt > (startMs + 5000)) {
        timelineEntries.add(
          TimelineEntry(
            timestamp: member.joinedAt,
            title: '${member.name} bergabung ke ruang',
            timeString: DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(member.joinedAt)),
          ),
        );
      }
    }

    // 3. Pelanggaran & Anggota Keluar dengan nama asli
    for (final event in events) {
      final violator = members.where((m) => m.uid == event.uid).firstOrNull;
      final violatorName = violator?.name ?? (event.uid == currentUid ? 'Kamu' : 'Anggota');

      if (event.type == 'keluar') {
        timelineEntries.add(
          TimelineEntry(
            timestamp: event.clientTs,
            title: '$violatorName meninggalkan ruangan',
            timeString: DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(event.clientTs)),
            isViolation: false,
          ),
        );
      } else {
        final delta = event.deltaTiltDeg > 0 ? ' (deviasi ${event.deltaTiltDeg.toStringAsFixed(1)}°)' : '';
        timelineEntries.add(
          TimelineEntry(
            timestamp: event.clientTs,
            title: '$violatorName mengangkat HP$delta',
            timeString: DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(event.clientTs)),
            isViolation: true,
          ),
        );
      }
    }

    // 4. Sesi selesai
    timelineEntries.add(
      TimelineEntry(
        timestamp: endMs,
        title: 'Sesi fokus $durationMin menit selesai',
        timeString: DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(endMs)),
      ),
    );

    // Urutkan timeline secara kronologis
    timelineEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final dateFormatted = DateFormat('d MMM yyyy • HH:mm').format(DateTime.fromMillisecondsSinceEpoch(startMs));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (readOnly) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          readOnly ? 'Detail Sesi Riwayat' : 'Ringkasan Sesi',
          style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Checkmark Badge & Session Finished Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded, color: AppColors.primary, size: 32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const StatusChip(label: 'SESI SELESAI', color: StatusChipColor.green),
                    const SizedBox(height: 8),
                    Text(
                      roomName,
                      style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatted,
                      style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Highlight Stat Cards (Durasi & Gangguan)
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Durasi', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$durationMin',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'menit',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('Target tercapai', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Gangguan', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Icon(Icons.screen_rotation_rounded, size: 16, color: AppColors.textMuted),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$totalViolations',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: totalViolations > 0 ? AppColors.amber : AppColors.green,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'kali',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('Total tim', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Anggota Kelompok Section (Real data from roomMembers)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'ANGGOTA KELOMPOK',
                        style: AppTheme.labelSmall.copyWith(letterSpacing: 1.0, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${members.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const Text('Kedisiplinan', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 10),

              if (members.isNotEmpty)
                Column(
                  children: members.map((member) {
                    final isMe = member.uid == currentUid;
                    final minutesAttended = ((endMs - member.joinedAt) / 60000).ceil().clamp(1, durationMin);
                    final isZeroGangguan = member.liftCount == 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            AvatarCircle(name: member.name, size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          member.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Kamu',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$minutesAttended menit fokus',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isZeroGangguan
                                    ? AppColors.green.withValues(alpha: 0.12)
                                    : AppColors.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isZeroGangguan ? AppColors.green : AppColors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${member.liftCount} gangguan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isZeroGangguan ? AppColors.green : AppColors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: const Center(
                    child: Text(
                      'Data anggota tercatat secara mandiri.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Kejadian Selama Sesi (Real Timeline)
              Text(
                'KEJADIAN SELAMA SESI',
                style: AppTheme.labelSmall.copyWith(letterSpacing: 1.0, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),

              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(timelineEntries.length, (index) {
                    final item = timelineEntries[index];
                    final isLast = index == timelineEntries.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline track with dot
                        Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.isViolation ? AppColors.red : AppColors.primary,
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 32,
                                color: AppColors.cardBorder,
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.timeString,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: item.isViolation ? AppColors.red : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Button (Only when not in read mode)
              if (!readOnly) ...[
                PrimaryButton(
                  text: 'Kembali ke Beranda',
                  onPressed: () => context.go('/home'),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
