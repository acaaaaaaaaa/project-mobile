import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum DetectionSensitivity {
  low(threshold: 3.5, label: 'Rendah (Hanya gerakan cepat)'),
  medium(threshold: 2.2, label: 'Sedang (Rekomendasi)'),
  high(threshold: 1.2, label: 'Tinggi (Sangat peka)');

  final double threshold;
  final String label;
  const DetectionSensitivity({required this.threshold, required this.label});
}

class SensorReading {
  final double x;
  final double y;
  final double z;
  final double magnitude;
  final DateTime timestamp;

  SensorReading({
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.timestamp,
  });
}

class PhoneMotionService {
  static final PhoneMotionService _instance = PhoneMotionService._internal();
  factory PhoneMotionService() => _instance;
  PhoneMotionService._internal();

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DetectionSensitivity sensitivity = DetectionSensitivity.medium;

  bool _isMonitoring = false;
  bool _isPhoneLifted = false;
  DateTime? _liftedStartTime;

  // Stream controllers untuk UI & Notifikasi
  final _readingController = StreamController<SensorReading>.broadcast();
  final _liftStateController = StreamController<bool>.broadcast();

  Stream<SensorReading> get readingStream => _readingController.stream;
  Stream<bool> get liftStateStream => _liftStateController.stream;

  bool get isMonitoring => _isMonitoring;
  bool get isPhoneLifted => _isPhoneLifted;
  DateTime? get liftedStartTime => _liftedStartTime;

  // Kalibrasi baseline
  double _baselineMagnitude = 0.0;
  int _consecutiveMovements = 0;
  int _consecutiveResting = 0;

  void startMonitoring({
    DetectionSensitivity? customSensitivity,
    void Function()? onLifted,
    void Function()? onResting,
  }) {
    if (_isMonitoring) return;

    if (customSensitivity != null) {
      sensitivity = customSensitivity;
    }

    _isMonitoring = true;
    _isPhoneLifted = false;
    _consecutiveMovements = 0;
    _consecutiveResting = 0;

    try {
      _accelerometerSubscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          _processReading(event.x, event.y, event.z, onLifted, onResting);
        },
        onError: (e) {
          // Fallback jika platform tidak mendukung sensor (misal emulator tanpa sensor hardware aktif)
          // Event stream tetap terbuka
        },
        cancelOnError: false,
      );
    } catch (_) {
      // Handle error gracefully
    }
  }

  void _processReading(
    double x,
    double y,
    double z,
    void Function()? onLifted,
    void Function()? onResting,
  ) {
    final magnitude = sqrt(x * x + y * y + z * z);
    final delta = (magnitude - _baselineMagnitude).abs();

    final reading = SensorReading(
      x: x,
      y: y,
      z: z,
      magnitude: magnitude,
      timestamp: DateTime.now(),
    );
    _readingController.add(reading);

    if (!_isMonitoring) return;

    // Logika Threshold Deteksi
    if (delta > sensitivity.threshold) {
      _consecutiveMovements++;
      _consecutiveResting = 0;

      // Konfirmasi minimal 2 sample bergerak berturut-turut untuk menghindari accidental vibration
      if (_consecutiveMovements >= 2 && !_isPhoneLifted) {
        _isPhoneLifted = true;
        _liftedStartTime = DateTime.now();
        _liftStateController.add(true);
        if (onLifted != null) onLifted();
      }
    } else {
      _consecutiveResting++;
      _consecutiveMovements = 0;

      // Jika diam selama ~10 sample (sekitar 1 detik), anggap HP sudah ditaruh kembali
      if (_consecutiveResting >= 10 && _isPhoneLifted) {
        _isPhoneLifted = false;
        _liftStateController.add(false);
        if (onResting != null) onResting();
      }
    }
  }

  /// Trigger manual simulasi untuk pengujian di Emulator Android Studio / Komputer
  void simulatePhoneLift(bool lifted, {void Function()? onLifted, void Function()? onResting}) {
    _isPhoneLifted = lifted;
    _liftStateController.add(lifted);

    final simulatedReading = SensorReading(
      x: lifted ? 2.8 : 0.05,
      y: lifted ? 3.4 : 0.02,
      z: lifted ? 1.5 : 0.01,
      magnitude: lifted ? 4.6 : 0.05,
      timestamp: DateTime.now(),
    );
    _readingController.add(simulatedReading);

    if (lifted && onLifted != null) {
      onLifted();
    } else if (!lifted && onResting != null) {
      onResting();
    }
  }

  void calibrateBaseline(double currentMag) {
    _baselineMagnitude = currentMag;
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isPhoneLifted = false;
    _liftStateController.add(false);
  }

  void dispose() {
    stopMonitoring();
    _readingController.close();
    _liftStateController.close();
  }
}
