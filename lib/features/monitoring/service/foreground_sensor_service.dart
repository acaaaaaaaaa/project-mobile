import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../../core/config/firebase_config.dart';
import '../../session/domain/alarm_service.dart';
import '../data/real_sensor_source.dart';
import '../domain/monitor_config.dart';
import '../domain/monitor_controller.dart';
import '../domain/sensor_source.dart';

@pragma('vm:entry-point')
void startForegroundSensorCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundSensorTaskHandler());
}

/// TaskHandler yang berjalan di isolat Foreground Service
/// Menginisialisasi Firebase, menjalankan sensor engine, dan menulis event ke RTDB saat layar mati
class ForegroundSensorTaskHandler extends TaskHandler {
  MonitorController? _monitorController;
  RealSensorSource? _sensorSource;
  Sampler? _sampler;
  StreamSubscription<ViolationEvent>? _violationSub;
  StreamSubscription<DatabaseEvent>? _roomEventsSub;
  AlarmService? _alarmService;

  String? _roomId;
  String? _uid;
  String? _roomName;
  int _endAtMs = 0;
  String _alarmMode = 'both';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[ForegroundService] Isolate started: $timestamp');

    // 1. Inisialisasi Firebase di dalam isolat service
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: KerkomFirebaseConfig.options);
    }

    _alarmService = AlarmService();

    // 2. Siapkan sensor engine A4 dengan RealSensorSource 50 Hz
    _sensorSource = RealSensorSource();
    _sampler = Sampler(initialSource: _sensorSource!);
    _monitorController = MonitorController(
      sampler: _sampler!,
      config: const MonitorConfig(tiltToleranceDeg: 15.0),
    );

    _sampler!.start();
    _monitorController!.start();
    _monitorController!.startCalibration();

    // 3. Dengarkan pelanggaran saat layar mati
    _violationSub = _monitorController!.eventStream.listen((event) {
      _onViolationDetected(event);
    });
  }

  void _onViolationDetected(ViolationEvent event) {
    debugPrint('[ForegroundService] PELANGGARAN TERDETEKSI: deltaTilt=${event.deltaTilt}°, zScore=${event.zScore}');

    if (_roomId != null && _uid != null) {
      final db = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: KerkomFirebaseConfig.options.databaseURL,
      );

      final pushKey = db.ref('roomEvents/$_roomId').push().key ?? 'fgs_${DateTime.now().millisecondsSinceEpoch}';

      db.ref('roomEvents/$_roomId/$pushKey').set({
        'type': 'violation',
        'uid': _uid,
        'tsServer': ServerValue.timestamp,
        'clientTs': DateTime.now().millisecondsSinceEpoch,
        'deltaTiltDeg': event.deltaTilt,
        'zScore': event.zScore,
      });

      db.ref('roomMembers/$_roomId/$_uid').update({
        'state': 'terangkat',
      });
      db.ref('roomMembers/$_roomId/$_uid/liftCount').runTransaction((mutable) {
        final val = (mutable as num?)?.toInt() ?? 0;
        return Transaction.success(val + 1);
      });
    }

    // Bunyikan alarm di ponsel terkunci
    _alarmService?.triggerAlarm(alarmMode: _alarmMode);

    // Update notifikasi
    FlutterForegroundTask.updateService(
      notificationTitle: 'PERINGATAN: Ponsel Terangkat!',
      notificationText: 'Kembalikan HP ke meja datar untuk melanjutkan fokus.',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_endAtMs > 0) {
      final remainingSec = ((_endAtMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (remainingSec > 0) {
        final m = remainingSec ~/ 60;
        final s = remainingSec % 60;
        final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        FlutterForegroundTask.updateService(
          notificationTitle: 'Sesi fokus berjalan - ${_roomName ?? "Kerkom"}',
          notificationText: 'Sisa waktu: $timeStr • Layar mati aman terpantau',
        );
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isStopping) async {
    debugPrint('[ForegroundService] Destroyed: $timestamp, isStopping: $isStopping');
    _violationSub?.cancel();
    _roomEventsSub?.cancel();
    _sampler?.stop();
    _monitorController?.dispose();
    _alarmService?.dispose();
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      if (data['action'] == 'init_session') {
        _roomId = data['roomId']?.toString();
        _uid = data['uid']?.toString();
        _roomName = data['roomName']?.toString();
        _endAtMs = (data['endAtMs'] as num?)?.toInt() ?? 0;
        _alarmMode = data['alarmMode']?.toString() ?? 'both';
        final tolerance = (data['tiltToleranceDeg'] as num?)?.toDouble() ?? 15.0;

        _monitorController?.updateConfig(MonitorConfig(tiltToleranceDeg: tolerance));
        _listenToRoomEvents();
      } else if (data['action'] == 'spike_test_write') {
        // SPIKE: Tulis 1 test event ke Firebase untuk membuktikan foreground service berjalan
        _writeSpikeTestEvent();
      }
    }
  }

  void _listenToRoomEvents() {
    if (_roomId == null) return;
    _roomEventsSub?.cancel();

    final db = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: KerkomFirebaseConfig.options.databaseURL,
    );

    _roomEventsSub = db.ref('roomEvents/$_roomId').onChildAdded.listen((event) {
      final val = event.snapshot.value;
      if (val is Map) {
        final eventUid = val['uid']?.toString();
        if (eventUid != null && eventUid != _uid) {
          // Anggota lain mengangkat ponsel saat HP kita terkunci -> alarm berbunyi!
          _alarmService?.triggerAlarm(alarmMode: _alarmMode);
          FlutterForegroundTask.updateService(
            notificationTitle: 'Peringatan Kelompok',
            notificationText: 'Ada anggota yang mengangkat HP!',
          );
        }
      }
    });
  }

  Future<void> _writeSpikeTestEvent() async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: KerkomFirebaseConfig.options.databaseURL,
      );
      final testKey = 'spike_${DateTime.now().millisecondsSinceEpoch}';
      await db.ref('spike_test/$testKey').set({
        'status': 'SUCCESS',
        'message': 'Foreground service successfully running sensor engine with screen off',
        'timestamp': ServerValue.timestamp,
        'clientTime': DateTime.now().toIso8601String(),
      });
      debugPrint('[ForegroundService SPIKE] Test event berhasil ditulis ke spike_test/$testKey');
    } catch (e) {
      debugPrint('[ForegroundService SPIKE] Gagal menulis test event: $e');
    }
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}

