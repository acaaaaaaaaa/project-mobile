import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/real_sensor_source.dart';
import '../domain/csv_logger.dart';
import '../domain/monitor_config.dart';
import '../domain/monitor_controller.dart';
import '../domain/sensor_source.dart';

final realSensorSourceProvider = Provider<RealSensorSource>((ref) {
  return RealSensorSource();
});

final simulatedSensorSourceProvider = Provider<SimulatedSensorSource>((ref) {
  return SimulatedSensorSource();
});

final samplerProvider = Provider<Sampler>((ref) {
  final realSource = ref.watch(realSensorSourceProvider);
  return Sampler(initialSource: realSource);
});

final debugCsvLoggerProvider = Provider<DebugCsvLogger>((ref) {
  return DebugCsvLogger();
});

final monitorControllerProvider = Provider<MonitorController>((ref) {
  final sampler = ref.watch(samplerProvider);
  final logger = ref.watch(debugCsvLoggerProvider);
  final controller = MonitorController(
    sampler: sampler,
    config: const MonitorConfig(),
    csvLogger: logger,
  );
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Stream snapshot telemetri sensor live
final monitorSnapshotProvider = StreamProvider<MonitorSnapshot>((ref) {
  final controller = ref.watch(monitorControllerProvider);
  return controller.snapshotStream;
});
