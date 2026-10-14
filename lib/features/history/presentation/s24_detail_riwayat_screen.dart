import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../room/presentation/room_controller.dart';
import '../../session/domain/session_models.dart';
import '../../session/presentation/session_controller.dart';

class S24DetailRiwayatScreen extends ConsumerWidget {
  final String roomId;
  final UserSessionRecord? initialRecord;

  const S24DetailRiwayatScreen({
    super.key,
    required this.roomId,
    this.initialRecord,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin!'),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String currentUid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus dari Riwayat?',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
          ),
        ),
        content: Text(
          'Sesi ini akan dihapus secara permanen dari daftar riwayat belajar Anda.',
          style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(sessionRepositoryProvider);
              await repo.deleteUserSession(currentUid, roomId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sesi berhasil dihapus dari riwayat.'),
                    backgroundColor: AppColors.navy,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSessionsAsync = ref.watch(userSessionsProvider);
    final currentUid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
    final roomLive = ref.watch(roomProvider(roomId)).valueOrNull;
    final membersAsync = ref.watch(roomMembersProvider(roomId));

    final session = userSessionsAsync.valueOrNull?.where((s) => s.roomId == roomId).firstOrNull ??
        initialRecord ??
        UserSessionRecord(
          roomId: roomId,
          roomName: roomLive?.name ?? 'Sesi Belajar',
          startAt: roomLive?.startAt ?? DateTime.now().millisecondsSinceEpoch,
          completedAt: DateTime.now().millisecondsSinceEpoch,
          durationDoneMin: roomLive?.durationMinutes ?? 45,
          violationCount: 0,
          endedHow: 'host',
          roomCode: roomLive?.code ?? '-',
          isCreatedByMe: roomLive?.hostUid == currentUid,
          status: 'Selesai',
          memberCount: 1,
          note: roomLive?.note,
          meetingLink: roomLive?.code != null ? 'https://kerkom.app/j/${roomLive!.code}' : null,
        );

    final roomCode = (session.roomCode?.isNotEmpty == true)
        ? session.roomCode!
        : (roomLive?.code ?? '-');
    final meetingLink = (session.meetingLink?.isNotEmpty == true)
        ? session.meetingLink!
        : (roomCode != '-' ? 'https://kerkom.app/j/$roomCode' : 'https://kerkom.app');
    final note = (session.note?.isNotEmpty == true)
        ? session.note!
        : (roomLive?.note?.isNotEmpty == true
            ? roomLive!.note!
            : 'Tidak ada catatan tambahan untuk ruangan ini.');

    final formattedDateTime = _formatFullDateTime(session.startAt, session.completedAt, session.durationDoneMin);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Detail Riwayat',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Card
            AppCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    session.roomName,
                    style: AppTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: session.status == 'Dibatalkan' ? AppColors.redSoft : AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: session.status == 'Dibatalkan' ? AppColors.red : AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          session.status,
                          style: AppTheme.labelSmall.copyWith(
                            color: session.status == 'Dibatalkan' ? AppColors.red : AppColors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    formattedDateTime,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Anggota Card
            AppCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Anggota',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      membersAsync.when(
                        data: (m) => Text(
                          '${m.length} orang',
                          style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  membersAsync.when(
                    data: (members) {
                      if (members.isEmpty) {
                        return Text(
                          'Data anggota tidak tersedia',
                          style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
                        );
                      }
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: members.map((member) {
                          final isMe = member.uid == currentUid;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AvatarCircle(name: member.name, photoUrl: member.photoUrl, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  member.name + (isMe ? ' (Kamu)' : ''),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy),
                                ),
                                if (member.isHost) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '👑 Ketua',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 38,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (err, stack) => Text(
                      '${session.memberCount} Anggota',
                      style: AppTheme.bodyMedium.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Kode Ruang Card
            AppCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.key_rounded, color: AppColors.navy, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kode Ruang', style: AppTheme.labelSmall.copyWith(color: AppColors.textMuted)),
                        Text(
                          roomCode,
                          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                    onPressed: () => _copyToClipboard(context, roomCode, 'Kode ruang'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Link Meeting Card
            AppCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.link_rounded, color: AppColors.navy, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Link Meeting', style: AppTheme.labelSmall.copyWith(color: AppColors.textMuted)),
                        Text(
                          meetingLink,
                          style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                    onPressed: () => _copyToClipboard(context, meetingLink, 'Link meeting'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Catatan Card
            AppCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notes_rounded, color: AppColors.navy, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Catatan', style: AppTheme.labelSmall.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          note,
                          style: AppTheme.bodyMedium.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Hapus dari Riwayat
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, ref, currentUid),
              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.red, size: 18),
              label: const Text('Hapus dari Riwayat', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.red)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.red.withValues(alpha: 0.4), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatFullDateTime(int? startAt, int? completedAt, int durationMinutes) {
    if (startAt == null || startAt == 0) return 'Jadwal fleksibel';
    final startDt = DateTime.fromMillisecondsSinceEpoch(startAt);
    final endDt = (completedAt != null && completedAt > 0)
        ? DateTime.fromMillisecondsSinceEpoch(completedAt)
        : startDt.add(Duration(minutes: durationMinutes));
    try {
      final dateStr = DateFormat('d MMMM yyyy').format(startDt);
      final startStr = DateFormat('HH:mm').format(startDt);
      final endStr = DateFormat('HH:mm').format(endDt);
      return '$dateStr • $startStr - $endStr WIB';
    } catch (_) {
      final startStr = DateFormat('HH:mm').format(startDt);
      final endStr = DateFormat('HH:mm').format(endDt);
      return '$startStr - $endStr WIB';
    }
  }
}
