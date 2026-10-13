import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Process 9: Clock Synchronization via Firebase .info/serverTimeOffset
/// Menghitung sisa waktu sesi secara lokal tanpa memercayai jam lokal perangkat semata.
class ServerTimeService {
  final FirebaseDatabase? _db;
  int _offsetMs;
  StreamSubscription<DatabaseEvent>? _sub;

  ServerTimeService({FirebaseDatabase? db, int initialOffsetMs = 0})
      : _db = db,
        _offsetMs = initialOffsetMs {
    if (_db != null) {
      _init();
    }
  }

  void _init() {
    _sub = _db?.ref('.info/serverTimeOffset').onValue.listen((event) {
      final val = event.snapshot.value;
      if (val is num) {
        _offsetMs = val.toInt();
      }
    });
  }

  /// Offset server saat ini dalam milidetik
  int get offsetMs => _offsetMs;

  /// Estimasi waktu server saat ini (waktu perangkat lokal + offset server)
  int get nowServerMs => DateTime.now().millisecondsSinceEpoch + _offsetMs;

  /// Menghitung sisa detik sebelum endAtMs
  int getRemainingSeconds(int endAtMs) {
    final diffMs = endAtMs - nowServerMs;
    return diffMs > 0 ? (diffMs / 1000).ceil() : 0;
  }

  void dispose() {
    _sub?.cancel();
  }
}
