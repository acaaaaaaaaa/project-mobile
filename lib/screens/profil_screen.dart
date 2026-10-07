import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/studypact_app_bar.dart';
import '../widgets/app_avatar.dart';

class ProfilScreen extends StatelessWidget {
  final VoidCallback onOpenHistory;

  const ProfilScreen({
    super.key,
    required this.onOpenHistory,
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
                subtitle: 'Profil Pengguna',
                onProfileTap: () {},
                onStreakTap: onOpenHistory,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const AppAvatar(
                            name: 'Farhan',
                            imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=160&q=80',
                            size: 72,
                            badge: CircleAvatar(
                              radius: 12,
                              backgroundColor: Color(0xFF047857),
                              child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Farhan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Tier 14 • Focus Master',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3 Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('7 Hari', 'Streak Aktif', '🔥'),
                              Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                              _buildStatItem('32.4 Jam', 'Waktu Fokus', '⏱'),
                              Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                              _buildStatItem('98.2%', 'Kepatuhan', '🛡'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Preferences & Sensor Settings
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pengaturan Sensor & Aplikasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            icon: Icons.speed_rounded,
                            iconColor: const Color(0xFF047857),
                            iconBg: const Color(0xFFDCFCE7),
                            title: 'Sensitivitas Sensor Gerak',
                            subtitle: 'Sedang (Toleransi 15°)',
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildSettingTile(
                            icon: Icons.volume_up_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFEFF6FF),
                            title: 'Alarm Audio Rekan Meja',
                            subtitle: 'Aktif saat terjadi distraksi',
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildSettingTile(
                            icon: Icons.groups_rounded,
                            iconColor: const Color(0xFF6366F1),
                            iconBg: const Color(0xFFEEF2FF),
                            title: 'Izin Undangan Mabar',
                            subtitle: 'Terima dari teman kontak',
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Study Group Info
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.school_rounded, color: Color(0xFF047857), size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Universitas Terbuka Komputasi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Mata Kuliah: Mobile & Wireless Computing',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildStatItem(String val, String label, String emoji) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              val,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
