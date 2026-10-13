import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class QueuedViolationEvent {
  final String roomId;
  final String pushKey;
  final String uid;
  final int clientTs;
  final double deltaTiltDeg;
  final double zScore;
  int attempts;

  QueuedViolationEvent({
    required this.roomId,
    required this.pushKey,
    required this.uid,
    required this.clientTs,
    required this.deltaTiltDeg,
    required this.zScore,
    this.attempts = 0,
  });
}

/// Process 10: Offline Event Queue dengan Exponential Backoff & Full Jitter
/// Base: 500 ms, Cap: 30 s. Menggunakan pushKey YANG SAMA persis sehingga tidak ada duplikasi.
class OfflineEventQueue {
  final FirebaseDatabase? _db;
  final List<QueuedViolationEvent> _queue = [];
  final Random _rng = Random();
  bool _isProcessing = false;

  static const int baseMs = 500;
  static const int capMs = 30000;

  OfflineEventQueue({FirebaseDatabase? db}) : _db = db;

  List<QueuedViolationEvent> get pendingEvents => List.unmodifiable(_queue);

  /// Menambahkan pelanggaran ke antrean dan memulai pengiriman
  Future<void> enqueueAndSend({
    required String roomId,
    required String uid,
    required int clientTs,
    required double deltaTiltDeg,
    required double zScore,
  }) async {
    // 1. Generate pushKey sekali saja sebelum mencoba mengirim
    final pushKey = _db?.ref('roomEvents/$roomId').push().key ??
        '-OJ${DateTime.now().microsecondsSinceEpoch}';

    final queued = QueuedViolationEvent(
      roomId: roomId,
      pushKey: pushKey,
      uid: uid,
      clientTs: clientTs,
      deltaTiltDeg: deltaTiltDeg,
      zScore: zScore,
      attempts: 0,
    );

    _queue.add(queued);
    _processQueue();
  }

  void _processQueue() {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    _sendNext();
  }

  Future<void> _sendNext() async {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    if (_db == null) {
      _queue.removeAt(0);
      _isProcessing = false;
      _processQueue();
      return;
    }

    final item = _queue.first;

    try {
      // 1. Tulis ke roomEvents/{roomId}/{pushKey}
      final eventRef = _db.ref('roomEvents/${item.roomId}/${item.pushKey}');
      await eventRef.set({
        'type': 'violation',
        'uid': item.uid,
        'tsServer': ServerValue.timestamp,
        'clientTs': item.clientTs,
        'deltaTiltDeg': item.deltaTiltDeg,
        'zScore': item.zScore,
      });

      // 2. Perbarui status anggota ke 'terangkat' dan naikkan liftCount
      final memberRef = _db.ref('roomMembers/${item.roomId}/${item.uid}');
      await memberRef.update({
        'state': 'terangkat',
      });
      await memberRef.child('liftCount').runTransaction((mutableData) {
        final currentVal = (mutableData as num?)?.toInt() ?? 0;
        return Transaction.success(currentVal + 1);
      });

      // Berhasil terkirim! Hapus dari antrean
      _queue.removeAt(0);
      debugPrint('Process 10: Event ${item.pushKey} berhasil terkirim ke RTDB.');

      _isProcessing = false;
      _processQueue();
    } catch (e) {
      item.attempts++;
      debugPrint('Process 10: Write gagal (percobaan ke-${item.attempts}): $e');

      // Hitung Full Jitter: temp = min(cap, base * 2^attempts); sleep = random(0, temp)
      final temp = min(capMs, baseMs * pow(2, min(item.attempts, 10)).toInt());
      final jitterDelayMs = (_rng.nextDouble() * temp).round();

      debugPrint('Process 10: Menjadwalkan retry dalam ${jitterDelayMs}ms dengan pushKey: ${item.pushKey}');

      Timer(Duration(milliseconds: jitterDelayMs), () {
        _isProcessing = false;
        _processQueue();
      });
    }
  }

  void clear() {
    _queue.clear();
    _isProcessing = false;
  }
}
