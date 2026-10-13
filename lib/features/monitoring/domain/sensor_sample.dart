import 'dart:math';

/// Representasi data cuplikan sensor independen (murni Dart, tanpa import Flutter)
class SensorSample {
  final int timestampMs;
  final double ax; // Akselerometer X (m/s^2)
  final double ay; // Akselerometer Y (m/s^2)
  final double az; // Akselerometer Z (m/s^2)
  final double gx; // Giroskop X (rad/s)
  final double gy; // Giroskop Y (rad/s)
  final double gz; // Giroskop Z (rad/s)

  const SensorSample({
    required this.timestampMs,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });

  /// Magnitudo Euclidean akselerasi total
  double get magnitude => sqrt(ax * ax + ay * ay + az * az);

  @override
  String toString() =>
      'Sample(t: $timestampMs, a: [${ax.toStringAsFixed(2)}, ${ay.toStringAsFixed(2)}, ${az.toStringAsFixed(2)}], g: [${gx.toStringAsFixed(2)}, ${gy.toStringAsFixed(2)}, ${gz.toStringAsFixed(2)}])';
}
