import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/session_repository.dart';
import '../domain/alarm_service.dart';
import '../domain/offline_event_queue.dart';
import '../domain/server_time_service.dart';
import '../domain/session_models.dart';
import '../../auth/presentation/auth_controller.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

/// Stream riwayat sesi user saat ini (userSessions/{uid})
/// Provider tunggal yang digunakan bersama oleh S04 'Sesi terakhir' dan S13 'Riwayat'
final userSessionsProvider = StreamProvider<List<UserSessionRecord>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final uid = userAsync.value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(sessionRepositoryProvider).watchUserSessions(uid);
});

final serverTimeServiceProvider = Provider<ServerTimeService>((ref) {
  final db = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );
  final service = ServerTimeService(db: db);
  ref.onDispose(() => service.dispose());
  return service;
});

final offlineEventQueueProvider = Provider<OfflineEventQueue>((ref) {
  final db = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );
  return OfflineEventQueue(db: db);
});

final alarmServiceProvider = Provider<AlarmService>((ref) {
  final service = AlarmService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream acara ruangan (roomEvents/{roomId})
final roomEventsProvider = StreamProvider.family<List<RoomEvent>, String>((ref, roomId) {
  return ref.watch(sessionRepositoryProvider).watchRoomEvents(roomId);
});

class SessionState {
  final int remainingSeconds;
  final bool isFinished;
  final RoomEvent? latestViolationEvent;
  final String? latestViolatorName;
  final RoomEvent? latestLeaveEvent;
  final String? latestLeaverName;

  const SessionState({
    this.remainingSeconds = 0,
    this.isFinished = false,
    this.latestViolationEvent,
    this.latestViolatorName,
    this.latestLeaveEvent,
    this.latestLeaverName,
  });

  SessionState copyWith({
    int? remainingSeconds,
    bool? isFinished,
    RoomEvent? latestViolationEvent,
    String? latestViolatorName,
    RoomEvent? latestLeaveEvent,
    String? latestLeaverName,
  }) {
    return SessionState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isFinished: isFinished ?? this.isFinished,
      latestViolationEvent: latestViolationEvent,
      latestViolatorName: latestViolatorName,
      latestLeaveEvent: latestLeaveEvent,
      latestLeaverName: latestLeaverName,
    );
  }
}

class SessionEngineNotifier extends StateNotifier<SessionState> {
  final String roomId;
  final Ref ref;

  Timer? _countdownTimer;
  Timer? _heartbeatTimer;
  StreamSubscription? _eventsSub;
  bool _hasInitialEventsLoaded = false;
  final Set<String> _processedEventKeys = {};
  int _joinTimeMs = 0;

  SessionEngineNotifier({required this.roomId, required this.ref})
      : super(const SessionState()) {
    _joinTimeMs = DateTime.now().millisecondsSinceEpoch;
  }

  void startSessionTracking(int endAtMs) {
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();

    final serverTime = ref.read(serverTimeServiceProvider);
    final repo = ref.read(sessionRepositoryProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid != null) {
      repo.setupOnDisconnect(roomId: roomId, uid: currentUid);
      repo.updateMemberState(roomId: roomId, uid: currentUid, state: 'aman');

      // 6. Presence Heartbeat setiap 5 detik
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        repo.sendHeartbeat(roomId: roomId, uid: currentUid);
      });
    }

    // 2. Countdown timer berbasis Server Time Offset (Process 9)
    void tick() {
      final remaining = serverTime.getRemainingSeconds(endAtMs);
      if (remaining <= 0) {
        _countdownTimer?.cancel();
        state = state.copyWith(remainingSeconds: 0, isFinished: true);
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());

    // 4. Dengarkan roomEvents untuk alarm dispatch
    _listenToRoomEvents();
  }

  void _listenToRoomEvents() {
    _eventsSub?.cancel();
    final repo = ref.read(sessionRepositoryProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    _eventsSub = repo.watchRoomEvents(roomId).listen((events) async {
      // 1. Pada load pertama, masukkan seluruh riwayat yang sudah ada ke _processedEventKeys
      if (!_hasInitialEventsLoaded) {
        for (final event in events) {
          _processedEventKeys.add(event.key);
        }
        _hasInitialEventsLoaded = true;
        return;
      }

      // 2. Setiap event baru yang belum ada di _processedEventKeys adalah event baru real-time
      for (final event in events) {
        if (!_processedEventKeys.contains(event.key)) {
          _processedEventKeys.add(event.key);

          if (event.type == 'keluar') {
            String leaverName = 'Anggota';
            if (event.uid != currentUid) {
              leaverName = await repo.fetchUserDisplayName(event.uid);
            } else {
              leaverName = 'Kamu';
            }

            state = state.copyWith(
              latestLeaveEvent: event,
              latestLeaverName: leaverName,
            );
          } else {
            String violatorName = 'Kamu';
            if (event.uid != currentUid) {
              violatorName = await repo.fetchUserDisplayName(event.uid);
            }

            state = state.copyWith(
              latestViolationEvent: event,
              latestViolatorName: violatorName,
            );
          }
        }
      }
    });
  }

  /// Catat pelanggaran ke Offline Event Queue (Process 10)
  void recordViolation({
    required double deltaTiltDeg,
    required double zScore,
  }) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    ref.read(offlineEventQueueProvider).enqueueAndSend(
          roomId: roomId,
          uid: currentUid,
          clientTs: DateTime.now().millisecondsSinceEpoch,
          deltaTiltDeg: deltaTiltDeg,
          zScore: zScore,
        );
  }

  /// Tangani aplikasi berpindah ke latar belakang saat layar menyala (Requirement 7)
  void handleAppBackgrounded() {
    recordViolation(deltaTiltDeg: 0.0, zScore: 0.0);
  }

  void clearLatestViolation() {
    state = state.copyWith(latestViolationEvent: null, latestViolatorName: null);
  }

  void clearLatestLeave() {
    state = state.copyWith(latestLeaveEvent: null, latestLeaverName: null);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    _eventsSub?.cancel();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      ref.read(sessionRepositoryProvider).cancelOnDisconnect(roomId: roomId, uid: currentUid);
    }
    super.dispose();
  }
}

final sessionEngineProvider =
    StateNotifierProvider.family<SessionEngineNotifier, SessionState, String>((ref, roomId) {
  return SessionEngineNotifier(roomId: roomId, ref: ref);
});
