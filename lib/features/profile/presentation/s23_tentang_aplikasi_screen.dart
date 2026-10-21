import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

class S23TentangAplikasiScreen extends StatelessWidget {
  const S23TentangAplikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Tentang Aplikasi',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header logo & branding
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x142463FF),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/kerkom_logo.png',
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.groups_rounded,
                          color: AppColors.primary,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'KerKom',
                      style: AppTheme.headlineMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Text(
                        'Versi 1.0.0 (Build 2026)',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aplikasi untuk membantu kerja kelompok yang lebih fokus dan produktif.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 0. Identitas Pengembang & Akademik
              _buildSectionCard(
                title: 'Identitas Pengembang',
                icon: Icons.school_rounded,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mata Kuliah & Dosen Info Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTheme.bodySmall.copyWith(color: AppColors.navy),
                                    children: const [
                                      TextSpan(text: 'Mata Kuliah: ', style: TextStyle(fontWeight: FontWeight.w800)),
                                      TextSpan(text: 'Manajemen Inovasi'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTheme.bodySmall.copyWith(color: AppColors.navy),
                                    children: const [
                                      TextSpan(text: 'Dosen Pengampu: ', style: TextStyle(fontWeight: FontWeight.w800)),
                                      TextSpan(text: "Dr. Siti Mas'ula, M.Pd."),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Tim Pengembang Header
                    Text(
                      'Tim Pengembang',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Anggota Tim List
                    ...[
                      'Putri Yuni Aqsyah',
                      'Muhammad Romadhoni Al Bukhori',
                      'Putu Alvin Mahendra Putra',
                    ].asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final name = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$idx',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 1. Fitur Utama (Direct reading, no redirect)
              _buildSectionCard(
                title: 'Fitur Utama',
                icon: Icons.star_outline_rounded,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _BulletItem(
                      title: 'Deteksi Kemiringan Fisik Real-time',
                      desc: 'Memanfaatkan sensor akselerometer perangkat untuk mendeteksi posisi ponsel di atas meja datar selama sesi kerja kelompok.',
                    ),
                    SizedBox(height: 10),
                    _BulletItem(
                      title: 'Alarm Kedisiplinan Terkoordinasi',
                      desc: 'Memicu alarm audio dan getaran langsung jika ada anggota yang mengambil atau memainkan ponsel di tengah sesi.',
                    ),
                    SizedBox(height: 10),
                    _BulletItem(
                      title: 'Manajemen Ruang & Kalender',
                      desc: 'Jadwalkan kegiatan kerja kelompok, buat kode ruang unik 6 digit, bagikan tautan meeting, dan sinkronkan dengan kalender.',
                    ),
                    SizedBox(height: 10),
                    _BulletItem(
                      title: 'Statistik & Riwayat Sesi',
                      desc: 'Catatan komprehensif riwayat belajar bersama dengan durasi, daftar anggota, dan rekaman kedisiplinan fokus.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Kebijakan Privasi
              _buildSectionCard(
                title: 'Kebijakan Privasi',
                icon: Icons.shield_outlined,
                content: Text(
                  'KerKom menghargai privasi Anda sepenuhnya. Data sensor orientasi perangkat hanya diproses secara lokal pada perangkat Anda selama sesi fokus aktif berlangsung. Kami tidak pernah merekam isi layar, mikrofon, kamera, maupun data pribadi di luar informasi akun yang Anda daftarkan secara sukarela. Data sesi dan profil disimpan secara aman pada Firebase Database yang terenkripsi.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Syarat & Ketentuan
              _buildSectionCard(
                title: 'Syarat & Ketentuan',
                icon: Icons.description_outlined,
                content: Text(
                  'Dengan menggunakan KerKom, Anda setuju untuk menggunakan aplikasi ini demi tujuan produktivitas belajar kelompok yang positif. Setiap anggota bertanggung jawab atas partisipasi dan kepatuhan dalam sesi kerja kelompok. KerKom tidak bertanggung jawab atas kegagalan sistem akibat perangkat pihak ketiga yang mematikan layanan latar belakang secara paksa.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Lisensi Open Source
              _buildSectionCard(
                title: 'Lisensi Open Source',
                icon: Icons.code_rounded,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KerKom dikembangkan menggunakan framework Flutter dan teknologi open source terkemuka di bawah lisensi MIT, Apache 2.0, dan BSD-3-Clause.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Komponen utama: Flutter Framework, Firebase Core & Auth, Riverpod State Management, Wakelock Plus, Vibration & AudioPlayers.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  '© 2026 KerKom Team. Hak Cipta Dilindungi.',
                  style: AppTheme.labelSmall.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String title;
  final String desc;

  const _BulletItem({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
