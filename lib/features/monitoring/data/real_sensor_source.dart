import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../domain/sensor_sample.dart';
import '../domain/sensor_source.dart';

/// Implementasi sumber sensor nyata berbasis sensors_plus (50 Hz, samplingPeriod 20 ms)
class RealSensorSource implements SensorSource {
  final _controller = StreamController<SensorSample>.broadcast();
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _lastAx = 0.0;
  double _lastAy = 0.0;
  double _lastAz = 9.80665;
  double _lastGx = 0.0;
  double _lastGy = 0.0;
  double _lastGz = 0.0;

  @override
  Stream<SensorSample> get sampleStream => _controller.stream;

  @override
  void start() {
    stop();

    // Dengarkan akselerometer baku dengan interval 20 ms (50 Hz)
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(
      (event) {
        _lastAx = event.x;
        _lastAy = event.y;
        _lastAz = event.z;
        _emit();
      },
      onError: (e) {},
    );

    // Dengarkan giroskop dengan interval 20 ms (50 Hz)
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(
      (event) {
        _lastGx = event.x;
        _lastGy = event.y;
        _lastGz = event.z;
      },
      onError: (e) {},
    );
  }

  void _emit() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sample = SensorSample(
      timestampMs: now,
      ax: _lastAx,
      ay: _lastAy,
      az: _lastAz,
      gx: _lastGx,
      gy: _lastGy,
      gz: _lastGz,
    );
    _controller.add(sample);
  }

  @override
  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
    _gyroSub?.cancel();
    _gyroSub = null;
  }
}
