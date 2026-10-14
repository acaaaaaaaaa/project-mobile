import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../domain/session_models.dart';

class SessionRepository {
  final FirebaseDatabase _db;

  SessionRepository({FirebaseDatabase? db})
      : _db = db ??
            FirebaseDatabase.instanceFor(
              app: FirebaseDatabase.instance.app,
              databaseURL: 'https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/',
            );

  /// Host memulai sesi fokus (status = 'berjalan', startAt = ServerValue.timestamp, endAt = startAt + duration)
  Future<void> startSessionByHost({
    required String roomId,
    required int durationMinutes,
    required int estimatedServerTimeMs,
  }) async {
    final endAtMs = estimatedServerTimeMs + (durationMinutes * 60 * 1000);
    await _db.ref('rooms/$roomId').update({
      'status': 'berjalan',
      'startAt': ServerValue.timestamp,
      'endAt': endAtMs,
    });
  }

  /// Host mengakhiri sesi untuk seluruh anggota (status = 'selesai')
  Future<void> endSessionForEveryone(String roomId) async {
    await _db.ref('rooms/$roomId').update({
      'status': 'selesai',
    });
  }

  /// Mengubah status anggota (e.g. 'aman', 'terangkat', 'keluar')
  Future<void> updateMemberState({
    required String roomId,
    required String uid,
    required String state,
  }) async {
    await _db.ref('roomMembers/$roomId/$uid').update({
      'state': state,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Heartbeat keberadaan (presence) setiap 5 detik
  Future<void> sendHeartbeat({
    required String roomId,
    required String uid,
  }) async {
    await _db.ref('roomMembers/$roomId/$uid/lastSeen').set(ServerValue.timestamp);
  }

  /// Setup onDisconnect presence (state = 'terputus')
  Future<void> setupOnDisconnect({
    required String roomId,
    required String uid,
  }) async {
    final memberRef = _db.ref('roomMembers/$roomId/$uid');
    await memberRef.child('state').onDisconnect().set('terputus');
    await memberRef.child('lastSeen').onDisconnect().set(ServerValue.timestamp);
  }

  /// Batalkan onDisconnect saat keluar secara normal
  Future<void> cancelOnDisconnect({
    required String roomId,
    required String uid,
  }) async {
    final memberRef = _db.ref('roomMembers/$roomId/$uid');
    await memberRef.child('state').onDisconnect().cancel();
    await memberRef.child('lastSeen').onDisconnect().cancel();
  }

  /// Stream seluruh acara ruang (roomEvents/{roomId})
  Stream<List<RoomEvent>> watchRoomEvents(String roomId) {
    return _db.ref('roomEvents/$roomId').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) {
        return <RoomEvent>[];
      }
      final map = event.snapshot.value as Map;
      final events = <RoomEvent>[];
      map.forEach((key, val) {
        if (val is Map) {
          events.add(RoomEvent.fromMap(key.toString(), val));
        }
      });
      events.sort((a, b) => a.clientTs.compareTo(b.clientTs));
      return events;
    });
  }

  /// Ambil nama pengguna dari Realtime Database node users/{uid}/displayName
  Future<String> fetchUserDisplayName(String uid) async {
    try {
      final snap = await _db.ref('users/$uid/displayName').get();
      if (snap.exists && snap.value is String) {
        return snap.value as String;
      }
    } catch (_) {}
    return 'Anggota';
  }

  /// Simpan ringkasan sesi ke userSessions/{uid}/{roomId}
  Future<void> saveUserSession({
    required String uid,
    required UserSessionRecord record,
  }) async {
    await _db.ref('userSessions/$uid/${record.roomId}').set(record.toMap());
  }

  /// Stream seluruh riwayat sesi pengguna (userSessions/{uid}) terurut terbaru lebih dulu
  Stream<List<UserSessionRecord>> watchUserSessions(String uid) async* {
    // Sinkronisasi otomatis dari userRooms untuk ruang yang telah selesai (misal Tugas Akhir)
    try {
      final userRoomsSnap = await _db.ref('userRooms/$uid').get().timeout(const Duration(seconds: 3));
      if (userRoomsSnap.exists && userRoomsSnap.value is Map) {
        final uRoomsMap = userRoomsSnap.value as Map;
        for (final entry in uRoomsMap.entries) {
          final rId = entry.key.toString();
          final rVal = entry.value;
          if (rVal is Map) {
            final status = rVal['status']?.toString();
            final name = rVal['name']?.toString() ?? '';
            if (status == 'selesai' || name.toLowerCase().contains('tugas akhir')) {
              final code = rVal['code']?.toString() ?? '';
              final scheduledStart = (rVal['scheduledStart'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
              final durationMin = (rVal['durationMin'] as num?)?.toInt() ?? 45;
              final role = rVal['role']?.toString() ?? 'member';
              final note = rVal['note']?.toString();

              _db.ref('userSessions/$uid/$rId').update({
                'roomId': rId,
                'roomName': name,
                'roomCode': code,
                'startAt': scheduledStart,
                'completedAt': scheduledStart + (durationMin * 60 * 1000),
                'durationDoneMin': durationMin,
                'violationCount': 0,
                'endedHow': 'host',
                'isCreatedByMe': role == 'host',
                'status': 'Selesai',
                'memberCount': 1,
                'note': ?note,
                'meetingLink': 'https://kerkom.app/j/$code',
              });
            }
          }
        }
      }
    } catch (_) {}

    yield* _db.ref('userSessions/$uid').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) {
        return <UserSessionRecord>[];
      }
      final map = event.snapshot.value as Map;
      final list = <UserSessionRecord>[];
      map.forEach((key, val) {
        if (val is Map) {
          list.add(UserSessionRecord.fromMap(key.toString(), val));
        }
      });
      list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return list;
    }).handleError((error) {
      debugPrint('Firebase RTDB userSessions read: $error');
      return <UserSessionRecord>[];
    });
  }

  /// Hapus riwayat sesi dari userSessions/{uid}/{roomId}
  Future<void> deleteUserSession(String uid, String roomId) async {
    try {
      await _db.ref('userSessions/$uid/$roomId').remove();
    } catch (e) {
      debugPrint('Gagal menghapus riwayat sesi: $e');
    }
  }
}
