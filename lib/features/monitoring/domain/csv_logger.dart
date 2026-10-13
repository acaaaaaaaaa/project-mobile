import 'sensor_sample.dart';

class CsvLogRow {
  final int timestampMs;
  final double ax, ay, az;
  final double gx, gy, gz;
  final double roll, pitch, deltaTilt;
  final double zScore;
  final String state;

  const CsvLogRow({
    required this.timestampMs,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.roll,
    required this.pitch,
    required this.deltaTilt,
    required this.zScore,
    required this.state,
  });

  String toCsv() =>
      '$timestampMs,${ax.toStringAsFixed(3)},${ay.toStringAsFixed(3)},${az.toStringAsFixed(3)},${gx.toStringAsFixed(3)},${gy.toStringAsFixed(3)},${gz.toStringAsFixed(3)},${roll.toStringAsFixed(2)},${pitch.toStringAsFixed(2)},${deltaTilt.toStringAsFixed(2)},${zScore.toStringAsFixed(2)},$state';
}

class DebugCsvLogger {
  static const String csvHeader =
      'timestampMs,ax,ay,az,gx,gy,gz,roll,pitch,deltaTilt,zScore,state';

  final List<CsvLogRow> _rows = [];
  bool enabled = true;

  int get recordedRows => _rows.length;
  List<CsvLogRow> get rows => List.unmodifiable(_rows);

  void clear() {
    _rows.clear();
  }

  void log({
    required SensorSample sample,
    required double roll,
    required double pitch,
    required double deltaTilt,
    required double zScore,
    required String state,
  }) {
    if (!enabled) return;
    _rows.add(
      CsvLogRow(
        timestampMs: sample.timestampMs,
        ax: sample.ax,
        ay: sample.ay,
        az: sample.az,
        gx: sample.gx,
        gy: sample.gy,
        gz: sample.gz,
        roll: roll,
        pitch: pitch,
        deltaTilt: deltaTilt,
        zScore: zScore,
        state: state,
      ),
    );
  }

  String exportCsv() {
    final buffer = StringBuffer()..writeln(csvHeader);
    for (final row in _rows) {
      buffer.writeln(row.toCsv());
    }
    return buffer.toString();
  }
}
