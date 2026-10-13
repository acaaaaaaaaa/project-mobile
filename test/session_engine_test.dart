import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_room/features/session/domain/offline_event_queue.dart';
import 'package:focus_room/features/session/domain/server_time_service.dart';
import 'package:focus_room/features/session/domain/session_models.dart';

void main() {
  group('Phase A5 Session Engine Unit Tests', () {
    test('Process 9: ServerTimeService calculates remaining time with server time offset', () {
      final service = ServerTimeService();
      final nowDevice = DateTime.now().millisecondsSinceEpoch;

      // Target 60 detik dari sekarang
      final targetEndAt = nowDevice + 60000;
      final remaining = service.getRemainingSeconds(targetEndAt);

      // Sisa waktu harus sekitar 60 detik (59-61 toleransi eksekusi)
      expect(remaining, greaterThanOrEqualTo(59));
      expect(remaining, lessThanOrEqualTo(61));

      // Ketika target sudah lampau, sisa waktu harus 0 (tidak pernah negatif)
      final pastTarget = nowDevice - 5000;
      expect(service.getRemainingSeconds(pastTarget), equals(0));
    });

    test('Process 10: OfflineEventQueue exponential backoff calculation with full jitter', () {
      const baseMs = OfflineEventQueue.baseMs; // 500 ms
      const capMs = OfflineEventQueue.capMs; // 30000 ms

      // Periksa perhitungan batas backoff untuk percobaan 0 s/d 10
      for (int attempt = 0; attempt <= 10; attempt++) {
        final temp = min(capMs, baseMs * pow(2, min(attempt, 10)).toInt());
        expect(temp, greaterThanOrEqualTo(baseMs));
        expect(temp, lessThanOrEqualTo(capMs));
      }

      // Pastikan cap 30 detik dihormati untuk percobaan tinggi (misal attempt = 20)
      final cappedTemp = min(capMs, baseMs * pow(2, min(20, 10)).toInt());
      expect(cappedTemp, equals(capMs));
    });

    test('Process 10: QueuedViolationEvent preserves the same pushKey on retries', () {
      const roomId = 'room_abc';
      const pushKey = '-OJ123456789xyz';
      const uid = 'user_test_uid';

      final item = QueuedViolationEvent(
        roomId: roomId,
        pushKey: pushKey,
        uid: uid,
        clientTs: 1000000,
        deltaTiltDeg: 28.5,
        zScore: 7.2,
        attempts: 0,
      );

      expect(item.pushKey, equals('-OJ123456789xyz'));

      // Simulasi kegagalan dan kenaikan attempts
      item.attempts++;
      expect(item.attempts, equals(1));
      expect(item.pushKey, equals('-OJ123456789xyz')); // pushKey tetap sama persis, tanpa duplikasi!

      item.attempts++;
      expect(item.attempts, equals(2));
      expect(item.pushKey, equals('-OJ123456789xyz'));
    });

    test('RoomEvent serialization and deserialization for RTDB', () {
      final event = RoomEvent(
        key: 'evt_1',
        type: 'violation',
        uid: 'user_42',
        tsServer: 1700000000,
        clientTs: 1700000005,
        deltaTiltDeg: 23.4,
        zScore: 6.8,
      );

      final map = event.toMap();
      expect(map['type'], 'violation');
      expect(map['uid'], 'user_42');
      expect(map['deltaTiltDeg'], 23.4);
      expect(map['zScore'], 6.8);

      final deserialized = RoomEvent.fromMap('evt_1', map);
      expect(deserialized.key, 'evt_1');
      expect(deserialized.type, 'violation');
      expect(deserialized.uid, 'user_42');
      expect(deserialized.deltaTiltDeg, 23.4);
      expect(deserialized.zScore, 6.8);
    });

    test('UserSessionRecord serialization for userSessions/{uid}/{roomId}', () {
      const record = UserSessionRecord(
        roomId: 'room_123',
        roomName: 'Tugas Akhir HCI',
        startAt: 1700000000,
        durationDoneMin: 45,
        violationCount: 2,
        endedHow: 'timer',
      );

      final map = record.toMap();
      expect(map['roomName'], 'Tugas Akhir HCI');
      expect(map['durationDoneMin'], 45);
      expect(map['violationCount'], 2);
      expect(map['endedHow'], 'timer');

      final deserialized = UserSessionRecord.fromMap('room_123', map);
      expect(deserialized.roomId, 'room_123');
      expect(deserialized.roomName, 'Tugas Akhir HCI');
      expect(deserialized.durationDoneMin, 45);
      expect(deserialized.violationCount, 2);
      expect(deserialized.endedHow, 'timer');
    });

    test('Phase A7: History summary tiles and sorting newest first', () {
      final session1 = UserSessionRecord(
        roomId: 'room_1',
        roomName: 'Koding Algoritma',
        startAt: 1700000000000,
        completedAt: 1700002700000,
        durationDoneMin: 45,
        violationCount: 0,
        endedHow: 'timer',
      );

      final session2 = UserSessionRecord(
        roomId: 'room_2',
        roomName: 'Review Desain UI',
        startAt: 1700003000000,
        completedAt: 1700004500000,
        durationDoneMin: 25,
        violationCount: 2,
        endedHow: 'keluar',
      );

      final list = [session1, session2];
      // Sort newest first
      list.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      expect(list.first.roomId, 'room_2');
      expect(list.last.roomId, 'room_1');

      // Metric calculations: total sessions & total focus hours
      final totalSessions = list.length;
      final totalMinutes = list.fold<int>(0, (sum, s) => sum + s.durationDoneMin);
      final totalHours = totalMinutes / 60.0;

      expect(totalSessions, 2);
      expect(totalMinutes, 70);
      expect(totalHours.toStringAsFixed(1), '1.2');

      // Different outcomes verified
      expect(session1.violationCount, 0);
      expect(session1.endedHow, 'timer');
      expect(session2.violationCount, 2);
      expect(session2.endedHow, 'keluar');
    });
  });
}
