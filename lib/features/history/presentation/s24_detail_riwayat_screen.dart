import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/auth_controller.dart';
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

    final session = userSessionsAsync.valueOrNull?.where((s) => s.roomId == roomId).firstOrNull ??
        initialRecord ??
        UserSessionRecord(
          roomId: roomId,
          roomName: 'Tugas Akhir HCI Kelompok 4',
          startAt: DateTime(2026, 10, 10, 14, 0).millisecondsSinceEpoch,
          completedAt: DateTime(2026, 10, 10, 14, 45).millisecondsSinceEpoch,
          durationDoneMin: 45,
          violationCount: 0,
          endedHow: 'host',
          roomCode: 'K7M2Q9',
          isCreatedByMe: true,
          status: 'Selesai',
          memberCount: 4,
          note: 'Diskusi progress tugas dan pembagian role.',
          meetingLink: 'https://zoom.us/j/123456789',
        );

    final roomCode = session.roomCode?.isNotEmpty == true ? session.roomCode! : 'K7M2Q9';
    final meetingLink = session.meetingLink?.isNotEmpty == true
        ? session.meetingLink!
        : 'https://kerkom.app/j/$roomCode';
    final note = session.note?.isNotEmpty == true
        ? session.note!
        : 'Diskusi progress tugas dan pembagian role.';

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
                    '10 Okt 2026  14:00 - 14:45 • ${session.durationDoneMin} menit',
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
                  Text(
                    'Anggota (${session.memberCount})',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMemberAvatar('F', AppColors.primary),
                      const SizedBox(width: 8),
                      _buildMemberAvatar('R', AppColors.navy),
                      const SizedBox(width: 8),
                      _buildMemberAvatar('A', const Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '+1',
                            style: AppTheme.labelSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildMemberAvatar(String initial, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
