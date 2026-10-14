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
import '../../monitoring/domain/monitor_controller.dart';
import '../../monitoring/presentation/monitoring_providers.dart';
import '../../monitoring/service/foreground_sensor_service.dart';
import '../../monitoring/service/screen_state_service.dart';
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
  double _exitSliderValue = 0.0;
  bool _isNavigatingAway = false;

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
    final endAt = room?.endAt ?? (DateTime.now().millisecondsSinceEpoch + 25 * 60 * 1000);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentUser = ref.read(currentUserProvider).value;
    final monitorPerm = currentUser?.settings.monitorPermission ?? 'whileSession';

    // 1. Inisialisasi pelacakan sesi (Timer sync, presence, roomEvents listener)
    ref.read(sessionEngineProvider(widget.roomId).notifier).startSessionTracking(endAt);

    // 2. Hubungkan monitor controller ke deteksi pelanggaran lokal
    final monitorController = ref.read(monitorControllerProvider);
    final sampler = ref.read(samplerProvider);
    sampler.start();
    if (monitorController.state == MonitorState.idle) {
      monitorController.start();
      monitorController.forceCalibrationSuccess();
    }

    _sensorViolationSub?.cancel();
    _sensorViolationSub = monitorController.eventStream.listen((event) {
      if (!_isNavigatingAway) {
        ref.read(sessionEngineProvider(widget.roomId).notifier).recordViolation(
              deltaTiltDeg: event.deltaTilt,
              zScore: event.zScore,
            );
      }
    });

    // 3. Mulai Foreground Service (Android jika diizinkan) atau Wakelock (iOS / fallback)
    if (AppPlatform.isAndroid && monitorPerm != 'denied') {
      ForegroundSensorServiceManager.start(
        roomId: widget.roomId,
        uid: currentUid ?? '',
        roomName: room?.name ?? 'Sesi Fokus',
        endAtMs: endAt,
        tiltToleranceDeg: currentUser?.settings.tiltToleranceDeg ?? 15.0,
        alarmMode: currentUser?.settings.alarmMode ?? 'both',
      );
    } else {
      WakelockPlus.enable();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Requirement 4: app goes to background while screen is ON = user switched apps = violation.
    // Screen OFF = locked = fine, keep monitoring via foreground service.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
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

    // Hentikan service latar belakang & lepaskan wakelock
    if (AppPlatform.isAndroid) {
      await ForegroundSensorServiceManager.stop();
    }
    await WakelockPlus.disable();

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final room = ref.read(roomProvider(widget.roomId)).value;
    final repo = ref.read(sessionRepositoryProvider);

    final members = ref.read(roomMembersProvider(widget.roomId)).value ?? [];

    if (currentUid != null && room != null) {
      // 1. Tandai status keluar di roomMembers
      await repo.updateMemberState(roomId: widget.roomId, uid: currentUid, state: 'keluar');

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

    if (AppPlatform.isAndroid) {
      await ForegroundSensorServiceManager.stop();
    }
    await WakelockPlus.disable();

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final room = ref.read(roomProvider(widget.roomId)).value;
    final repo = ref.read(sessionRepositoryProvider);
    final members = ref.read(roomMembersProvider(widget.roomId)).value ?? [];

    if (currentUid != null && room != null) {
      final startAt = room.startAt ?? DateTime.now().millisecondsSinceEpoch;
      final durationDone = room.durationMinutes;
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
          endedHow: endedHow,
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

    // 2. Pantau event pelanggaran untuk membuka S10 atau S11 & memutar alarm
    ref.listen<SessionState>(sessionEngineProvider(widget.roomId), (prev, next) {
      final event = next.latestViolationEvent;
      if (event != null && !_isNavigatingAway) {
        // Bunyikan alarm sesuai pengaturan lokal
        final alarmMode = currentUser?.settings.alarmMode ?? 'both';
        ref.read(alarmServiceProvider).triggerAlarm(alarmMode: alarmMode);

        if (event.uid == currentUid) {
          // S10 Alarm: Pelanggar
          ref.read(sessionEngineProvider(widget.roomId).notifier).clearLatestViolation();
          context.push('/alarm-violator/${widget.roomId}');
        } else {
          // S11 Alarm: Anggota Lain
          final violatorName = next.latestViolatorName ?? 'Anggota';
          ref.read(sessionEngineProvider(widget.roomId).notifier).clearLatestViolation();
          context.push(
            '/alarm-peer/${widget.roomId}',
            extra: {'violatorName': violatorName},
          );
        }
      }
    });

    final totalDurationSec = (room?.durationMinutes ?? 25) * 60;
    final progress = totalDurationSec > 0
        ? (1.0 - (sessionState.remainingSeconds / totalDurationSec)).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Meta Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
              const SizedBox(height: 16),

              // Countdown Ring Display
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: AppColors.surfaceContainer,
                          color: AppColors.primary,
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
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
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
              const SizedBox(height: 10),

              // Stability indicator
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.screen_lock_portrait, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'HP terdeteksi stabil di meja',
                        style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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

                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      AvatarCircle(name: member.name, size: 36),
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
                                                  : (isOffline ? 'Koneksi terputus' : 'Stationary di meja'),
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

              // Slide-to-Exit Zone
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
                            onChanged: (val) {
                              setState(() => _exitSliderValue = val);
                              if (val >= 0.95) {
                                _handleSlideExit();
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
