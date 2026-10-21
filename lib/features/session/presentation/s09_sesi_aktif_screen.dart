import 'dart:async';
import '../../../core/utils/platform_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/destructive_outline_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../monitoring/domain/monitor_config.dart';
import '../../monitoring/domain/monitor_controller.dart';
import '../../monitoring/presentation/monitoring_providers.dart';
import '../../monitoring/service/foreground_sensor_service.dart';
import '../../monitoring/service/screen_state_service.dart';
import '../../room/domain/room_models.dart';
import '../../room/presentation/room_controller.dart';
import '../domain/session_models.dart';
import 'session_controller.dart';

class S09SesiAktifScreen extends ConsumerStatefulWidget {
  final String roomId;

  const S09SesiAktifScreen({super.key, required this.roomId});

  @override
  ConsumerState<S09SesiAktifScreen> createState() => _S09SesiAktifScreenState();
}

class _S09SesiAktifScreenState extends ConsumerState<S09SesiAktifScreen> with WidgetsBindingObserver {
  StreamSubscription<ViolationEvent>? _sensorViolationSub;
  StreamSubscription<MonitorState>? _sensorStateSub;
  bool _sessionInitialized = false;
  bool _foregroundServiceReady = false;
  bool _isInBackground = false;
  double _exitSliderValue = 0.0;
  bool _isNavigatingAway = false;
  bool _wasDeviceLifted = false;
  String? _localAlertBanner;
  String? _remoteViolatorBanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  void _initSession() {
    final room = ref.read(roomProvider(widget.roomId)).value;
    if (room == null || room.hasEndedAt(ref.read(serverTimeServiceProvider).nowServerMs)) {
      context.replace('/session-summary/${widget.roomId}?readOnly=true');
      return;
    }
    if (room.status != 'berjalan' || room.endAt == null) {
      context.replace('/lobby/${widget.roomId}');
      return;
    }
    _sessionInitialized = true;
    final endAt = room.endAt!;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentUser = ref.read(currentUserProvider).value;
    final monitorPerm = currentUser?.settings.monitorPermission ?? 'whileSession';

    // 1. Inisialisasi pelacakan sesi (Timer sync, presence, roomEvents listener)
    ref.read(sessionEngineProvider(widget.roomId).notifier).startSessionTracking(endAt);

    // 2. Hubungkan sampler dan monitor controller dengan sensor riil & toleransi pengguna
    final sampler = ref.read(samplerProvider);
    final realSource = ref.read(realSensorSourceProvider);
    sampler.setSource(realSource);

    final monitorController = ref.read(monitorControllerProvider);
    final tiltTol = currentUser?.settings.tiltToleranceDeg ?? 15.0;
    monitorController.updateConfig(MonitorConfig(tiltToleranceDeg: tiltTol));
    monitorController.start(preserveCalibration: true);
    if (monitorController.calibration == null) monitorController.startCalibration();

    // 3. Sinkronisasi foto profil pengguna ke roomMembers
    if (currentUid != null && currentUser?.photoUrl.isNotEmpty == true) {
      ref.read(sessionRepositoryProvider).syncMemberPhoto(
            roomId: widget.roomId,
            uid: currentUid,
            photoUrl: currentUser!.photoUrl,
          );
    }

    _sensorViolationSub?.cancel();
    _sensorViolationSub = monitorController.eventStream.listen((event) {
      if (!_isNavigatingAway) {
        _handleLocalViolation(deltaTilt: event.deltaTilt, zScore: event.zScore);
      }
    });
    _sensorStateSub = monitorController.stateStream.listen((state) {
      if (state == MonitorState.armed && !_isNavigatingAway) {
        _handlePhoneRestored();
      }
    });

    // 4. Mulai Foreground Service (Android jika diizinkan) atau Wakelock (iOS / fallback)
    if (AppPlatform.isAndroid && monitorPerm != 'denied') {
      ForegroundSensorServiceManager.start(
        roomId: widget.roomId,
        uid: currentUid ?? '',
        roomName: room.name,
        endAtMs: endAt,
        tiltToleranceDeg: tiltTol,
        alarmMode: currentUser?.settings.alarmMode ?? 'both',
        calibration: monitorController.calibration,
      ).then((started) {
        if (!mounted || _isNavigatingAway) {
          if (started) ForegroundSensorServiceManager.stop();
          return;
        }
        _foregroundServiceReady = started;
        if (started && _isInBackground) {
          ForegroundSensorServiceManager.setBackgroundMonitoring(true, calibration: monitorController.calibration);
          monitorController.stop();
        }
        if (!started) WakelockPlus.enable();
      });
    } else {
      WakelockPlus.enable();
    }
  }

