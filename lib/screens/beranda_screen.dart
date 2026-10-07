import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/studypact_app_bar.dart';
import '../widgets/app_avatar.dart';

class BerandaScreen extends StatelessWidget {
  final VoidCallback onOpenLobby;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinCode;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;

  const BerandaScreen({
    super.key,
    required this.onOpenLobby,
    required this.onCreateRoom,
    required this.onJoinCode,
    required this.onOpenHistory,
    required this.onOpenProfile,
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
                subtitle: 'Beranda',
                onProfileTap: onOpenProfile,
                onStreakTap: onOpenHistory,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting & Status Pill
                    _buildGreetingHeader(),
                    const SizedBox(height: 18),

                    // Level & Streak Card
                    _buildLevelProgressCard(),
                    const SizedBox(height: 18),

                    // Study Invitation Card (Undangan Mabar Study)
                    _buildInvitationCard(context),
                    const SizedBox(height: 18),

                    // Action Grid (Buat Ruang & Gabung Kode)
                    _buildActionGrid(context),
                    const SizedBox(height: 20),

                    // Kalender Fokus
                    _buildCalendarCard(),
                    const SizedBox(height: 22),

                    // Teman Belajar Aktif
                    _buildActiveFriendsSection(context),
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

  Widget _buildGreetingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Halo, Farhan!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(width: 6),
                Text('👋', style: TextStyle(fontSize: 20)),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Siap kunci distraksi hari ini?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6EE7B7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFF065F46), size: 7),
              SizedBox(width: 5),
              Text(
                'SIAP SESI',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF064E3B),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgressCard() {
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Center(
                  child: Text(
                    '14',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Master',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Target berikutnya: Tier 15 Architect',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, color: Color(0xFF15803D), size: 14),
                    SizedBox(width: 4),
                    Text(
                      '+45 XP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'kemarin',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '840  XP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF312E81),
                ),
              ),
              Text(
                '1.000 XP (160 XP lagi)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              color: const Color(0xFFE2E8F0),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.84,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4), Color(0xFF10B981)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7 Hari Beruntun!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Target mingguan: 5/7 hari aktif',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(7, (index) {
                    final isFilled = index < 5;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 5,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isFilled ? const Color(0xFF047857) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2238),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Pill & Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline_rounded, size: 12, color: Color(0xFF92400E)),
                    SizedBox(width: 4),
                    Text(
                      'UNDANGAN MABAR STUDY',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                  SizedBox(width: 4),
                  Text(
                    '02:41',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Host & Title Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppAvatar(
                name: 'Rizky Ramadhan',
                imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&q=80',
                size: 46,
                badge: Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tugas Akhir HCI – Kelompok 4',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Host: Rizky Ramadhan • Sesi Ketat (Sensor Nyala)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded, size: 13, color: Color(0xFF6EE7B7)),
                        const SizedBox(width: 4),
                        const Text(
                          '45 Mnt Standar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6EE7B7),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFF64748B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(Icons.group_rounded, size: 13, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 4),
                        const Text(
                          '4/5 Anggota Ready',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Member Avatars Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 28,
                  width: 80,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: _avatarMini('Farhan', const Color(0xFF6366F1)),
                      ),
                      Positioned(
                        left: 18,
                        child: _avatarMini('Nabila', const Color(0xFFEC4899)),
                      ),
                      Positioned(
                        left: 36,
                        child: _avatarMini('Dimas', const Color(0xFFF59E0B)),
                      ),
                      Positioned(
                        left: 54,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4F46E5),
                            border: Border.all(color: const Color(0xFF1E2238), width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              '+1',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Slot tersisa: 1 Orang',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Buttons: Tolak & Terima
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Undangan mabar ditolak.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF333854),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Tolak',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: onOpenLobby,
                  icon: const Icon(Icons.lock_rounded, size: 15, color: Colors.white),
                  label: const Text(
                    'Terima & Masuk Lobi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarMini(String name, Color bg) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: const Color(0xFF1E2238), width: 1.5),
      ),
      child: Center(
        child: Text(
          name[0],
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Row(
      children: [
        // Buat Ruang Card
        Expanded(
          child: GestureDetector(
            onTap: onCreateRoom,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_box_outlined, color: Color(0xFF6366F1), size: 22),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Buat Ruang',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Atur durasi & undang rekan tim',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Text(
                        'Mulai Instan',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Gabung Kode Card
        Expanded(
          child: GestureDetector(
            onTap: onJoinCode,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pin_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gabung Kode',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Contoh: PACT-8821',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Text(
                        'Input PIN',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.mark_email_unread_outlined, size: 14, color: Color(0xFF0284C7)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
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
            children: [
              const Icon(Icons.calendar_month_outlined, color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Kalender Fokus • April 2025',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Aktif 22/30 Hari',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats inside calendar box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Total Jam Fokus',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '32.4 Jam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 24,
                  child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 1),
                ),
                Column(
                  children: [
                    Text(
                      'Kepatuhan Sensor',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '98.2%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Days Header (S S R K J S M)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CalendarDayHeader('S'),
              _CalendarDayHeader('S'),
              _CalendarDayHeader('R'),
              _CalendarDayHeader('K'),
              _CalendarDayHeader('J'),
              _CalendarDayHeader('S'),
              _CalendarDayHeader('M'),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar Days Grid
          _buildCalendarGrid(),
          const SizedBox(height: 14),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF047857), '>60 mnt'),
              const SizedBox(width: 14),
              _buildLegendItem(const Color(0xFF6EE7B7), '25–45 mnt'),
              const SizedBox(width: 14),
              _buildLegendItem(const Color(0xFFE2E8F0), 'Istirahat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // 4 rows of 7 days
    final gridData = [
      // Row 1
      {'day': '30', 'type': 'off'},
      {'day': '1', 'type': 'med'},
      {'day': '2', 'type': 'high'},
      {'day': '3', 'type': 'high'},
      {'day': '4', 'type': 'med'},
      {'day': '5', 'type': 'off'},
      {'day': '6', 'type': 'off'},
      // Row 2
      {'day': '7', 'type': 'med'},
      {'day': '8', 'type': 'high'},
      {'day': '9', 'type': 'high'},
      {'day': '10', 'type': 'high'},
      {'day': '11', 'type': 'med'},
      {'day': '12', 'type': 'high'},
      {'day': '13', 'type': 'off'},
      // Row 3
      {'day': '14', 'type': 'high'},
      {'day': '15', 'type': 'med'},
      {'day': '16', 'type': 'high'},
      {'day': '17', 'type': 'high'},
      {'day': '18', 'type': 'high'},
      {'day': '19', 'type': 'med'},
      {'day': '20', 'type': 'off'},
      // Row 4
      {'day': '21', 'type': 'high'},
      {'day': '22', 'type': 'high'},
      {'day': '23', 'type': 'med'},
      {'day': '24', 'type': 'today'}, // Current day highlighted
      {'day': '25', 'type': 'off'},
      {'day': '26', 'type': 'off'},
      {'day': '27', 'type': 'off'},
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.spaceBetween,
      children: gridData.map((item) {
        final day = item['day']!;
        final type = item['type']!;

        Color bg;
        Color textColor = AppTheme.textPrimary;
        Border? border;

        switch (type) {
          case 'high':
            bg = const Color(0xFF047857); // Dark green
            textColor = Colors.white;
            break;
          case 'med':
            bg = const Color(0xFF6EE7B7); // Light green
            textColor = const Color(0xFF064E3B);
            break;
          case 'today':
            bg = const Color(0xFF6EE7B7);
            textColor = const Color(0xFF064E3B);
            border = Border.all(color: const Color(0xFF1E1B4B), width: 1.8);
            break;
          case 'off':
          default:
            bg = const Color(0xFFF1F5F9);
            textColor = const Color(0xFF94A3B8);
            break;
        }

        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: border,
          ),
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: type == 'off' ? FontWeight.w500 : FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFriendsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.people_alt_rounded, size: 18, color: AppTheme.textPrimary),
                SizedBox(width: 8),
                Text(
                  'Teman Belajar Aktif',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: const Text(
                'Lihat Semua (8)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Friend 1: Rizky Ramadhan
        _buildFriendTile(
          context,
          name: 'Rizky Ramadhan',
          status: 'Online • Siap Mabar',
          statusColor: const Color(0xFF10B981),
          imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&q=80',
          trailingWidget: _buildAjakButton(context, 'Rizky Ramadhan'),
        ),
        const SizedBox(height: 10),

        // Friend 2: Nabila Putri
        _buildFriendTile(
          context,
          name: 'Nabila Putri',
          status: 'Sedang Fokus • 18m tersisa',
          statusColor: const Color(0xFFF59E0B),
          isLocked: true,
          imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&q=80',
          trailingWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_bottom_rounded, size: 13, color: Color(0xFF475569)),
                SizedBox(width: 4),
                Text(
                  '18:24',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Friend 3: Dimas Arya
        _buildFriendTile(
          context,
          name: 'Dimas Arya',
          status: 'Online • Idle',
          statusColor: const Color(0xFF10B981),
          imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&q=80',
          trailingWidget: _buildAjakButton(context, 'Dimas Arya'),
        ),
      ],
    );
  }

  Widget _buildFriendTile(
    BuildContext context, {
    required String name,
    required String status,
    required Color statusColor,
    required Widget trailingWidget,
    String? imageUrl,
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AppAvatar(
            name: name,
            imageUrl: imageUrl,
            size: 42,
            badge: Icon(Icons.circle, color: statusColor, size: 9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (isLocked) ...[
                      const Icon(Icons.lock_outline_rounded, size: 11, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isLocked ? const Color(0xFFD97706) : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailingWidget,
        ],
      ),
    );
  }

  Widget _buildAjakButton(BuildContext context, String friendName) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Undangan mabar terkirim ke $friendName!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      icon: const Icon(Icons.play_arrow_rounded, size: 14, color: Color(0xFF4F46E5)),
      label: const Text(
        'Ajak',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4F46E5),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEEF2FF),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _CalendarDayHeader extends StatelessWidget {
  final String label;
  const _CalendarDayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
      ),
    );
  }
}
