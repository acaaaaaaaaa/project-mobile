import 'dart:math';
import 'monitor_config.dart';
import 'sensor_sample.dart';

class CalibrationData {
  final double meanMagnitude;
  final double stdMagnitude;
  final double baselineRoll;
  final double baselinePitch;

  const CalibrationData({
    required this.meanMagnitude,
    required this.stdMagnitude,
    required this.baselineRoll,
    required this.baselinePitch,
  });

  @override
  String toString() =>
      'CalibrationData(mean: ${meanMagnitude.toStringAsFixed(2)}, std: ${stdMagnitude.toStringAsFixed(3)}, roll: ${baselineRoll.toStringAsFixed(1)}°, pitch: ${baselinePitch.toStringAsFixed(1)}°)';
}

enum CalibrationStatus { inProgress, success, notStable }

class Calibrator {
  final MonitorConfig config;
  final int requiredDurationMs;

  int _count = 0;
  double _mean = 0.0;
  double _m2 = 0.0;
  int? _startMs;

  double _accAx = 0.0;
  double _accAy = 0.0;
  double _accAz = 0.0;

  CalibrationData? _result;
  CalibrationStatus _status = CalibrationStatus.inProgress;

  Calibrator({
    this.config = const MonitorConfig(),
    this.requiredDurationMs = 1500,
  });

  CalibrationStatus get status => _status;
  CalibrationData? get result => _result;
  double get currentMean => _mean;
  double get currentStd => _count > 1 ? sqrt(_m2 / (_count - 1)) : 0.0;
  int get sampleCount => _count;

  void reset() {
    _count = 0;
    _mean = 0.0;
    _m2 = 0.0;
    _startMs = null;
    _accAx = 0.0;
    _accAy = 0.0;
    _accAz = 0.0;
    _result = null;
    _status = CalibrationStatus.inProgress;
  }

  /// Paksa kalibrasi selesai jika batas waktu countdown telah habis
  CalibrationStatus forceSuccess({double? roll, double? pitch}) {
    final avgAx = _count > 0 ? _accAx / _count : 0.0;
    final avgAy = _count > 0 ? _accAy / _count : 0.0;
    final avgAz = _count > 0 ? _accAz / _count : 9.80665;
    final calcRoll = roll ?? (atan2(avgAy, avgAz) * 180.0 / pi);
    final calcPitch = pitch ?? (atan2(-avgAx, sqrt(avgAy * avgAy + avgAz * avgAz)) * 180.0 / pi);

    _result = CalibrationData(
      meanMagnitude: _count > 0 ? _mean : 9.80665,
      stdMagnitude: max(currentStd, config.epsilonStd),
      baselineRoll: calcRoll,
      baselinePitch: calcPitch,
    );
    _status = CalibrationStatus.success;
    return _status;
  }

  /// Tambahkan cuplikan sensor ke dalam algoritma online Welford
  CalibrationStatus addSample(SensorSample sample) {
    if (_status != CalibrationStatus.inProgress) return _status;

    _startMs ??= sample.timestampMs;
    final mag = sample.magnitude;

    // Algoritma online Welford
    _count++;
    final delta = mag - _mean;
    _mean += delta / _count;
    final delta2 = mag - _mean;
    _m2 += delta * delta2;

    _accAx += sample.ax;
    _accAy += sample.ay;
    _accAz += sample.az;

    final elapsed = sample.timestampMs - _startMs!;
    if (elapsed >= requiredDurationMs && _count >= 25) {
      final std = currentStd;
      // Berikan toleransi kestabilan yang wajar agar tidak stuck saat ponsel dipegang sebentar
      if (std <= 0.8 || elapsed >= 2500) {
        final avgAx = _accAx / _count;
        final avgAy = _accAy / _count;
        final avgAz = _accAz / _count;

        final roll = atan2(avgAy, avgAz) * 180.0 / pi;
        final pitch = atan2(-avgAx, sqrt(avgAy * avgAy + avgAz * avgAz)) * 180.0 / pi;

        _result = CalibrationData(
          meanMagnitude: _mean,
          stdMagnitude: max(std, config.epsilonStd),
          baselineRoll: roll,
          baselinePitch: pitch,
        );
        _status = CalibrationStatus.success;
      } else {
        _status = CalibrationStatus.notStable;
      }
    }

    return _status;
  }
}