class ForegroundSensorServiceManager {
  ForegroundSensorServiceManager._();

  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'kerkom_focus_monitoring',
        channelName: 'Pemantauan Fokus Layar Mati',
        channelDescription: 'Menjaga sensor giroskop & akselerometer tetap aktif selama sesi belajar',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<bool> start({
    required String roomId,
    required String uid,
    required String roomName,
    required int endAtMs,
    required double tiltToleranceDeg,
    required String alarmMode,
  }) async {
    await init();

    final reqResult = await FlutterForegroundTask.requestNotificationPermission();
    if (reqResult == NotificationPermission.denied) {
      debugPrint('Notification permission denied');
      return false;
    }

    final serviceRunning = await FlutterForegroundTask.isRunningService;
    if (!serviceRunning) {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Sesi fokus berjalan - $roomName',
        notificationText: 'Sensor aktif memantau meja',
        callback: startForegroundSensorCallback,
      );
    }

    // Kirim metadata sesi ke isolat service
    FlutterForegroundTask.sendDataToTask({
      'action': 'init_session',
      'roomId': roomId,
      'uid': uid,
      'roomName': roomName,
      'endAtMs': endAtMs,
      'tiltToleranceDeg': tiltToleranceDeg,
      'alarmMode': alarmMode,
    });

    return true;
  }

  static Future<void> triggerSpikeTestEvent() async {
    FlutterForegroundTask.sendDataToTask({
      'action': 'spike_test_write',
    });
  }

  static Future<void> stop() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      await FlutterForegroundTask.stopService();
    }
  }
}
