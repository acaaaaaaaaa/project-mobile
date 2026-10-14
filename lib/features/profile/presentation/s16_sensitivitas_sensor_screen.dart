import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../monitoring/domain/monitor_config.dart';
import '../../monitoring/domain/monitor_controller.dart';
import '../../monitoring/presentation/monitoring_providers.dart';
import '../../sensor/presentation/s19_sheet_izin_pemantauan.dart';

class S16SensitivitasSensorScreen extends ConsumerStatefulWidget {
  const S16SensitivitasSensorScreen({super.key});

  @override
  ConsumerState<S16SensitivitasSensorScreen> createState() => _S16SensitivitasSensorScreenState();
}

class _S16SensitivitasSensorScreenState extends ConsumerState<S16SensitivitasSensorScreen> {
  double _tiltToleranceDeg = 15.0;
  bool _isInitializedFromUser = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMonitoring();
    });
  }

  void _startMonitoring() {
    final controller = ref.read(monitorControllerProvider);
    final sampler = ref.read(samplerProvider);

    // Awali dengan sumber sensor riil
    final realSource = ref.read(realSensorSourceProvider);
    sampler.setSource(realSource);

    controller.updateConfig(MonitorConfig(tiltToleranceDeg: _tiltToleranceDeg));
    controller.start();
    controller.startCalibration();
  }

  @override
  void dispose() {
    ref.read(samplerProvider).stop();
    super.dispose();
  }

  void _onToleranceChanged(double val) {
    setState(() {
      _tiltToleranceDeg = val.roundToDouble();
    });
    ref.read(monitorControllerProvider).updateConfig(
          MonitorConfig(tiltToleranceDeg: _tiltToleranceDeg),
        );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).updateTiltToleranceDeg(_tiltToleranceDeg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sensitivitas sensor berhasil disimpan!'),
            backgroundColor: AppColors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    // Sinkronisasi awal toleransi dari user profile
    if (!_isInitializedFromUser && user != null) {
      _tiltToleranceDeg = user.settings.tiltToleranceDeg;
      _isInitializedFromUser = true;
    }

    final snapshotAsync = ref.watch(monitorSnapshotProvider);
    final snapshot = snapshotAsync.value;

    final currentTilt = snapshot?.deltaTilt ?? 0.0;
    final currentState = snapshot?.state ?? MonitorState.calibrating;
    final zScore = snapshot?.zScore ?? 0.0;
    final magnitude = snapshot?.magnitude ?? 9.81;

    final isViolation = currentState == MonitorState.violation;
    final isCalibrating = currentState == MonitorState.calibrating;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Sensitivitas Sensor',
          style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Atur seberapa jauh ponsel boleh bergerak sebelum alarm kelompok berbunyi.',
                style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // 1. Centerpiece: Live Gyro Sensor Card
              AppCard(
                backgroundColor: isViolation
                    ? AppColors.red.withValues(alpha: 0.08)
                    : AppColors.card,
                border: Border.all(
                  color: isViolation
                      ? AppColors.red.withValues(alpha: 0.5)
                      : AppColors.cardBorder,
                  width: 1.5,
                ),
                child: Column(
                  children: [
                    // Status Pill Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isViolation
                                    ? AppColors.red
                                    : (isCalibrating ? AppColors.amber : AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isCalibrating
                                  ? 'SEDANG MENGALIBRASI'
                                  : 'SENSOR GIRO REAL-TIME',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isViolation
                                    ? AppColors.red
                                    : (isCalibrating ? AppColors.amber : AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.screen_rotation, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'ROLL / PITCH',
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gauge Visualizer
                    SizedBox(
                      width: 220,
                      height: 180,
                      child: CustomPaint(
                        painter: TiltGaugePainter(
                          currentAngleDeg: currentTilt,
                          thresholdDeg: _tiltToleranceDeg,
                          isViolation: isViolation,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    currentTilt.toStringAsFixed(1),
                                    style: AppTheme.tabularFigures.copyWith(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: isViolation ? AppColors.red : AppColors.textPrimary,
                                      height: 1.0,
                                    ),
                                  ),
                                  const Text(
                                    '°',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildStatusBadge(currentState, isViolation),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tick labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('0°', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Text('15°', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Text('30°', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Text('45°+', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Testing hint card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isViolation ? Icons.warning_amber_rounded : Icons.vibration,
                            size: 18,
                            color: isViolation ? AppColors.red : AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isViolation
                                  ? 'Pelanggaran terdeteksi! Kembalikan ponsel ke posisi datar.'
                                  : 'Miringkan HP Anda perlahan untuk menguji sensitivitas secara real-time.',
                              style: AppTheme.bodySmall.copyWith(
                                color: isViolation ? AppColors.red : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Interactive Slider Section
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toleransi Sudut',
                              style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Batas kemiringan sebelum sinyal bahaya',
                              style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_tiltToleranceDeg.toInt()}°',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surfaceContainer,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _tiltToleranceDeg,
                        min: 5.0,
                        max: 40.0,
                        divisions: 35,
                        onChanged: _onToleranceChanged,
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Ketat (5°)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text('Longgar (40°)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Insight Hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getHintForTolerance(_tiltToleranceDeg),
                              style: AppTheme.bodySmall.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Telemetry & Recalibration Quick Actions
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTelemetryItem('Z-Score', zScore.toStringAsFixed(2)),
                        _buildTelemetryItem('Akselerasi', '${magnitude.toStringAsFixed(2)} m/s²'),
                        _buildTelemetryItem(
                          'Status',
                          switch (currentState) {
                            MonitorState.violation => 'TERANGKAT',
                            MonitorState.armed => 'AKTIF',
                            MonitorState.calibrating => 'KALIBRASI',
                            MonitorState.recovering => 'PEMULIHAN',
                            MonitorState.idle => 'SIAGA',
                          },
                          color: isViolation
                              ? AppColors.red
                              : (isCalibrating ? AppColors.amber : AppColors.primary),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.cardBorder, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.verified_outlined, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Kalibrasi Otomatis Meja',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(monitorControllerProvider).startCalibration();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Memulai kalibrasi ulang posisi datar...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Text(
                            'SET NOL',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Row: Pemantauan saat layar mati (S19)
              AppCard(
                onTap: () {
                  S19SheetIzinPemantauanContent.show(context);
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.screen_lock_portrait, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pemantauan saat layar mati',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.settings.monitorPermission == 'always'
                                ? 'Selalu aktif (Hemat baterai diabaikan)'
                                : (user?.settings.monitorPermission == 'whileSession'
                                    ? 'Aktif saat sesi berjalan'
                                    : (user?.settings.monitorPermission == 'once'
                                        ? 'Ditanya setiap sesi'
                                        : 'Layar tetap menyala')),
                            style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Fixed Save Button
              PrimaryButton(
                text: 'Simpan',
                isLoading: _isSaving,
                onPressed: _saveSettings,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MonitorState state, bool isViolation) {
    if (state == MonitorState.calibrating) {
      return const StatusChip(label: 'Mengalibrasi...', color: StatusChipColor.amber);
    }
    if (isViolation) {
      return const StatusChip(label: 'Pelanggaran!', color: StatusChipColor.red);
    }
    if (state == MonitorState.recovering) {
      return const StatusChip(label: 'Memulihkan...', color: StatusChipColor.amber);
    }
    return const StatusChip(label: 'Sudut Stabil', color: StatusChipColor.green);
  }

  Widget _buildTelemetryItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.tabularFigures.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getHintForTolerance(double deg) {
    if (deg <= 10) {
      return 'Sangat ketat ($deg°). Cocok untuk meja stabil tanpa guncangan.';
    } else if (deg <= 20) {
      return 'Standar ($deg°). Optimal mendeteksi HP diangkat tanpa memicu alarm saat mengetik.';
    } else {
      return 'Longgar ($deg°). Direkomendasikan jika meja belajar Anda sering goyang.';
    }
  }
}

/// Custom painter menggambar circular arc gauge untuk delta kemiringan
class TiltGaugePainter extends CustomPainter {
  final double currentAngleDeg;
  final double thresholdDeg;
  final bool isViolation;

  TiltGaugePainter({
    required this.currentAngleDeg,
    required this.thresholdDeg,
    required this.isViolation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final radius = min(size.width, size.height) / 2 - 14;

    const startAngle = 135.0 * pi / 180.0;
    const sweepTotal = 270.0 * pi / 180.0;
    const maxDeg = 45.0;

    // 1. Background Arc Track
    final bgPaint = Paint()
      ..color = AppColors.surfaceContainer
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // 2. Threshold Limit Arc (0 sampai thresholdDeg)
    final clampedThreshold = thresholdDeg.clamp(0.0, maxDeg);
    final thresholdSweep = sweepTotal * (clampedThreshold / maxDeg);
    final thresholdPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      thresholdSweep,
      false,
      thresholdPaint,
    );

    // 3. Current Live Tilt Arc
    final clampedCurrent = currentAngleDeg.clamp(0.0, maxDeg);
    final currentSweep = sweepTotal * (clampedCurrent / maxDeg);
    final livePaint = Paint()
      ..color = isViolation ? AppColors.red : AppColors.primary
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (currentSweep > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        currentSweep,
        false,
        livePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TiltGaugePainter oldDelegate) {
    return oldDelegate.currentAngleDeg != currentAngleDeg ||
        oldDelegate.thresholdDeg != thresholdDeg ||
        oldDelegate.isViolation != isViolation;
  }
}
