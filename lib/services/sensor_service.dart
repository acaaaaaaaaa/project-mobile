import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum DetectionSensitivity {
  low(threshold: 3.5, label: 'Rendah'),
  medium(threshold: 2.2, label: 'Sedang'),
  high(threshold: 1.2, label: 'Tinggi');
  final double threshold;
  final String label;
  const DetectionSensitivity({required this.threshold, required this.label});
}

class SensorReading {
  final double x, y, z, magnitude;
  final DateTime timestamp;
  SensorReading(this.x, this.y, this.z, this.magnitude, this.timestamp);
}

class MotionEpisode {
  final DateTime observedAt;
  final int durationMs;
  final double peakAccel, peakGyro, orientationChangeDeg, confidence;
  MotionEpisode(this.observedAt, this.durationMs, this.peakAccel,
      this.peakGyro, this.orientationChangeDeg, this.confidence);
}

class PhoneMotionService {
  static final PhoneMotionService _instance = PhoneMotionService._internal();
  factory PhoneMotionService() => _instance;
  PhoneMotionService._internal();

  StreamSubscription<UserAccelerometerEvent>? _motion;
  StreamSubscription<AccelerometerEvent>? _gravity;
  StreamSubscription<GyroscopeEvent>? _gyro;
  final _readingController = StreamController<SensorReading>.broadcast();
  final _liftController = StreamController<bool>.broadcast();
  Stream<SensorReading> get readingStream => _readingController.stream;
  Stream<bool> get liftStateStream => _liftController.stream;
  DetectionSensitivity sensitivity = DetectionSensitivity.medium;
  bool _monitoring = false, _lifted = false;
  bool get isMonitoring => _monitoring;
  bool get isPhoneLifted => _lifted;
  DateTime? liftedStartTime;
  DateTime? _candidateAt, _quietAt, _calibrationUntil;
  double _gx = 0, _gy = 0, _gz = 9.8;
  double _bx = 0, _by = 0, _bz = 9.8;
  double _gyroMagnitude = 0, _peakAccel = 0, _peakGyro = 0, _peakAngle = 0;
  bool _hasGravity = false;
  void Function(MotionEpisode)? _onLifted;
  void Function()? _onResting;

  void startMonitoring({DetectionSensitivity? customSensitivity,
      void Function(MotionEpisode)? onLifted, void Function()? onResting}) {
    _onLifted = onLifted;
    _onResting = onResting;
    if (_monitoring) return;
    if (customSensitivity != null) sensitivity = customSensitivity;
    _monitoring = true;
    _lifted = false;
    _candidateAt = _quietAt = null;
    _calibrationUntil = DateTime.now().add(const Duration(seconds: 2));
    _hasGravity = false;
    _peakAccel = _peakGyro = _peakAngle = 0;
    _gravity = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _gx = event.x; _gy = event.y; _gz = event.z;
      if (!_hasGravity) {
        _bx = _gx; _by = _gy; _bz = _gz;
        _hasGravity = true;
      }
      if (DateTime.now().isBefore(_calibrationUntil!) && !_lifted) {
        _bx = .95 * _bx + .05 * _gx;
        _by = .95 * _by + .05 * _gy;
        _bz = .95 * _bz + .05 * _gz;
      }
    }, onError: (_) {});
    _gyro = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _gyroMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    }, onError: (_) {});
    _motion = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _process(event.x, event.y, event.z);
    }, onError: (_) {});
  }

  double get orientationChangeDeg {
    final dot = _gx * _bx + _gy * _by + _gz * _bz;
    final norms = sqrt(_gx * _gx + _gy * _gy + _gz * _gz) *
        sqrt(_bx * _bx + _by * _by + _bz * _bz);
    if (!_hasGravity || norms < 1) return 0;
    return acos((dot / norms).clamp(-1.0, 1.0)) * 180 / pi;
  }

  void _process(double x, double y, double z) {
    final now = DateTime.now();
    final magnitude = sqrt(x * x + y * y + z * z);
    _readingController.add(SensorReading(x, y, z, magnitude, now));
    if (!_monitoring || now.isBefore(_calibrationUntil!)) return;
    final angle = orientationChangeDeg;
    final moving = angle >= 25 ||
        (magnitude >= sensitivity.threshold && _gyroMagnitude >= .35);
    if (moving) {
      _quietAt = null;
      _candidateAt ??= now;
      _peakAccel = max(_peakAccel, magnitude);
      _peakGyro = max(_peakGyro, _gyroMagnitude);
      _peakAngle = max(_peakAngle, angle);
      if (!_lifted && now.difference(_candidateAt!).inMilliseconds >= 650) {
        _lifted = true;
        liftedStartTime = _candidateAt;
        _liftController.add(true);
        _onLifted?.call(MotionEpisode(_candidateAt!,
            now.difference(_candidateAt!).inMilliseconds, _peakAccel,
            _peakGyro, _peakAngle, .75));
      }
    } else {
      _quietAt ??= now;
      if (now.difference(_quietAt!).inMilliseconds >= 1200) {
        _candidateAt = null;
        _peakAccel = _peakGyro = _peakAngle = 0;
        if (_lifted) {
          _lifted = false;
          _liftController.add(false);
          _onResting?.call();
        }
      }
    }
  }

  void calibrateBaseline(double ignored) {
    _bx = _gx; _by = _gy; _bz = _gz;
    _candidateAt = null;
    _peakAccel = _peakGyro = _peakAngle = 0;
  }

  void simulatePhoneLift(bool lifted) {
    if (_lifted == lifted) return;
    _lifted = lifted;
    _liftController.add(lifted);
    _readingController.add(SensorReading(lifted ? 3 : 0, 0, 0,
        lifted ? 3 : 0, DateTime.now()));
    if (lifted) {
      liftedStartTime = DateTime.now();
      _onLifted?.call(MotionEpisode(liftedStartTime!, 1000, 3, 1, 35, .75));
    } else {
      _onResting?.call();
    }
  }

  void stopMonitoring() {
    _monitoring = false;
    _motion?.cancel(); _gravity?.cancel(); _gyro?.cancel();
    _motion = null; _gravity = null; _gyro = null;
    _lifted = false;
    _candidateAt = null;
    _liftController.add(false);
  }
}
