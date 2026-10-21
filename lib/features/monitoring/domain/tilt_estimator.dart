import 'dart:math';
import 'low_pass_filter.dart';
import 'monitor_config.dart';
import 'sensor_sample.dart';

class TiltEstimation {
  final double roll; // Derajat (-180 s/d +180)
  final double pitch; // Derajat (-180 s/d +180)
  final double deltaTilt; // Deviasi dari baseline dalam derajat

  const TiltEstimation({
    required this.roll,
    required this.pitch,
    required this.deltaTilt,
  });

  @override
  String toString() =>
      'TiltEstimation(roll: ${roll.toStringAsFixed(1)}°, pitch: ${pitch.toStringAsFixed(1)}°, deltaTilt: ${deltaTilt.toStringAsFixed(1)}°)';
}

class TiltEstimator {
  final MonitorConfig config;
  final Vector3LowPassFilter _accelLpf;

  double _baselineRoll = 0.0;
  double _baselinePitch = 0.0;

  double _currentRoll = 0.0;
  double _currentPitch = 0.0;
  int? _lastTimestampMs;
  bool _initialized = false;

  TiltEstimator({this.config = const MonitorConfig()})
      : _accelLpf = Vector3LowPassFilter(tau: config.lpfTau);

  double get currentRoll => _currentRoll;
  double get currentPitch => _currentPitch;
  double get baselineRoll => _baselineRoll;
  double get baselinePitch => _baselinePitch;

  void setBaseline(double roll0, double pitch0) {
    _baselineRoll = roll0;
    _baselinePitch = pitch0;
    _currentRoll = roll0;
    _currentPitch = pitch0;
    _lastTimestampMs = null;
    _initialized = true;
    _accelLpf.reset();
  }

  void reset() {
    _baselineRoll = 0.0;
    _baselinePitch = 0.0;
    _currentRoll = 0.0;
    _currentPitch = 0.0;
    _lastTimestampMs = null;
    _initialized = false;
    _accelLpf.reset();
  }

  /// Update estimasi kemiringan dengan cuplikan sensor
  TiltEstimation update(SensorSample sample) {
    final now = sample.timestampMs;
    final dt = _lastTimestampMs == null
        ? 0.02
        : max(0.001, (now - _lastTimestampMs!) / 1000.0);
    _lastTimestampMs = now;

    // 1. Saring akselerometer dengan Low-Pass Filter
    final filteredAccel = _accelLpf.filter(sample.ax, sample.ay, sample.az, dt);

    // 2. Sudut Roll & Pitch dari akselerometer (gravitasi statis)
    final rollAccel = atan2(filteredAccel.y, filteredAccel.z) * 180.0 / pi;
    final pitchAccel = atan2(
          -filteredAccel.x,
          sqrt(filteredAccel.y * filteredAccel.y + filteredAccel.z * filteredAccel.z),
        ) *
        180.0 /
        pi;

    if (!_initialized) {
      _currentRoll = rollAccel;
      _currentPitch = pitchAccel;
      _baselineRoll = rollAccel;
      _baselinePitch = pitchAccel;
      _initialized = true;
    } else {
      // 3. Integrasikan giroskop (rad/s -> derajat/s)
      final rollGyro = _currentRoll + (sample.gx * dt * 180.0 / pi);
      final pitchGyro = _currentPitch + (sample.gy * dt * 180.0 / pi);

      // 4. Filter Komplementer: roll = beta * rollGyro + (1 - beta) * rollAccel
      final beta = config.compBeta;
      // Blend the shortest angular difference, including face-down phones at +/-180.
      _currentRoll = _wrap180(rollGyro + (1.0 - beta) * _wrap180(rollAccel - rollGyro));
      _currentPitch = _wrap180(pitchGyro + (1.0 - beta) * _wrap180(pitchAccel - pitchGyro));
    }

    // 5. Hitung deltaTilt dengan penanganan wrap +-180 derajat (mengabaikan yaw)
    final deltaRoll = _wrap180(_currentRoll - _baselineRoll);
    final deltaPitch = _wrap180(_currentPitch - _baselinePitch);
    final deltaTilt = sqrt(deltaRoll * deltaRoll + deltaPitch * deltaPitch);

    return TiltEstimation(
      roll: _currentRoll,
      pitch: _currentPitch,
      deltaTilt: deltaTilt,
    );
  }

  double _wrap180(double deg) {
    var angle = deg % 360.0;
    if (angle > 180.0) angle -= 360.0;
    if (angle < -180.0) angle += 360.0;
    return angle;
  }
}
