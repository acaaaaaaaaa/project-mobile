import 'dart:async';
import 'calibrator.dart';
import 'csv_logger.dart';
import 'monitor_config.dart';
import 'sensor_sample.dart';
import 'sensor_source.dart';
import 'tilt_estimator.dart';
import 'violation_detector.dart';
import 'window_features.dart';

enum MonitorState {
  idle,
  calibrating,
  armed,
  violation,
  recovering,
}

class ViolationEvent {
  final int timestampMs;
  final double deltaTilt;
  final double zScore;
  final double gyroRms;

  const ViolationEvent({
    required this.timestampMs,
    required this.deltaTilt,
    required this.zScore,
    required this.gyroRms,
  });

  @override
  String toString() =>
      'ViolationEvent(t: $timestampMs, deltaTilt: ${deltaTilt.toStringAsFixed(1)}°, zScore: ${zScore.toStringAsFixed(2)})';
}

class MonitorSnapshot {
  final MonitorState state;
  final double roll;
  final double pitch;
  final double deltaTilt;
  final double zScore;
  final double magnitude;
  final double gyroRms;
  final CalibrationData? calibration;

  const MonitorSnapshot({
    required this.state,
    required this.roll,
    required this.pitch,
    required this.deltaTilt,
    required this.zScore,
    required this.magnitude,
    required this.gyroRms,
    this.calibration,
  });
}

class MonitorController {
  final Sampler sampler;
  MonitorConfig config;
  final DebugCsvLogger csvLogger;

  final Calibrator _calibrator;
  final TiltEstimator _tiltEstimator;
  final WindowFeaturesExtractor _featureExtractor;
  final ViolationDetector _violationDetector;

  MonitorState _state = MonitorState.idle;
  CalibrationData? _calibration;
  StreamSubscription<SensorSample>? _sampleSub;
  double _lastZScore = 0.0;
  double _lastGyroRms = 0.0;

  final _stateController = StreamController<MonitorState>.broadcast(sync: true);
  final _eventController = StreamController<ViolationEvent>.broadcast(sync: true);
  final _snapshotController = StreamController<MonitorSnapshot>.broadcast(sync: true);

  MonitorController({
    required this.sampler,
    MonitorConfig? config,
    DebugCsvLogger? csvLogger,
  })  : config = config ?? const MonitorConfig(),
        csvLogger = csvLogger ?? DebugCsvLogger(),
        _calibrator = Calibrator(config: config ?? const MonitorConfig()),
        _tiltEstimator = TiltEstimator(config: config ?? const MonitorConfig()),
        _featureExtractor = WindowFeaturesExtractor(config: config ?? const MonitorConfig()),
        _violationDetector = ViolationDetector(config: config ?? const MonitorConfig());

  MonitorState get state => _state;
  CalibrationData? get calibration => _calibration;
  Stream<MonitorState> get stateStream => _stateController.stream;
  Stream<ViolationEvent> get eventStream => _eventController.stream;
  Stream<MonitorSnapshot> get snapshotStream => _snapshotController.stream;

  void updateConfig(MonitorConfig newConfig) {
    config = newConfig;
    _violationDetector.updateConfig(newConfig);
  }

  void start() {
    stop();
    _state = MonitorState.idle;
    _stateController.add(_state);
    sampler.start();
    _sampleSub = sampler.sampleStream.listen(processSample);
  }

  void startCalibration() {
    _calibrator.reset();
    _tiltEstimator.reset();
    _featureExtractor.reset();
    _violationDetector.reset();
    _lastZScore = 0.0;
    _lastGyroRms = 0.0;
    _state = MonitorState.calibrating;
    _stateController.add(_state);
  }

  void forceCalibrationSuccess() {
    final status = _calibrator.forceSuccess();
    if (status == CalibrationStatus.success) {
      _calibration = _calibrator.result;
      _tiltEstimator.setBaseline(
        _calibration!.baselineRoll,
        _calibration!.baselinePitch,
      );
      _state = MonitorState.armed;
      _stateController.add(_state);
    }
  }

  void processSample(SensorSample sample) {
    double currentRoll = 0.0;
    double currentPitch = 0.0;
    double deltaTilt = 0.0;

    switch (_state) {
      case MonitorState.idle:
        break;

      case MonitorState.calibrating:
        final calStatus = _calibrator.addSample(sample);
        if (calStatus == CalibrationStatus.success) {
          _calibration = _calibrator.result;
          _tiltEstimator.setBaseline(
            _calibration!.baselineRoll,
            _calibration!.baselinePitch,
          );
          _state = MonitorState.armed;
          _stateController.add(_state);
        } else if (calStatus == CalibrationStatus.notStable) {
          // Meja belum stabil, ulang kalibrasi
          _calibrator.reset();
        }
        break;

      case MonitorState.armed:
      case MonitorState.violation:
      case MonitorState.recovering:
        final tilt = _tiltEstimator.update(sample);
        currentRoll = tilt.roll;
        currentPitch = tilt.pitch;
        deltaTilt = tilt.deltaTilt;

        final features = _featureExtractor.addSample(sample, deltaTilt, _calibration);

        if (features != null) {
          _lastZScore = features.zScore;
          _lastGyroRms = features.gyroRms;
          final detection = _violationDetector.evaluate(features);

          if (_state == MonitorState.armed && detection == DetectionStatus.violation) {
            _state = MonitorState.violation;
            _stateController.add(_state);
            _eventController.add(
              ViolationEvent(
                timestampMs: sample.timestampMs,
                deltaTilt: deltaTilt,
                zScore: _lastZScore,
                gyroRms: _lastGyroRms,
              ),
            );
          } else if (_state == MonitorState.violation && detection == DetectionStatus.normal) {
            // Memulai pemulihan (recovering)
            _state = MonitorState.recovering;
            _stateController.add(_state);
          } else if (_state == MonitorState.recovering) {
            if (detection == DetectionStatus.normal) {
              _state = MonitorState.armed;
              _stateController.add(_state);
            } else if (detection == DetectionStatus.violation) {
              _state = MonitorState.violation;
              _stateController.add(_state);
            }
          }
        }
        break;
    }

    // Rekam ke debug CSV logger
    csvLogger.log(
      sample: sample,
      roll: currentRoll,
      pitch: currentPitch,
      deltaTilt: deltaTilt,
      zScore: _lastZScore,
      state: _state.name,
    );

    _snapshotController.add(
      MonitorSnapshot(
        state: _state,
        roll: currentRoll,
        pitch: currentPitch,
        deltaTilt: deltaTilt,
        zScore: _lastZScore,
        magnitude: sample.magnitude,
        gyroRms: _lastGyroRms,
        calibration: _calibration,
      ),
    );
  }

  void stop() {
    _sampleSub?.cancel();
    _sampleSub = null;
    sampler.stop();
    _state = MonitorState.idle;
    _stateController.add(_state);
  }

  void dispose() {
    stop();
    _stateController.close();
    _eventController.close();
    _snapshotController.close();
  }
}
