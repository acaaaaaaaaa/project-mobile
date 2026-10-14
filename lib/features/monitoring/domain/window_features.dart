import 'dart:math';
import 'calibrator.dart';
import 'monitor_config.dart';
import 'sensor_sample.dart';

class WindowFeaturesOutput {
  final double zScore;
  final double gyroRms;
  final double peakToPeak;
  final double meanDeltaTilt;
  final int windowEndTimestampMs;

  const WindowFeaturesOutput({
    required this.zScore,
    required this.gyroRms,
    required this.peakToPeak,
    required this.meanDeltaTilt,
    required this.windowEndTimestampMs,
  });

  @override
  String toString() =>
      'Features(deltaTilt: ${meanDeltaTilt.toStringAsFixed(1)}°, zScore: ${zScore.toStringAsFixed(2)}, gyroRms: ${gyroRms.toStringAsFixed(2)}, p2p: ${peakToPeak.toStringAsFixed(2)})';
}

class WindowFeaturesExtractor {
  final MonitorConfig config;
  final List<SensorSample> _sampleBuffer = [];
  final List<double> _tiltBuffer = [];

  WindowFeaturesExtractor({this.config = const MonitorConfig()});

  void reset() {
    _sampleBuffer.clear();
    _tiltBuffer.clear();
  }

  /// Tambahkan cuplikan dan kemiringan saat ini.
  /// Mengembalikan WindowFeaturesOutput jika jendela berukuran 25 telah terpenuhi, lalu hop 12 sampel.
  WindowFeaturesOutput? addSample(
    SensorSample sample,
    double deltaTilt,
    CalibrationData? calibration,
  ) {
    _sampleBuffer.add(sample);
    _tiltBuffer.add(deltaTilt);

    if (_sampleBuffer.length >= config.windowSize) {
      final features = _compute(calibration);

      // Hop 12 sampel (geser jendela)
      final hop = min(config.hopSize, _sampleBuffer.length);
      _sampleBuffer.removeRange(0, hop);
      _tiltBuffer.removeRange(0, hop);

      return features;
    }

    return null;
  }

  WindowFeaturesOutput _compute(CalibrationData? calibration) {
    final n = _sampleBuffer.length;
    double sumMag = 0.0;
    double minMag = double.infinity;
    double maxMag = double.negativeInfinity;
    double sumGyroSq = 0.0;
    double sumTilt = 0.0;

    for (int i = 0; i < n; i++) {
      final s = _sampleBuffer[i];
      final mag = s.magnitude;
      sumMag += mag;
      if (mag < minMag) minMag = mag;
      if (mag > maxMag) maxMag = mag;

      final gyroSq = s.gx * s.gx + s.gy * s.gy + s.gz * s.gz;
      sumGyroSq += gyroSq;
      sumTilt += _tiltBuffer[i];
    }

    final meanMag = sumMag / n;
    final peakToPeak = maxMag - minMag;
    final gyroRms = sqrt(sumGyroSq / n);
    final meanDeltaTilt = sumTilt / n;

    // Hitung z-score magnitudo terhadap baseline
    final baselineMag = calibration?.meanMagnitude ?? 9.80665;
    final std = calibration != null
        ? max(calibration.stdMagnitude, config.epsilonStd)
        : 0.15;
    final zScore = (meanMag - baselineMag).abs() / std;

    return WindowFeaturesOutput(
      zScore: zScore,
      gyroRms: gyroRms,
      peakToPeak: peakToPeak,
      meanDeltaTilt: meanDeltaTilt,
      windowEndTimestampMs: _sampleBuffer.last.timestampMs,
    );
  }
}
