import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_room/features/monitoring/domain/monitor_config.dart';
import 'package:focus_room/features/monitoring/domain/monitor_controller.dart';
import 'package:focus_room/features/monitoring/domain/sensor_sample.dart';
import 'package:focus_room/features/monitoring/domain/sensor_source.dart';

void main() {
  group('Sensor Engine Pure Dart Unit Tests', () {
    late SimulatedSensorSource simSource;
    late Sampler sampler;
    late MonitorController controller;

    setUp(() {
      simSource = SimulatedSensorSource();
      sampler = Sampler(initialSource: simSource);
      controller = MonitorController(
        sampler: sampler,
        config: const MonitorConfig(tiltToleranceDeg: 15.0),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    void calibrateStill() {
      controller.startCalibration();
      for (int t = 20; t <= 3100; t += 20) {
        final sample = simSource.generateSampleAtTime(t, SimulationScenario.flatStill);
        controller.processSample(sample);
      }
      expect(controller.state, MonitorState.armed);
      expect(controller.calibration, isNotNull);
    }

    test('(a) flat and still -> no violation', () {
      calibrateStill();

      bool violationOccurred = false;
      controller.eventStream.listen((_) => violationOccurred = true);

      for (int t = 3120; t <= 5500; t += 20) {
        final sample = simSource.generateSampleAtTime(t, SimulationScenario.flatStill, 3100);
        controller.processSample(sample);
      }

      expect(violationOccurred, isFalse);
      expect(controller.state, MonitorState.armed);
    });

    test('(b) vibration bursts with constant tilt -> no violation', () {
      calibrateStill();

      bool violationOccurred = false;
      controller.eventStream.listen((_) => violationOccurred = true);

      for (int t = 3120; t <= 6500; t += 20) {
        final sample = simSource.generateSampleAtTime(t, SimulationScenario.deskVibration, 3100);
        controller.processSample(sample);
      }

      expect(violationOccurred, isFalse);
      expect(controller.state, MonitorState.armed);
    });

    test('(c) slow 30 deg tilt over 1 s -> violation', () {
      calibrateStill();

      ViolationEvent? violationEvent;
      controller.eventStream.listen((e) => violationEvent = e);

      for (int t = 3120; t <= 6200; t += 20) {
        final sample = simSource.generateSampleAtTime(t, SimulationScenario.slowLift30Deg, 3100);
        controller.processSample(sample);
      }

      expect(controller.state, MonitorState.violation);
      expect(violationEvent, isNotNull);
      expect(violationEvent!.deltaTilt, greaterThan(15.0));
    });

    test('(d) straight vertical lift -> violation via z-score', () {
      calibrateStill();

      ViolationEvent? violationEvent;
      controller.eventStream.listen((e) => violationEvent = e);

      // Skenario: t=1s s/d 1.8s percepatan vertikal ke atas (+4 m/s^2) tanpa kemiringan
      for (int t = 3120; t <= 5200; t += 20) {
        final sample = simSource.generateSampleAtTime(t, SimulationScenario.straightVerticalLift, 3100);
        controller.processSample(sample);
      }

      expect(controller.state, MonitorState.violation);
      expect(violationEvent, isNotNull);
      expect(violationEvent!.zScore, greaterThan(6.0));
    });

    test('(e) a 3 deg nudge -> no violation', () {
      calibrateStill();

      bool violationOccurred = false;
      controller.eventStream.listen((_) => violationOccurred = true);

      for (int t = 3120; t <= 5500; t += 20) {
        final sample = simSource.generateSampleAtTime(t, SimulationScenario.smallNudge, 3100);
        controller.processSample(sample);
      }

      expect(violationOccurred, isFalse);
      expect(controller.state, MonitorState.armed);
    });

    test('(f) hovering around the threshold does not flap (hysteresis test)', () {
      calibrateStill();

      const g = 9.80665;
      int t = 3120;

      void transitionAngle(double fromDeg, double toDeg, int durationMs) {
        final steps = durationMs ~/ 20;
        final gyroRad = steps > 0
            ? ((toDeg - fromDeg) * pi / 180.0) / (durationMs / 1000.0)
            : 0.0;
        for (int i = 0; i <= steps; i++) {
          t += 20;
          final deg = fromDeg + (toDeg - fromDeg) * (i / steps);
          final rad = deg * pi / 180.0;
          final sample = SensorSample(
            timestampMs: t,
            ax: -g * sin(rad),
            ay: 0.0,
            az: g * cos(rad),
            gx: 0.0,
            gy: i == steps ? 0.0 : gyroRad,
            gz: 0.0,
          );
          controller.processSample(sample);
        }
      }

      void holdAngle(double deg, int durationMs) {
        final steps = durationMs ~/ 20;
        final rad = deg * pi / 180.0;
        for (int i = 0; i < steps; i++) {
          t += 20;
          final sample = SensorSample(
            timestampMs: t,
            ax: -g * sin(rad),
            ay: 0.0,
            az: g * cos(rad),
            gx: 0.0,
            gy: 0.0,
            gz: 0.0,
          );
          controller.processSample(sample);
        }
      }

      // 1. Naik perlahan ke 14 deg (di bawah T_high 15 deg)
      transitionAngle(0.0, 14.0, 1000);
      holdAngle(14.0, 1000);
      expect(controller.state, MonitorState.armed);

      // 2. Naik ke 16 deg (di atas T_high 15 deg)
      transitionAngle(14.0, 16.0, 500);
      holdAngle(16.0, 1000);
      expect(controller.state, MonitorState.violation);

      // 3. Turun sedikit ke 12 deg (di bawah T_high 15 deg, tetapi di atas T_low 7.5 deg)
      // Hysteresis: tetap VIOLATION, tidak flapping ke armed!
      transitionAngle(16.0, 12.0, 500);
      holdAngle(12.0, 1000);
      expect(controller.state, MonitorState.violation);

      // 4. Turun ke 5 deg (di bawah T_low 7.5 deg)
      // Pulih bersih kembali ke ARMED
      transitionAngle(12.0, 5.0, 500);
      holdAngle(5.0, 1000);
      expect(controller.state, MonitorState.armed);
    });
  });
}
