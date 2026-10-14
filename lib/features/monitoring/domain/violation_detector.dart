import 'monitor_config.dart';
import 'window_features.dart';

enum DetectionStatus { normal, candidate, violation }

class ViolationDetector {
  MonitorConfig config;
  int _consecutiveHighWindows = 0;
  bool _isViolating = false;

  ViolationDetector({this.config = const MonitorConfig()});

  bool get isViolating => _isViolating;
  int get consecutiveHighWindows => _consecutiveHighWindows;

  void reset() {
    _consecutiveHighWindows = 0;
    _isViolating = false;
  }

  void updateConfig(MonitorConfig newConfig) {
    config = newConfig;
  }

  /// Evaluasi fitur window untuk deteksi pelanggaran dengan hysteresis
  DetectionStatus evaluate(WindowFeaturesOutput features) {
    final tHigh = config.tiltToleranceDeg;
    final tLow = config.tiltRecoveryDeg;
    final kHigh = config.kZScoreHigh;
    final kLow = config.kZScoreLow;

    // Deteksi pengangkatan HP: sudut kemiringan berubah, percepatan dinamis naik bersama tilt, atau z-score naik
    final isHigh = features.meanDeltaTilt > tHigh ||
        features.zScore > kHigh ||
        (features.peakToPeak > 2.0 && features.meanDeltaTilt > 5.0) ||
        (features.meanDeltaTilt > (tHigh * 0.75) && features.gyroRms > 0.8);

    final isLow = features.meanDeltaTilt < tLow &&
        features.zScore < kLow &&
        features.gyroRms < 0.4;

    if (!_isViolating) {
      if (isHigh) {
        _consecutiveHighWindows++;
        if (_consecutiveHighWindows >= config.consecutiveWindows) {
          _isViolating = true;
          return DetectionStatus.violation;
        }
        return DetectionStatus.candidate;
      } else {
        _consecutiveHighWindows = 0;
        return DetectionStatus.normal;
      }
    } else {
      // Sedang dalam status pelanggaran; pulih kembali hanya jika berada di bawah batas rendah (hysteresis)
      if (isLow) {
        _consecutiveHighWindows = 0;
        _isViolating = false;
        return DetectionStatus.normal;
      }
      return DetectionStatus.violation;
    }
  }
}