  void _handleLocalViolation({required double deltaTilt, required double zScore}) {
    if (_wasDeviceLifted || _isNavigatingAway || !mounted) return;
    _wasDeviceLifted = true;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentUser = ref.read(currentUserProvider).value;
    final alarmMode = currentUser?.settings.alarmMode ?? 'both';

    // 1. Bunyikan alarm lokal sesuai pengaturan pengguna
    ref.read(alarmServiceProvider).triggerAlarm(alarmMode: alarmMode);

    // 2. Langsung kirim event pelanggaran ke RTDB agar diterima instan oleh anggota lain
    if (currentUid != null) {
      ref.read(sessionRepositoryProvider).recordRoomViolation(
            roomId: widget.roomId,
            uid: currentUid,
            deltaTiltDeg: deltaTilt,
            zScore: zScore,
            memberName: currentUser?.displayName,
          );
    }

    if (mounted) {
      setState(() {
        _localAlertBanner = 'Peringatan: Kamu mengangkat HP! (Kemiringan ${deltaTilt.toStringAsFixed(1)}°)';
      });
    }
  }

  void _handlePhoneRestored() {
    _wasDeviceLifted = false;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (_remoteViolatorBanner == null) ref.read(alarmServiceProvider).stop();

    if (currentUid != null) {
      ref.read(sessionRepositoryProvider).clearRoomViolation(
            roomId: widget.roomId,
            uid: currentUid,
          );
    }

    if (mounted) {
      setState(() {
        _localAlertBanner = null;
      });
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Ruang Sesi?',
          style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Apakah Anda yakin ingin meninggalkan sesi fokus ini? Sesi kelompok tetap berjalan untuk anggota lain dan status Anda akan ditandai selesai.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_sessionInitialized || _isNavigatingAway) return;
    if (state == AppLifecycleState.resumed) {
      _isInBackground = false;
      if (_foregroundServiceReady) {
        ForegroundSensorServiceManager.setBackgroundMonitoring(false);
        ref.read(monitorControllerProvider).start(preserveCalibration: true);
      }
    } else if (state == AppLifecycleState.paused) {
      _isInBackground = true;
      if (_foregroundServiceReady) {
        final controller = ref.read(monitorControllerProvider);
        ForegroundSensorServiceManager.setBackgroundMonitoring(true, calibration: controller.calibration);
        controller.stop();
      }
      if (!_isNavigatingAway) {
        final isScreenOn = ref.read(screenStateServiceProvider).isScreenOn;
        if (isScreenOn) {
          ref.read(sessionEngineProvider(widget.roomId).notifier).handleAppBackgrounded();
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sensorViolationSub?.cancel();
    _sensorStateSub?.cancel();
    ref.read(alarmServiceProvider).stop();
    ref.read(monitorControllerProvider).stop();
    ref.read(sessionEngineProvider(widget.roomId).notifier).stopSessionTracking();
    if (AppPlatform.isAndroid) {
      ForegroundSensorServiceManager.stop();
    }
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSlideExit() async {
    if (_isNavigatingAway) return;
    _isNavigatingAway = true;

    // Hentikan alarm, service latar belakang & lepaskan wakelock
    ref.read(alarmServiceProvider).stop();
    if (AppPlatform.isAndroid) {
      await ForegroundSensorServiceManager.stop();
    }
    await WakelockPlus.disable();

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentUser = ref.read(currentUserProvider).value;
    final room = ref.read(roomProvider(widget.roomId)).value;
    final repo = ref.read(sessionRepositoryProvider);

    final members = ref.read(roomMembersProvider(widget.roomId)).value ?? [];

    if (currentUid != null && room != null) {
      // 1. Tandai status keluar di roomMembers dan kirim log leaver
      await repo.updateMemberState(
        roomId: widget.roomId,
        uid: currentUid,
        state: 'keluar',
        memberName: currentUser?.displayName,
      );

      // 2. Simpan rekaman sesi lokal
      final startAt = room.startAt ?? DateTime.now().millisecondsSinceEpoch;
      final durationDone = ((DateTime.now().millisecondsSinceEpoch - startAt) / 60000).ceil();
      final now = DateTime.now().millisecondsSinceEpoch;

      await repo.saveUserSession(
        uid: currentUid,
        record: UserSessionRecord(
          roomId: widget.roomId,
          roomName: room.name,
          startAt: startAt,
          completedAt: now,
          durationDoneMin: durationDone,
          violationCount: 0,
          endedHow: 'keluar',
          roomCode: room.code,
          note: room.note,
          meetingLink: room.meetingLink ?? 'https://kerkom.app/j/${room.code}',
          memberCount: members.isNotEmpty ? members.length : 1,
          isCreatedByMe: room.hostUid == currentUid,
          status: 'Selesai',
        ),
      );
    }

    if (mounted) {
      context.go('/session-summary/${widget.roomId}');
    }
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Akhiri Sesi untuk Semua?',
          style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Seluruh anggota akan diarahkan ke ringkasan sesi. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          DestructiveOutlineButton(
            text: 'Akhiri Sekarang',
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(sessionRepositoryProvider).endSessionForEveryone(widget.roomId);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onSessionFinished(String endedHow) async {
    if (_isNavigatingAway) return;
    _isNavigatingAway = true;
    final repo = ref.read(sessionRepositoryProvider);
    ref.read(alarmServiceProvider).stop();
    ref.read(monitorControllerProvider).stop();
    ref.read(sessionEngineProvider(widget.roomId).notifier).stopSessionTracking();

    if (endedHow == 'timer') {
      // Persist completion for members whose screens are off as well.
      await repo.endSessionForEveryone(widget.roomId, endedHow: 'timer');
    }

    if (AppPlatform.isAndroid) {
      await ForegroundSensorServiceManager.stop();
    }
    await WakelockPlus.disable();

    if (mounted) {
      context.go('/session-summary/${widget.roomId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionEngineProvider(widget.roomId));
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final currentUser = ref.watch(currentUserProvider).value;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final room = roomAsync.value;
    final isHost = room != null && room.hostUid == currentUid;

    // 1. Pantau status selesai dari host atau timer
    ref.listen(roomProvider(widget.roomId), (prev, next) {
      if (next.value?.status == 'selesai') {
        _onSessionFinished('host');
      }
    });

    if (sessionState.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSessionFinished('timer');
      });
    }

    // 2. Telemetri Sensor Real-Time
    final snapshot = ref.watch(monitorSnapshotProvider).value;
    final currentTilt = snapshot?.deltaTilt ?? 0.0;
    final zScore = snapshot?.zScore ?? 0.0;
    final magnitude = snapshot?.magnitude ?? 9.81;
    final isDeviceLifted = snapshot?.state == MonitorState.violation;

      // 3. Pantau status seluruh anggota di ruangan (Realtime Member State Watcher)
      ref.listen<AsyncValue<List<RoomMemberModel>>>(roomMembersProvider(widget.roomId), (prev, next) {
        final members = next.value ?? [];
        final remoteViolators = members.where((m) => m.uid != currentUid && m.state == 'terangkat').toList();

        if (remoteViolators.isNotEmpty && _remoteViolatorBanner == null && !_isNavigatingAway) {
          // Ada anggota lain yang terdeteksi mengangkat HP!
          final alarmMode = currentUser?.settings.alarmMode ?? 'both';
          ref.read(alarmServiceProvider).triggerAlarm(alarmMode: alarmMode);

          if (mounted) {
            setState(() {
              _remoteViolatorBanner = 'Peringatan: ${remoteViolators.first.name} mengangkat HP!';
            });
          }
        } else if (remoteViolators.isEmpty && _remoteViolatorBanner != null && !_wasDeviceLifted) {
          // Semua anggota lain sudah kembali meletakkan HP dan HP lokal juga aman
          ref.read(alarmServiceProvider).stop();
          if (mounted) {
            setState(() {
              _remoteViolatorBanner = null;
            });
          }
        }
      });

      // 4. Pantau event pelanggaran dari roomEvents & event keluar
      ref.listen<SessionState>(sessionEngineProvider(widget.roomId), (prev, next) {
        final event = next.latestViolationEvent;
        if (event != null && !_isNavigatingAway) {
          if (event.uid != currentUid) {
            // Bunyikan alarm sesuai preferensi pengaturan pengguna saat anggota lain melanggar
            final alarmMode = currentUser?.settings.alarmMode ?? 'both';
            ref.read(alarmServiceProvider).triggerAlarm(alarmMode: alarmMode);
            if (mounted) {
              setState(() {
                _remoteViolatorBanner = 'Peringatan: ${next.latestViolatorName ?? "Anggota"} mengangkat HP!';
              });
            }
          }
        }

        final leaveEvent = next.latestLeaveEvent;
        if (leaveEvent != null && !_isNavigatingAway) {
          final leaverName = next.latestLeaverName ?? 'Anggota';
          ref.read(sessionEngineProvider(widget.roomId).notifier).clearLatestLeave();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$leaverName telah meninggalkan ruangan.',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.amber,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      });

    final totalDurationSec = (room?.durationMinutes ?? 25) * 60;
    final progress = totalDurationSec > 0
        ? (1.0 - (sessionState.remainingSeconds / totalDurationSec)).clamp(0.0, 1.0)
        : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _showExitConfirmationDialog();
        if (confirmed && mounted) {
          _handleSlideExit();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Meta Bar dengan Tombol Back Konfirmasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                      onPressed: () async {
                        final confirmed = await _showExitConfirmationDialog();
                        if (confirmed && mounted) {
                          _handleSlideExit();
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDeviceLifted ? AppColors.red.withValues(alpha: 0.2) : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sensors_rounded,
                            size: 14,
                            color: isDeviceLifted ? AppColors.red : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDeviceLifted ? 'TERANGKAT' : 'SENSOR AKTIF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDeviceLifted ? AppColors.red : AppColors.primary,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          room?.name ?? 'Sesi Fokus',
                          style: AppTheme.headlineSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 8),

                // Banner Notifikasi Pelanggaran / Peringatan di Tampilan Ruang
                if (_localAlertBanner != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _localAlertBanner!,
                            style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(alarmServiceProvider).stop();
                            setState(() => _localAlertBanner = null);
                          },
                          child: const Text('Diamkan', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w900, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ] else if (_remoteViolatorBanner != null || (sessionState.latestViolationEvent != null && sessionState.latestViolationEvent!.uid != currentUid)) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _remoteViolatorBanner ?? 'Peringatan: ${sessionState.latestViolatorName ?? "Anggota"} mengangkat HP!',
                            style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(alarmServiceProvider).stop();
                            ref.read(sessionEngineProvider(widget.roomId).notifier).clearLatestViolation();
                            setState(() => _remoteViolatorBanner = null);
                          },
                          child: const Text('Diamkan', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w900, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Countdown Ring Display
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 190,
                          height: 190,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: AppColors.surfaceContainer,
                            color: isDeviceLifted ? AppColors.red : AppColors.primary,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'TARGET INTERVAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(sessionState.remainingSeconds),
                              style: AppTheme.timerDisplay.copyWith(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: isDeviceLifted ? AppColors.red : AppColors.primary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'dari ${room?.durationMinutes ?? 25} menit',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Informasi Telemetri Real-Time (Z-Score & Akselerasi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDeviceLifted
                        ? AppColors.red.withValues(alpha: 0.12)
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDeviceLifted
                          ? AppColors.red.withValues(alpha: 0.5)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTelemetryMetric('Z-Score', zScore.toStringAsFixed(2), isAlert: isDeviceLifted),
                      Container(width: 1, height: 24, color: AppColors.cardBorder),
                      _buildTelemetryMetric('Akselerasi', '${magnitude.toStringAsFixed(2)} m/s²', isAlert: isDeviceLifted),
                      Container(width: 1, height: 24, color: AppColors.cardBorder),
                      _buildTelemetryMetric('Sudut', '${currentTilt.toStringAsFixed(1)}°', isAlert: isDeviceLifted),
                      Container(width: 1, height: 24, color: AppColors.cardBorder),
                      _buildTelemetryBadge(isDeviceLifted ? 'TERANGKAT' : 'STABIL', isAlert: isDeviceLifted),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Group Accountability Card
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ANGGOTA KELOMPOK',
                              style: AppTheme.labelSmall.copyWith(
                                letterSpacing: 1.0,
                                color: AppColors.textMuted,
                              ),
                            ),
                            membersAsync.when(
                              data: (m) => Text(
                                '${m.where((e) => e.state == 'aman').length}/${m.length} Disiplin',
                                style: const TextStyle(fontSize: 11, color: AppColors.primary),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (err, stack) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: membersAsync.when(
                            data: (members) {
                              return ListView.separated(
                                itemCount: members.length,
                                separatorBuilder: (_, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  final isMe = member.uid == currentUid;
                                  final nowMs = DateTime.now().millisecondsSinceEpoch;
                                  final isOffline = (nowMs - member.lastSeen) > 20000;

                                  final effectivePhoto = (isMe && currentUser?.photoUrl.isNotEmpty == true)
                                      ? currentUser!.photoUrl
                                      : member.photoUrl;

                                  return Container(
                                    key: ValueKey(member.uid),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        AvatarCircle(
                                          name: member.name,
                                          photoUrl: effectivePhoto,
                                          size: 36,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      member.name,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isMe) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1.5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        'Kamu',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  if (member.isHost) ...[
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 1.5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFEF3C7),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        '👑 Ketua',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: Color(0xFFB45309),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                member.state == 'terangkat'
                                                    ? 'Mengangkat HP (${member.liftCount}x)'
                                                    : (member.state == 'keluar'
                                                        ? 'Meninggalkan ruangan'
                                                        : (isOffline ? 'Koneksi terputus' : 'Stationary di meja')),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: member.state == 'terangkat'
                                                      ? AppColors.red
                                                      : AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildMemberStatusChip(member.state, isOffline),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) => Center(child: Text('Error: $err')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Slide-to-Exit Zone dengan Konfirmasi
                Column(
                  children: [
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.surfaceContainer,
                          inactiveTrackColor: AppColors.card,
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          trackHeight: 38,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 18),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Text(
                              'Geser untuk keluar ›››',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Slider(
                              value: _exitSliderValue,
                              onChanged: (val) async {
                                setState(() => _exitSliderValue = val);
                                if (val >= 0.95) {
                                  setState(() => _exitSliderValue = 0.0);
                                  final confirmed = await _showExitConfirmationDialog();
                                  if (confirmed && mounted) {
                                    _handleSlideExit();
                                  }
                                }
                              },
                              onChangeEnd: (val) {
                                if (val < 0.95) {
                                  setState(() => _exitSliderValue = 0.0);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Keluar awal menandai status ke seluruh tim tanpa penalti.',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    if (isHost) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _showEndSessionDialog,
                        child: const Text(
                          'Akhiri Sesi untuk Semua',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryMetric(String label, String value, {bool isAlert = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isAlert ? AppColors.red : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryBadge(String status, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.red.withValues(alpha: 0.2) : AppColors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isAlert ? AppColors.red : AppColors.green,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMemberStatusChip(String state, bool isOffline) {
    if (state == 'terangkat') {
      return const StatusChip(label: 'Terangkat', color: StatusChipColor.red);
    }
    if (state == 'keluar') {
      return const StatusChip(label: 'Keluar', color: StatusChipColor.amber);
    }
    if (isOffline || state == 'terputus') {
      return const StatusChip(label: 'Terputus', color: StatusChipColor.amber);
    }
    return const StatusChip(label: 'Aman', color: StatusChipColor.green);
  }
}
