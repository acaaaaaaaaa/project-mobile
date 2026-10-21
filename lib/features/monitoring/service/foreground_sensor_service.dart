import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../core/config/firebase_config.dart';
import '../../session/domain/alarm_service.dart';
import '../data/real_sensor_source.dart';
import '../domain/calibrator.dart';
import '../domain/monitor_config.dart';
import '../domain/monitor_controller.dart';
import '../domain/sensor_source.dart';

@pragma('vm:entry-point')
void startForegroundSensorCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundSensorTaskHandler());
}

class ForegroundSensorTaskHandler extends TaskHandler {
  MonitorController? _controller;
  AlarmService? _alarm;
  StreamSubscription<ViolationEvent>? _violationSub;
  StreamSubscription<MonitorState>? _stateSub;
  StreamSubscription<DatabaseEvent>? _membersSub;
  String? _roomId;
  String? _uid;
  String _roomName = 'Kerkom';
  String _alarmMode = 'both';
  int _endAtMs = 0;
  bool _backgroundMonitoring = false;
  bool _localViolation = false;
  bool _peerViolation = false;

  FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: KerkomFirebaseConfig.options.databaseURL,
  );

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: KerkomFirebaseConfig.options);
    }
    _alarm = AlarmService();
    _controller = MonitorController(
      sampler: Sampler(initialSource: RealSensorSource()),
    );
    _violationSub = _controller!.eventStream.listen((event) {
      if (_backgroundMonitoring) _recordViolation(event);
    });
    _stateSub = _controller!.stateStream.listen((state) {
      if (_backgroundMonitoring &&
          state == MonitorState.armed &&
          _localViolation) {
        _localViolation = false;
        _db.ref('roomMembers/$_roomId/$_uid').update({
          'state': 'aman',
          'lastSeen': ServerValue.timestamp,
        });
        if (!_peerViolation) _alarm?.stop();
        _showMonitoringNotification();
      }
    });
    // Read metadata on startup instead of racing sendDataToTask against onStart.
    final saved = await FlutterForegroundTask.getData<String>(
      key: 'focus_session',
    );
    if (saved != null) onReceiveData(jsonDecode(saved));
    if (await FlutterForegroundTask.getData<bool>(key: 'focus_background') ==
        true) {
      onReceiveData({'action': 'background_monitoring', 'enabled': true});
    }
  }

  void _recordViolation(ViolationEvent event) {
    if (_localViolation || _roomId == null || _uid == null) return;
    _localViolation = true;
    _db.ref('roomEvents/$_roomId').push().set({
      'type': 'violation',
      'uid': _uid,
      'tsServer': ServerValue.timestamp,
      'clientTs': DateTime.now().millisecondsSinceEpoch,
      'deltaTiltDeg': event.deltaTilt,
      'zScore': event.zScore,
    });
    final member = _db.ref('roomMembers/$_roomId/$_uid');
    member.update({'state': 'terangkat', 'lastSeen': ServerValue.timestamp});
    member
        .child('liftCount')
        .runTransaction(
          (value) => Transaction.success(((value as num?)?.toInt() ?? 0) + 1),
        );
    _alarm?.triggerAlarm(alarmMode: _alarmMode);
    FlutterForegroundTask.updateService(
      notificationTitle: 'PERINGATAN: Ponsel Terangkat!',
      notificationText: 'Kembalikan HP ke meja datar untuk melanjutkan fokus.',
    );
  }

  void _showMonitoringNotification() {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Sesi fokus berjalan - $_roomName',
      notificationText: 'Sensor aktif memantau meja',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Timer ticks never refresh or re-alert the persistent notification.
    if (_endAtMs > 0 && timestamp.millisecondsSinceEpoch >= _endAtMs) {
      _backgroundMonitoring = false;
      _controller?.stop();
      _alarm?.stop();
      FlutterForegroundTask.stopService();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isStopping) async {
    await _violationSub?.cancel();
    await _stateSub?.cancel();
    await _membersSub?.cancel();
    _controller?.dispose();
    _alarm?.dispose();
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    if (data['action'] == 'init_session') {
      _roomId = data['roomId']?.toString();
      _uid = data['uid']?.toString();
      _roomName = data['roomName']?.toString() ?? 'Kerkom';
      _endAtMs = (data['endAtMs'] as num?)?.toInt() ?? 0;
      _alarmMode = data['alarmMode']?.toString() ?? 'both';
      _controller?.updateConfig(
        MonitorConfig(
          tiltToleranceDeg:
              (data['tiltToleranceDeg'] as num?)?.toDouble() ?? 15,
        ),
      );
      final calibration = _readCalibration(data['calibration']);
      if (calibration != null) _controller?.useCalibration(calibration);
      _watchMembers();
    } else if (data['action'] == 'background_monitoring') {
      _backgroundMonitoring = data['enabled'] == true;
      if (_backgroundMonitoring) {
        final calibration =
            _readCalibration(data['calibration']) ?? _controller?.calibration;
        _controller?.start();
        if (calibration != null) {
          _controller?.useCalibration(calibration);
        } else {
          _controller?.startCalibration();
        }
        if (_peerViolation) _alarm?.triggerAlarm(alarmMode: _alarmMode);
      } else {
        _controller?.stop();
        _alarm?.stop();
      }
    } else if (data['action'] == 'spike_test_write') {
      _db
          .ref('spike_test')
          .push()
          .set({'status': 'SUCCESS', 'timestamp': ServerValue.timestamp})
          .catchError(
            (Object error) => debugPrint('Foreground diagnostic: $error'),
          );
    }
  }

  void _watchMembers() {
    _membersSub?.cancel();
    // Watch current violations; replaying historical roomEvents raised old alarms.
    _membersSub = _db.ref('roomMembers/$_roomId').onValue.listen((event) {
      final value = event.snapshot.value;
      final previous = _peerViolation;
      _peerViolation =
          value is Map &&
          value.entries.any(
            (entry) =>
                entry.key.toString() != _uid &&
                entry.value is Map &&
                entry.value['state'] == 'terangkat',
          );
      if (!_backgroundMonitoring) return;
      if (_peerViolation && !previous) {
        _alarm?.triggerAlarm(alarmMode: _alarmMode);
        FlutterForegroundTask.updateService(
          notificationTitle: 'Peringatan Kelompok',
          notificationText: 'Ada anggota yang mengangkat HP!',
        );
      } else if (!_peerViolation && !_localViolation && previous) {
        _alarm?.stop();
        _showMonitoringNotification();
      }
    });
  }

  CalibrationData? _readCalibration(Object? value) {
    if (value is! Map) return null;
    return CalibrationData(
      meanMagnitude: (value['meanMagnitude'] as num).toDouble(),
      stdMagnitude: (value['stdMagnitude'] as num).toDouble(),
      baselineRoll: (value['baselineRoll'] as num).toDouble(),
      baselinePitch: (value['baselinePitch'] as num).toDouble(),
    );
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
        // A new channel is needed: Android persists an existing channel's importance.
        channelId: 'kerkom_focus_monitoring_quiet_v2',
        channelName: 'Pemantauan Fokus Layar Mati',
        channelDescription: 'Pemantauan sensor selama sesi belajar',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000),
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
    CalibrationData? calibration,
  }) async {
    await init();
    if (await FlutterForegroundTask.requestNotificationPermission() ==
        NotificationPermission.denied) {
      return false;
    }
    final metadata = {
      'action': 'init_session',
      'roomId': roomId,
      'uid': uid,
      'roomName': roomName,
      'endAtMs': endAtMs,
      'tiltToleranceDeg': tiltToleranceDeg,
      'alarmMode': alarmMode,
      'calibration': _calibrationMap(calibration),
    };
    await FlutterForegroundTask.saveData(
      key: 'focus_session',
      value: jsonEncode(metadata),
    );
    await FlutterForegroundTask.saveData(key: 'focus_background', value: false);
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask(metadata);
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Sesi fokus berjalan - $roomName',
        notificationText: 'Sensor aktif memantau meja',
        callback: startForegroundSensorCallback,
      );
    }
    return await FlutterForegroundTask.isRunningService;
  }

  static Map<String, double>? _calibrationMap(CalibrationData? data) =>
      data == null
      ? null
      : {
          'meanMagnitude': data.meanMagnitude,
          'stdMagnitude': data.stdMagnitude,
          'baselineRoll': data.baselineRoll,
          'baselinePitch': data.baselinePitch,
        };

  static Future<void> setBackgroundMonitoring(
    bool enabled, {
    CalibrationData? calibration,
  }) async {
    await FlutterForegroundTask.saveData(
      key: 'focus_background',
      value: enabled,
    );
    FlutterForegroundTask.sendDataToTask({
      'action': 'background_monitoring',
      'enabled': enabled,
      'calibration': _calibrationMap(calibration),
    });
  }

  static Future<void> triggerSpikeTestEvent() async {
    FlutterForegroundTask.sendDataToTask({'action': 'spike_test_write'});
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
