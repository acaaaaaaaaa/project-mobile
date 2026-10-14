import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../session/domain/session_models.dart';
import '../../session/presentation/session_controller.dart';

class S13RiwayatScreen extends ConsumerStatefulWidget {
  const S13RiwayatScreen({super.key});

  @override
  ConsumerState<S13RiwayatScreen> createState() => _S13RiwayatScreenState();
}

class _S13RiwayatScreenState extends ConsumerState<S13RiwayatScreen> {
  // 0: Semua, 1: Ruang Dibuat, 2: Ruang Diikuti
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(userSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo K & KerKom di kiri, Notifikasi di kanan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/kerkom_logo.png',
                        width: 36,
                        height: 36,
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
                    onTap: () => context.push('/notifications'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 22),
                          Positioned(
                            top: 9,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
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
            ),

            // Judul Riwayat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Riwayat',
                  style: AppTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3 Filter Tabs: [Semua] [Ruang Dibuat] [Ruang Diikuti]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildFilterTab('Semua', 0),
                    _buildFilterTab('Ruang Dibuat', 1),
                    _buildFilterTab('Ruang Diikuti', 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Daftar Riwayat
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  final filtered = _filterSessions(sessions);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada riwayat sesi',
                        style: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                    );
                  }

                  return _buildGroupedSessionList(filtered);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Belum ada riwayat sesi',
                    style: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, int index) {
    final isSelected = _selectedFilter == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  List<UserSessionRecord> _filterSessions(List<UserSessionRecord> all) {
    if (_selectedFilter == 1) {
      // Ruang Dibuat saja
      return all.where((s) => s.isCreatedByMe).toList();
    } else if (_selectedFilter == 2) {
      // Ruang Diikuti saja
      return all.where((s) => !s.isCreatedByMe).toList();
    }
    return all;
  }

  String _formatSessionTime(int startAt, int completedAt, int durationMin) {
    if (startAt <= 0) return '$durationMin menit';
    final startDt = DateTime.fromMillisecondsSinceEpoch(startAt);
    final endDt = completedAt > startAt
        ? DateTime.fromMillisecondsSinceEpoch(completedAt)
        : startDt.add(Duration(minutes: durationMin > 0 ? durationMin : 45));
    final startStr = '${startDt.hour.toString().padLeft(2, '0')}:${startDt.minute.toString().padLeft(2, '0')}';
    final endStr = '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr • $durationMin menit';
  }

  String _getDateHeader(int startAt) {
    if (startAt <= 0) return 'Riwayat Sesi';
    final dt = DateTime.fromMillisecondsSinceEpoch(startAt);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(sessionDay).inDays;

    if (diffDays == 0) return 'Hari ini';
    if (diffDays == 1) return 'Kemarin';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildGroupedSessionList(List<UserSessionRecord> sessions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final currentHeader = _getDateHeader(session.startAt);
        final prevHeader = index > 0 ? _getDateHeader(sessions[index - 1].startAt) : null;
        final showHeader = index == 0 || currentHeader != prevHeader;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  currentHeader,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                borderRadius: 18,
                onTap: () => context.push('/history-detail/${session.roomId}', extra: session),
                child: Row(
                  children: [
                    // Icon Box
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getSessionIconBg(index),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getSessionIcon(index),
                        color: _getSessionIconColor(index),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Detail Sesi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.roomName,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatSessionTime(session.startAt, session.completedAt, session.durationDoneMin),
                            style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${session.memberCount} Anggota • ${session.isCreatedByMe ? 'Dibuat Saya' : 'Diikuti'}',
                            style: AppTheme.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge & Arrow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: session.status == 'Dibatalkan' ? AppColors.redSoft : AppColors.greenSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            session.status,
                            style: AppTheme.labelSmall.copyWith(
                              color: session.status == 'Dibatalkan' ? AppColors.red : AppColors.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getSessionIconBg(int index) {
    const bgs = [Color(0xFFEFF6FF), Color(0xFFEBF3FE), Color(0xFFF3E8FF), Color(0xFFFEF3C7), Color(0xFFFEE2E2)];
    return bgs[index % bgs.length];
  }

  Color _getSessionIconColor(int index) {
    const colors = [AppColors.primary, Color(0xFF0284C7), Color(0xFF8B5CF6), Color(0xFFD97706), AppColors.red];
    return colors[index % colors.length];
  }

  IconData _getSessionIcon(int index) {
    const icons = [Icons.videocam_rounded, Icons.folder_rounded, Icons.bar_chart_rounded, Icons.bookmark_rounded, Icons.edit_note_rounded];
    return icons[index % icons.length];
  }
}
