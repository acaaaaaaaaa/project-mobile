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
    final now = DateTime.now().millisecondsSinceEpoch;
    final roomSnap = await _db.ref('rooms/$roomId').get();
    String? code;
    String name = 'Ruang Belajar';
    int durationMin = 45;
    int startAt = now;
    String hostUid = '';

    if (roomSnap.exists && roomSnap.value is Map) {
      final rMap = roomSnap.value as Map;
      code = rMap['code']?.toString();
      name = rMap['name']?.toString() ?? 'Ruang Belajar';
      durationMin = (rMap['durationMinutes'] as num?)?.toInt() ?? 45;
      startAt = (rMap['startAt'] as num?)?.toInt() ?? now;
      hostUid = rMap['hostUid']?.toString() ?? '';
    }

    final updates = <String, dynamic>{
      'rooms/$roomId/status': 'selesai',
      if (code != null) 'roomCodes/$code/active': false,
    };

    try {
      final membersSnap = await _db.ref('roomMembers/$roomId').get();
      if (membersSnap.exists && membersSnap.value is Map) {
        final membersMap = membersSnap.value as Map;
        membersMap.forEach((mUid, _) {
          updates['userRooms/$mUid/$roomId/status'] = 'selesai';
          updates['userActiveRoom/$mUid'] = null;
          updates['userSessions/$mUid/$roomId'] = {
            'roomId': roomId,
            'roomName': name,
            'roomCode': code ?? '',
            'startAt': startAt,
            'completedAt': now,
            'durationDoneMin': ((now - startAt) / 60000).ceil().clamp(1, durationMin),
            'violationCount': 0,
            'endedHow': 'host',
            'isCreatedByMe': mUid == hostUid,
            'status': 'Selesai',
            'memberCount': membersMap.length,
            'meetingLink': code != null ? 'https://kerkom.app/j/$code' : '',
          };
        });
      }
    } catch (_) {}

    await _db.ref().update(updates);
  }

  /// Mengubah status anggota (e.g. 'aman', 'terangkat', 'keluar')
  Future<void> updateMemberState({
    required String roomId,
    required String uid,
    required String state,
    String? memberName,
  }) async {
    await _db.ref('roomMembers/$roomId/$uid').update({
      'state': state,
      'lastSeen': ServerValue.timestamp,
    });

    if (state == 'keluar') {
      try {
        final name = memberName ?? 'Anggota';
        await _db.ref('roomEvents/$roomId').push().set({
          'uid': uid,
          'type': 'keluar',
          'title': '$name telah meninggalkan ruangan',
          'clientTs': DateTime.now().millisecondsSinceEpoch,
          'deltaTiltDeg': 0.0,
          'zScore': 0.0,
        });
      } catch (_) {}
    }
  }

  /// Sinkronisasi foto profil terkini ke roomMembers
  Future<void> syncMemberPhoto({
    required String roomId,
    required String uid,
    required String photoUrl,
  }) async {
    if (photoUrl.isEmpty) return;
    try {
      await _db.ref('roomMembers/$roomId/$uid/photoUrl').set(photoUrl);
    } catch (_) {}
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
    // Sinkronisasi otomatis: pastikan ruang yang belum selesai dibersihkan dari userSessions
    try {
      final userRoomsSnap = await _db.ref('userRooms/$uid').get().timeout(const Duration(seconds: 3));
      if (userRoomsSnap.exists && userRoomsSnap.value is Map) {
        final uRoomsMap = userRoomsSnap.value as Map;
        for (final entry in uRoomsMap.entries) {
          final rId = entry.key.toString();
          final rVal = entry.value;
          if (rVal is Map) {
            final status = rVal['status']?.toString().toLowerCase();
            final name = rVal['name']?.toString() ?? '';
            if (status != 'selesai') {
              // Jika ruang belum selesai (masih lobi/berjalan), pastikan TIDAK ADA di userSessions
              _db.ref('userSessions/$uid/$rId').remove();
            } else if (status == 'selesai' || name.toLowerCase().contains('tugas akhir')) {
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
          final rec = UserSessionRecord.fromMap(key.toString(), val);
          if (rec.status.toLowerCase() == 'selesai') {
            list.add(rec);
          }
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
