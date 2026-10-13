import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../monitoring/presentation/monitoring_providers.dart';
import 'session_controller.dart';

class S10AlarmPelanggarScreen extends ConsumerStatefulWidget {
  final String roomId;

  const S10AlarmPelanggarScreen({super.key, required this.roomId});

  @override
  ConsumerState<S10AlarmPelanggarScreen> createState() => _S10AlarmPelanggarScreenState();
}

class _S10AlarmPelanggarScreenState extends ConsumerState<S10AlarmPelanggarScreen> {
  @override
  void dispose() {
    // Pastikan alarm audio & getar berhenti saat layar ditutup
    ref.read(alarmServiceProvider).stop();
    super.dispose();
  }

  void _onRecalibrate() {
    ref.read(alarmServiceProvider).stop();
    // 5. Kembali ke S08 untuk kalibrasi ulang (3 detik di atas meja), lalu kembali ke ARMED & S09
    context.go('/calibration/${widget.roomId}');
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(monitorSnapshotProvider).value;
    final currentTilt = snapshot?.deltaTilt ?? 28.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1B0A0C), // Deep crimson alert background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Alert Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.red),
                        SizedBox(width: 6),
                        Text(
                          'ALARM AKTIF',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Timer Tetap Berjalan',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),

              // Central Pulsing Beacon
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.red.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.red.withValues(alpha: 0.25),
                        ),
                        child: const Icon(
                          Icons.screen_rotation,
                          size: 48,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Kamu mengangkat HP!',
                    style: AppTheme.headlineLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Teman sekelompokmu sudah diberi tahu.\nTimer fokus kelompok tetap berjalan.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Telemetry Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMetricCard(
                        'Sudut Terdeteksi',
                        '${currentTilt.toStringAsFixed(0)}°',
                        isAlert: true,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard('Batas Toleransi', '15°'),
                    ],
                  ),
                ],
              ),

              // Bottom Actions
              Column(
                children: [
                  PrimaryButton(
                    text: 'Taruh HP & Kalibrasi Ulang',
                    icon: const Icon(Icons.sync_rounded, size: 20, color: AppColors.onPrimary),
                    onPressed: _onRecalibrate,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sensor akan diverifikasi kembali selama 3 detik di atas meja datar.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, {bool isAlert = false}) {
    return Container(
      width: 135,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? AppColors.red.withValues(alpha: 0.4) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isAlert ? AppColors.red : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
