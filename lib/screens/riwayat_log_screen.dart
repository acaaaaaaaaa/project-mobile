import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/studypact_app_bar.dart';
import '../widgets/app_avatar.dart';

class RiwayatLogScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;
  final VoidCallback? onOpenProfile;

  const RiwayatLogScreen({
    super.key,
    this.onBackToHome,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudyPactAppBar(
                subtitle: 'Riwayat & Log',
                onProfileTap: onOpenProfile,
                onStreakTap: () {},
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Success Badge Card
                    _buildSuccessHeaderCard(),
                    const SizedBox(height: 18),

                    // Rincian Hadiah XP Card
                    _buildXpRewardsCard(),
                    const SizedBox(height: 20),

                    // Papan Peringkat Sesi (Hasil Komitmen Tim)
                    _buildLeaderboardSection(),
                    const SizedBox(height: 20),

                    // Buku Tamu Sistem (Audit Trail Sensor)
                    _buildAuditTrailSection(),
                    const SizedBox(height: 24),

                    // Bottom Buttons
                    _buildActionButtons(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeaderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Medal Icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDCFCE7),
              border: Border.all(color: const Color(0xFF86EFAC), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.military_tech_rounded,
                color: Color(0xFF047857),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Pill Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF065F46), size: 7),
                SizedBox(width: 5),
                Text(
                  'SESI SUKSES PENUH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF064E3B),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Title & Subtitle
          const Text(
            'Tugas Akhir HCI',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Kelompok 4 • Ruang Fokus Terkunci',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // 2 Stats Capsules
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Color(0xFF047857), size: 18),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Durasi Sesi',
                            style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '45 Menit',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF047857), size: 18),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stabilitas Meja',
                            style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '100% Valid',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXpRewardsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PEROLEHAN PENGALAMAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Rincian Hadiah XP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '+60',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF047857),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF047857),
                        ),
                      ),
                      Text(
                        'XP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF047857).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Item 1: Fokus Dasar
          _buildRewardItem(
            icon: Icons.timer_rounded,
            iconBg: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF6366F1),
            title: 'Fokus Dasar (1XP / 1m)',
            subtitle: '45 menit mode senyap kaku',
            amount: '+45  XP',
            amountColor: AppTheme.textPrimary,
          ),
          const SizedBox(height: 10),

          // Item 2: Teamwork Integrity Bonus
          _buildRewardItem(
            icon: Icons.verified_user_rounded,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF10B981),
            title: 'Teamwork Integrity Bonus',
            subtitle: 'Semua peserta lolos tanpa pelanggaran',
            amount: '+15  XP',
            amountColor: const Color(0xFF047857),
          ),
          const SizedBox(height: 10),

          // Item 3: Penalti Gerakan / Angkat
          _buildRewardItem(
            icon: Icons.stay_current_portrait_rounded,
            iconBg: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF64748B),
            title: 'Penalti Gerakan / Angkat',
            subtitle: 'Sensor gyro & akselerometer bersih',
            amount: '0  XP',
            amountColor: AppTheme.textMuted,
          ),
          const SizedBox(height: 14),

          // Streak Card (+1 Hari)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFB923C),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '8 Hari Beruntun!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '+1 HARI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Pact harian berikutnya siap besok pukul 09:00',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9A3412)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAPAN PERINGKAT SESI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hasil Komitmen Tim',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '4 Peserta',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Rank 1: Farhan ANDA
        _buildLeaderTile(
          rank: 1,
          name: 'Farhan',
          tag: 'ANDA',
          tagColor: const Color(0xFF4F46E5),
          tagBg: const Color(0xFFEEF2FF),
          subtitle: '45 Menit • Meja 0.0° Flat',
          xp: '+60  XP',
          statusBadge: '100% Disiplin',
          statusBadgeBg: const Color(0xFFDCFCE7),
          statusBadgeText: const Color(0xFF15803D),
          imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=120&q=80',
        ),
        const SizedBox(height: 8),

        // Rank 2: Rizky Ramadhan HOST
        _buildLeaderTile(
          rank: 2,
          name: 'Rizky Ramadhan',
          tag: 'HOST',
          tagColor: const Color(0xFF0284C7),
          tagBg: const Color(0xFFE0F2FE),
          subtitle: '45 Menit • 0 Gangguan',
          xp: '+60  XP',
          statusBadge: '100% Disiplin',
          statusBadgeBg: const Color(0xFFDCFCE7),
          statusBadgeText: const Color(0xFF15803D),
          imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&q=80',
        ),
        const SizedBox(height: 8),

        // Rank 3: Nabila Putri
        _buildLeaderTile(
          rank: 3,
          name: 'Nabila Putri',
          subtitle: '45 Menit • Mode Belajar',
          xp: '+60  XP',
          statusBadge: '100% Disiplin',
          statusBadgeBg: const Color(0xFFDCFCE7),
          statusBadgeText: const Color(0xFF15803D),
          imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&q=80',
        ),
        const SizedBox(height: 8),

        // Rank 4: Budi Santoso LATE
        _buildLeaderTile(
          rank: 4,
          name: 'Budi Santoso',
          tag: 'LATE',
          tagColor: const Color(0xFFD97706),
          tagBg: const Color(0xFFFEF3C7),
          subtitle: '33 Menit • Sync Gelombang 2',
          xp: '+33  XP',
          statusBadge: 'Tepat Sasaran',
          statusBadgeBg: const Color(0xFFF1F5F9),
          statusBadgeText: const Color(0xFF475569),
          imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&q=80',
        ),
      ],
    );
  }

  Widget _buildLeaderTile({
    required int rank,
    required String name,
    String? tag,
    Color? tagColor,
    Color? tagBg,
    required String subtitle,
    required String xp,
    required String statusBadge,
    required Color statusBadgeBg,
    required Color statusBadgeText,
    String? imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          // Avatar with rank circle
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(name: name, imageUrl: imageUrl, size: 40),
              Positioned(
                left: -3,
                bottom: -3,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: rank == 1 ? const Color(0xFF047857) : const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: tagColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                xp,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBadgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusBadge,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusBadgeText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buku Tamu Sistem',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Audit trail sensor & kehadiran presisi',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SYNC-OK',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Timeline Logs
          _buildTimelineItem(
            time: '14:00:00',
            tag: 'INISIASI HOST',
            tagColor: const Color(0xFF4F46E5),
            dotColor: const Color(0xFF4F46E5),
            desc: 'Sesi kelompok dibuka oleh Rizky Ramadhan. Kuota 4/4 terisi, protokol hening aktif.',
            isLast: false,
          ),
          _buildTimelineItem(
            time: '14:00:14',
            tag: 'SENSOR TERKUNCI',
            tagColor: const Color(0xFF047857),
            dotColor: const Color(0xFF047857),
            desc: 'Farhan (Anda) berhasil kalibrasi titik nol (0.0° tilt). Akselerometer meja siaga penuh.',
            isLast: false,
          ),
          _buildTimelineItem(
            time: '14:00:30',
            tag: 'KONEKSI MASUK',
            tagColor: const Color(0xFF047857),
            dotColor: const Color(0xFF047857),
            desc: 'Nabila Putri terhubung sinkron. Mode Belajar: Aktif, tidak terdeteksi aplikasi terlarang dibuka.',
            isLast: false,
          ),
          _buildTimelineItem(
            time: '14:12:05',
            tag: 'GELOMBANG MASUK',
            tagColor: const Color(0xFFD97706),
            dotColor: const Color(0xFFD97706),
            desc: 'Budi Santoso bergabung via Waiting Room (Terlambat +12m). Lulus tes hening mandiri 15 detik.',
            isLast: false,
          ),
          _buildTimelineItem(
            time: '14:31:42',
            tag: 'JARINGAN PULIH',
            tagColor: const Color(0xFF0284C7),
            dotColor: const Color(0xFF0284C7),
            desc: 'Budi Santoso: Sinyal terputus sesaat (Reconnecting 35s). Status sensor offline dinyatakan aman tanpa perubahan sudut.',
            isLast: false,
          ),
          _buildTimelineItem(
            time: '14:45:00',
            tag: 'SELESAI FINAL',
            tagColor: const Color(0xFF047857),
            dotColor: const Color(0xFF047857),
            desc: 'Timer sesi 45 menit tuntas secara serentak. Tingkat pelanggaran gerak tim: 0 insiden.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String tag,
    required Color tagColor,
    required Color dotColor,
    required String desc,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line & dot
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: tagColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Dark Button: Kembali ke Beranda
        ElevatedButton.icon(
          onPressed: onBackToHome ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
          label: const Text(
            'Kembali ke Beranda',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E2238),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 2,
          ),
        ),
        const SizedBox(height: 10),

        // Secondary Button: Bagikan Hasil
        ElevatedButton.icon(
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(
                text: '🎉 Sesi Belajar Tugas Akhir HCI Kelompok 4 sukses penuh!\n'
                    'Total waktu: 45 Menit | Stabilitas Meja: 100% Valid | +60 XP diperoleh.\n'
                    'Dibuat dengan aplikasi StudyPact.',
              ),
            );
          },
          icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF4F46E5)),
          label: const Text(
            'Bagikan Hasil Sesi ke WhatsApp / Grup',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4F46E5),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEEF2FF),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
