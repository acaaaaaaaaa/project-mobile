import 'dart:async';
import '../../../core/utils/platform_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../monitoring/domain/monitor_controller.dart';
import '../../monitoring/presentation/monitoring_providers.dart';
import '../../room/presentation/room_controller.dart';
import '../../session/presentation/session_controller.dart';
import 's19_sheet_izin_pemantauan.dart';

class S08KalibrasiScreen extends ConsumerStatefulWidget {
  final String roomId;

  const S08KalibrasiScreen({super.key, required this.roomId});

  @override
  ConsumerState<S08KalibrasiScreen> createState() => _S08KalibrasiScreenState();
}

class _S08KalibrasiScreenState extends ConsumerState<S08KalibrasiScreen> {
  int _countdownSeconds = 3;
  Timer? _countdownTimer;
  bool _calibrationFinished = false;
  bool _isStable = true;
  StreamSubscription<MonitorState>? _stateSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndStartCalibration();
    });
  }

  Future<void> _checkPermissionAndStartCalibration() async {
    if (!mounted) return;

    if (AppPlatform.isIOS) {
      // iOS fallback: tidak ada background sensing, layar tetap menyala
      await WakelockPlus.enable();
    } else if (AppPlatform.isAndroid) {
      final user = ref.read(currentUserProvider).value;
      final perm = user?.settings.monitorPermission;
      if (perm == null || perm.isEmpty || perm == 'once') {
        final result = await S19SheetIzinPemantauanContent.show(context);
        if (result == 'denied') {
          await WakelockPlus.enable();
        }
      } else if (perm == 'denied') {
        await WakelockPlus.enable();
      }
    }

    if (mounted) {
      _startCalibrationFlow();
    }
  }

  void _startCalibrationFlow() {
    final controller = ref.read(monitorControllerProvider);
    final sampler = ref.read(samplerProvider);

    sampler.start();
    controller.start();
    controller.startCalibration();

    _countdownSeconds = 3;
    _calibrationFinished = false;
    _isStable = true;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
      }
    });

    _stateSub?.cancel();
    _stateSub = controller.stateStream.listen((state) {
      if (state == MonitorState.armed && !_calibrationFinished) {
        _onCalibrationSuccess();
      }
    });
  }

  Future<void> _onCalibrationSuccess() async {
    _calibrationFinished = true;
    _countdownTimer?.cancel();

    final room = ref.read(roomProvider(widget.roomId)).value;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (room == null || currentUid == null) return;

    final isHost = room.hostUid == currentUid;
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final serverTime = ref.read(serverTimeServiceProvider);

    if (isHost) {
      // Host menyelesaikan kalibrasi -> sesi mulai berjalan untuk semua anggota
      await sessionRepo.startSessionByHost(
        roomId: widget.roomId,
        durationMinutes: room.durationMinutes,
        estimatedServerTimeMs: serverTime.nowServerMs,
      );
      if (mounted) {
        context.go('/active-session/${widget.roomId}');
      }
    } else {
      // Anggota biasa menyelesaikan kalibrasi
      await sessionRepo.updateMemberState(
        roomId: widget.roomId,
        uid: currentUid,
        state: 'aman',
      );

      // Jika room sudah 'berjalan', langsung pindah (late joiner)
      if (room.status == 'berjalan') {
        if (mounted) {
          context.go('/active-session/${widget.roomId}');
        }
      } else {
        // Jika belum berjalan, tunggu host
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    ref.listen(roomProvider(widget.roomId), (prev, next) {
      final room = next.value;
      if (room != null && room.status == 'berjalan' && _calibrationFinished) {
        if (mounted) {
          context.go('/active-session/${widget.roomId}');
        }
      }
    });

    final room = roomAsync.value;
    final isHost = room != null && room.hostUid == currentUid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    label: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.sensors_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'SENSOR AKTIF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Central Calibration Display
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Letakkan HP datar di meja',
                    style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pastikan layar menghadap ke atas pada permukaan datar yang stabil.',
                    style: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Circular Countdown Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Pulse Circle
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.05),
                        ),
                      ),
                      // Countdown Ring
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: (4 - _countdownSeconds) / 3.0,
                          strokeWidth: 6,
                          backgroundColor: AppColors.surfaceContainer,
                          color: AppColors.primary,
                        ),
                      ),
                      // Countdown Number or Waiting
                      if (_calibrationFinished && !isHost && room?.status != 'berjalan')
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Menunggu\nhost...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '$_countdownSeconds',
                          style: AppTheme.timerDisplay.copyWith(
                            fontSize: 72,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Telemetry Status Badge
                  _buildStatusChip(),
                  const SizedBox(height: 10),
                  const Text(
                    'Jangan sentuh HP selama 3 detik',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),

              // Bottom Advisory
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppPlatform.isIOS
                            ? 'Catatan iOS: Layar akan tetap menyala selama sesi berjalan (pemantauan latar belakang tidak aktif di iOS).'
                            : 'Kalibrasi gravitasi akan mengunci posisi nol untuk mendeteksi ponsel diangkat.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    if (_calibrationFinished) {
      return const StatusChip(
        label: 'Kalibrasi Selesai • Baseline Terkunci',
        color: StatusChipColor.green,
      );
    }
    if (!_isStable) {
      return const StatusChip(
        label: 'Meja Bergoyang • Mengulang...',
        color: StatusChipColor.amber,
      );
    }
    return const StatusChip(
      label: 'Mengukur Gravitasi Statis...',
      color: StatusChipColor.lime,
    );
  }
}
