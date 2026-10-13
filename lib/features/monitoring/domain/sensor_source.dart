import 'dart:async';
import 'dart:math';
import 'sensor_sample.dart';

enum SimulationScenario {
  flatStill,
  deskVibration,
  slowLift30Deg,
  straightVerticalLift,
  smallNudge,
}

abstract class SensorSource {
  Stream<SensorSample> get sampleStream;
  void start();
  void stop();
}

/// Sumber sensor simulasi untuk pengujian deterministik dan debug menu di S16
class SimulatedSensorSource implements SensorSource {
  final _controller = StreamController<SensorSample>.broadcast();
  Timer? _timer;
  int _currentTimeMs = 0;
  SimulationScenario _scenario = SimulationScenario.flatStill;
  final Random _rng = Random(42);

  @override
  Stream<SensorSample> get sampleStream => _controller.stream;

  SimulationScenario get scenario => _scenario;

  void setScenario(SimulationScenario scenario) {
    _scenario = scenario;
    _currentTimeMs = 0;
  }

  @override
  void start() {
    stop();
    _currentTimeMs = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      _currentTimeMs += 20;
      final sample = generateSampleAtTime(_currentTimeMs, _scenario);
      _controller.add(sample);
    });
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Menghasilkan cuplikan deterministik berdasarkan waktu t (ms) dan skenario
  SensorSample generateSampleAtTime(int tMs, SimulationScenario scenario, [int startOffsetMs = 0]) {
    final tSec = max(0.0, (tMs - startOffsetMs) / 1000.0);
    const g = 9.80665;

    switch (scenario) {
      case SimulationScenario.flatStill:
        // Ponsel diam datar di meja dengan noise sensor wajar (~0.02 m/s^2)
        final noiseAx = (_rng.nextDouble() - 0.5) * 0.04;
        final noiseAy = (_rng.nextDouble() - 0.5) * 0.04;
        final noiseAz = (_rng.nextDouble() - 0.5) * 0.04;
        return SensorSample(
          timestampMs: tMs,
          ax: noiseAx,
          ay: noiseAy,
          az: g + noiseAz,
          gx: 0.0,
          gy: 0.0,
          gz: 0.0,
        );

      case SimulationScenario.deskVibration:
        // Getaran meja frekuensi tinggi (18 Hz), magnitudo bergetar tetapi orientasi rata-rata tetap 0 derajat
        final vibAx = sin(2 * pi * 18.0 * tSec) * 1.5;
        final vibAy = cos(2 * pi * 18.0 * tSec) * 1.5;
        final vibAz = sin(2 * pi * 36.0 * tSec) * 2.0;
        final vibGx = sin(2 * pi * 18.0 * tSec) * 0.15;
        final vibGy = cos(2 * pi * 18.0 * tSec) * 0.15;
        return SensorSample(
          timestampMs: tMs,
          ax: vibAx,
          ay: vibAy,
          az: g + vibAz,
          gx: vibGx,
          gy: vibGy,
          gz: 0.0,
        );

      case SimulationScenario.slowLift30Deg:
        // Mengangkat perlahan hingga 30 derajat selama rentang 1 detik (misal t = 1.0 s s/d 2.0 s)
        double pitchDeg = 0.0;
        double gy = 0.0;
        if (tSec >= 1.0 && tSec <= 2.0) {
          final progress = tSec - 1.0;
          pitchDeg = 30.0 * progress;
          gy = (30.0 * pi / 180.0); // Kecepatan sudut konstan (rad/s)
        } else if (tSec > 2.0) {
          pitchDeg = 30.0;
          gy = 0.0;
        }

        final pitchRad = pitchDeg * pi / 180.0;
        // Pada kemiringan konstan / lambat: magnitudo akselerasi tetap persis g (9.8 m/s^2)
        final ax = -g * sin(pitchRad);
        final ay = 0.0;
        final az = g * cos(pitchRad);

        return SensorSample(
          timestampMs: tMs,
          ax: ax,
          ay: ay,
          az: az,
          gx: 0.0,
          gy: gy,
          gz: 0.0,
        );

      case SimulationScenario.straightVerticalLift:
        // Mengangkat lurus vertikal ke atas tanpa miring (t = 1.0 s s/d 1.8 s)
        // Menghasilkan percepatan linier vertikal tambahan +4.0 m/s^2
        double extraAz = 0.0;
        if (tSec >= 1.0 && tSec <= 1.8) {
          extraAz = 4.0;
        }
        return SensorSample(
          timestampMs: tMs,
          ax: 0.0,
          ay: 0.0,
          az: g + extraAz,
          gx: 0.0,
          gy: 0.0,
          gz: 0.0,
        );

      case SimulationScenario.smallNudge:
        // Senggolan kecil 3 derajat sekilas pada t = 1.0 s s/d 1.3 s lalu kembali ke 0
        double pitchDeg = 0.0;
        double gy = 0.0;
        if (tSec >= 1.0 && tSec <= 1.2) {
          pitchDeg = 3.0 * ((tSec - 1.0) / 0.2);
          gy = 0.1;
        } else if (tSec > 1.2 && tSec <= 1.4) {
          pitchDeg = 3.0 * (1.0 - (tSec - 1.2) / 0.2);
          gy = -0.1;
        }
        final pitchRad = pitchDeg * pi / 180.0;
        return SensorSample(
          timestampMs: tMs,
          ax: -g * sin(pitchRad),
          ay: 0.0,
          az: g * cos(pitchRad),
          gx: 0.0,
          gy: gy,
          gz: 0.0,
        );
    }
  }
}

/// Sampler yang menyatukan sumber aktif dan mendistribusikan aliran sampel
class Sampler {
  SensorSource _activeSource;
  StreamSubscription<SensorSample>? _sub;
  final _outputController = StreamController<SensorSample>.broadcast();

  Sampler({required SensorSource initialSource}) : _activeSource = initialSource;

  Stream<SensorSample> get sampleStream => _outputController.stream;
  SensorSource get activeSource => _activeSource;

  void setSource(SensorSource newSource) {
    if (_activeSource == newSource) return;
    _sub?.cancel();
    _activeSource.stop();
    _activeSource = newSource;
    _activeSource.start();
    _sub = _activeSource.sampleStream.listen(_outputController.add);
  }

  void start() {
    _sub?.cancel();
    _activeSource.start();
    _sub = _activeSource.sampleStream.listen(_outputController.add);
  }

  void stop() {
    _sub?.cancel();
    _activeSource.stop();
  }
}
