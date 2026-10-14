import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../domain/room_models.dart';

class RoomRepository {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  RoomRepository({
    FirebaseDatabase? db,
    FirebaseAuth? auth,
  })  : _db = db ??
            FirebaseDatabase.instanceFor(
              app: FirebaseDatabase.instance.app,
              databaseURL: 'https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/',
            ),
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// Karakter alfanumerik tanpa 0, O, 1, I (untuk menghindari ambiguitas)
  static const String _codeAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  String _generateRandomCandidateCode() {
    final random = Random();
    return List.generate(6, (_) => _codeAlphabet[random.nextInt(_codeAlphabet.length)]).join(); // e.g. K7M2Q9
  }

  /// Membuat Ruang Baru dengan Transaksi Atomik pada roomCodes/{code}
  Future<RoomModel> createRoom({
    required String name,
    required int durationMinutes,
    String? reminder,
    String? note,
    int? scheduledStart,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum terautentikasi';

    final cleanName = name.trim();
    if (cleanName.isEmpty) throw 'Nama ruang belajar wajib diisi';

    // 1. Dapatkan nama profil pengguna terkini dari users/{uid}
    String displayName = user.displayName ?? 'Host';
    String photoUrl = user.photoURL ?? '';
    try {
      final userSnap = await _db.ref('users/${user.uid}').get();
      if (userSnap.exists && userSnap.value is Map) {
        final userMap = userSnap.value as Map;
        displayName = userMap['displayName']?.toString() ?? displayName;
        photoUrl = userMap['photoUrl']?.toString() ?? photoUrl;
      }
    } catch (_) {}

    final roomId = _uuid.v4();
    String? assignedCode;

    // 2. Loop transaction atau set langsung untuk kode ruang
    for (int attempt = 0; attempt < 5; attempt++) {
      final candidateCode = _generateRandomCandidateCode();
      final codeRef = _db.ref('roomCodes/$candidateCode');

      try {
        final result = await codeRef.runTransaction((currentData) {
          if (currentData == null) {
            return Transaction.success({
              'roomId': roomId,
              'createdAt': ServerValue.timestamp,
              'active': true,
            });
          }
          return Transaction.abort();
        });

        if (result.committed) {
          assignedCode = candidateCode;
          break;
        }
      } catch (e) {
        // Fallback jika database rules memerlukan penulisan langsung
        try {
          await codeRef.set({
            'roomId': roomId,
            'createdAt': ServerValue.timestamp,
            'active': true,
          });
          assignedCode = candidateCode;
          break;
        } catch (_) {
          assignedCode = candidateCode;
          break;
        }
      }
    }

    assignedCode ??= _generateRandomCandidateCode();

    final now = DateTime.now().millisecondsSinceEpoch;
    final startTimestamp = scheduledStart ?? now;

    final room = RoomModel(
      id: roomId,
      code: assignedCode,
      name: cleanName,
      hostUid: user.uid,
      durationMinutes: durationMinutes,
      status: 'lobi',
      createdAt: now,
      startAt: startTimestamp,
      remainingSeconds: durationMinutes * 60,
      reminder: reminder,
      note: note,
    );

    final hostMember = RoomMemberModel(
      uid: user.uid,
      name: displayName,
      photoUrl: photoUrl,
      isHost: true,
      state: 'siap',
      joinedAt: now,
    );

    // Multi-path atomic write untuk rooms, roomCodes, roomMembers, userRooms, userActiveRoom, userSessions
    final updates = <String, dynamic>{
      'rooms/$roomId': room.toMap(),
      'roomMembers/$roomId/${user.uid}': hostMember.toMap(),
      'userActiveRoom/${user.uid}': {
        'roomId': roomId,
        'roomCode': assignedCode,
        'roomName': cleanName,
        'status': 'lobi',
      },
      'userRooms/${user.uid}/$roomId': {
        'roomId': roomId,
        'name': cleanName,
        'code': assignedCode,
        'scheduledStart': startTimestamp,
        'durationMin': durationMinutes,
        'role': 'host',
        'status': 'lobi',
        'note': note ?? '',
        'reminder': reminder ?? '',
        'createdAt': now,
      },
      'userSessions/${user.uid}/$roomId': {
        'roomId': roomId,
        'roomName': cleanName,
        'roomCode': assignedCode,
        'startAt': startTimestamp,
        'completedAt': startTimestamp + (durationMinutes * 60 * 1000),
        'durationDoneMin': durationMinutes,
        'violationCount': 0,
        'endedHow': 'host',
        'isCreatedByMe': true,
        'status': 'Selesai',
        'memberCount': 1,
        'note': note ?? '',
        'meetingLink': 'https://kerkom.app/j/$assignedCode',
      },
    };

    try {
      await _db.ref().update(updates);
    } catch (e) {
      // Fallback single-set jika partial permission
      try {
        await _db.ref('rooms/$roomId').set(room.toMap());
        await _db.ref('userRooms/${user.uid}/$roomId').set(updates['userRooms/${user.uid}/$roomId']);
      } catch (_) {}
    }

    return room;
  }

  /// Bergabung ke Ruang Belajar via Kode (S06)
  Future<RoomModel> joinRoomByCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum terautentikasi';

    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) throw 'Kode ruang wajib diisi';

    // 1. Cek validitas kode di roomCodes/{code}
    var codeSnap = await _db.ref('roomCodes/$cleanCode').get();
    if (!codeSnap.exists) {
      final stripped = cleanCode.replaceAll('-', '');
      codeSnap = await _db.ref('roomCodes/$stripped').get();
    }
    if (!codeSnap.exists || codeSnap.value is! Map) {
      throw 'Kode tidak ditemukan atau sesi sudah selesai';
    }

    final codeData = codeSnap.value as Map;
    if (codeData['active'] != true) {
      throw 'Kode tidak ditemukan atau sesi sudah selesai';
    }

    final roomId = codeData['roomId']?.toString();
    if (roomId == null) throw 'Kode tidak ditemukan atau sesi sudah selesai';

    // 2. Ambil detail room di rooms/{roomId}
    final roomSnap = await _db.ref('rooms/$roomId').get();
    if (!roomSnap.exists || roomSnap.value is! Map) {
      throw 'Kode tidak ditemukan atau sesi sudah selesai';
    }

    final room = RoomModel.fromMap(roomId, roomSnap.value as Map);
    if (room.status == 'selesai') {
      throw 'Kode tidak ditemukan atau sesi sudah selesai';
    }

    // 3. Ambil data nama pengguna terkini dari users/{uid}
    final userSnap = await _db.ref('users/${user.uid}').get();
    String displayName = user.displayName ?? 'Anggota';
    String photoUrl = user.photoURL ?? '';
    if (userSnap.exists && userSnap.value is Map) {
      final userMap = userSnap.value as Map;
      displayName = userMap['displayName']?.toString() ?? displayName;
      photoUrl = userMap['photoUrl']?.toString() ?? photoUrl;
    }

    // 4. Masukkan ke roomMembers/{roomId}/{uid}
    final isHost = room.hostUid == user.uid;
    final now = DateTime.now().millisecondsSinceEpoch;
    final member = RoomMemberModel(
      uid: user.uid,
      name: displayName,
      photoUrl: photoUrl,
      isHost: isHost,
      state: 'siap',
      joinedAt: now,
    );

    final updates = <String, dynamic>{
      'roomMembers/$roomId/${user.uid}': member.toMap(),
      'userActiveRoom/${user.uid}': {
        'roomId': roomId,
        'roomCode': room.code,
        'roomName': room.name,
        'status': room.status,
      },
      'userRooms/${user.uid}/$roomId': {
        'roomId': roomId,
        'name': room.name,
        'code': room.code,
        'scheduledStart': room.startAt ?? room.createdAt,
        'durationMin': room.durationMinutes,
        'role': isHost ? 'host' : 'member',
        'status': room.status,
        'note': room.note ?? '',
        'reminder': room.reminder ?? '',
        'createdAt': room.createdAt,
      },
    };

    await _db.ref().update(updates);

    return room;
  }

  /// Stream perubahan detail room real-time
  Stream<RoomModel?> watchRoom(String roomId) async* {
    if (roomId.isEmpty) {
      yield null;
      return;
    }

    // 1. Ambil data awal secara cepat (get) dengan timeout
    // Mencegah lobi menggantung di loading spinner saat koneksi realtime di web lambat terhubung
    try {
      final snap = await _db.ref('rooms/$roomId').get().timeout(const Duration(seconds: 4));
      if (snap.exists && snap.value is Map) {
        yield RoomModel.fromMap(roomId, snap.value as Map);
      } else {
        // Fallback: periksa node userRooms/{uid}/{roomId} jika room dibuat dengan format userRooms
        final uid = currentUid;
        if (uid != null) {
          final userRoomSnap = await _db.ref('userRooms/$uid/$roomId').get().timeout(const Duration(seconds: 2));
          if (userRoomSnap.exists && userRoomSnap.value is Map) {
            final uMap = userRoomSnap.value as Map;
            yield RoomModel(
              id: roomId,
              code: uMap['code']?.toString() ?? roomId,
              name: uMap['name']?.toString() ?? 'Ruang Belajar',
              hostUid: (uMap['role'] == 'host' ? uid : ''),
              durationMinutes: (uMap['durationMin'] as num?)?.toInt() ?? 45,
              status: uMap['status']?.toString() ?? 'lobi',
              createdAt: (uMap['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
              remainingSeconds: ((uMap['durationMin'] as num?)?.toInt() ?? 45) * 60,
              reminder: uMap['reminder']?.toString(),
              note: uMap['note']?.toString(),
            );
          } else {
            yield null;
          }
        } else {
          yield null;
        }
      }
    } catch (_) {
      // Jika get timeout atau koneksi lambat, lanjutkan ke listener onValue
    }

    // 2. Stream real-time pembaruan data
    yield* _db.ref('rooms/$roomId').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        return RoomModel.fromMap(roomId, event.snapshot.value as Map);
      }
      return null;
    }).handleError((_) => null);
  }

  /// Stream daftar anggota room real-time
  Stream<List<RoomMemberModel>> watchRoomMembers(String roomId) async* {
    if (roomId.isEmpty) {
      yield <RoomMemberModel>[];
      return;
    }

    // Ambil data awal anggota secara cepat
    try {
      final snap = await _db.ref('roomMembers/$roomId').get().timeout(const Duration(seconds: 4));
      if (snap.exists && snap.value is Map) {
        final membersMap = snap.value as Map;
        final list = <RoomMemberModel>[];
        membersMap.forEach((key, val) {
          if (val is Map) {
            final m = RoomMemberModel.fromMap(key.toString(), val);
            if (m.state != 'keluar') {
              list.add(m);
            }
          }
        });
        list.sort((a, b) {
          if (a.isHost) return -1;
          if (b.isHost) return 1;
          return a.joinedAt.compareTo(b.joinedAt);
        });
        yield list;
      }
    } catch (_) {}

    // Stream real-time anggota
    yield* _db.ref('roomMembers/$roomId').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final membersMap = event.snapshot.value as Map;
        final list = <RoomMemberModel>[];
        membersMap.forEach((key, val) {
          if (val is Map) {
            final m = RoomMemberModel.fromMap(key.toString(), val);
            if (m.state != 'keluar') {
              list.add(m);
            }
          }
        });
        // Urutkan host pertama, kemudian berdasarkan waktu join
        list.sort((a, b) {
          if (a.isHost) return -1;
          if (b.isHost) return 1;
          return a.joinedAt.compareTo(b.joinedAt);
        });
        return list;
      }
      return <RoomMemberModel>[];
    }).handleError((_) => <RoomMemberModel>[]);
  }

  /// Stream seluruh daftar room aktif untuk Tab Daftar Ruang
  Stream<List<RoomModel>> watchAllRooms() {
    return _db.ref('rooms').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final map = event.snapshot.value as Map;
        final list = <RoomModel>[];
        map.forEach((k, v) {
          if (v is Map) {
            final r = RoomModel.fromMap(k.toString(), v);
            if (r.status != 'selesai') {
              list.add(r);
            }
          }
        });
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }
      return <RoomModel>[];
    }).handleError((_) => <RoomModel>[]);
  }

  /// Stream room aktif pengguna saat ini (untuk banner amber di S04)
  Stream<Map<String, dynamic>?> watchUserActiveRoom(String uid) {
    return _db.ref('userActiveRoom/$uid').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Stream riwayat 3 sesi terakhir pengguna
  Stream<List<UserSessionHistory>> watchRecentSessions(String uid) {
    return _db.ref('userSessions/$uid').limitToLast(3).onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final map = event.snapshot.value as Map;
        final list = <UserSessionHistory>[];
        map.forEach((k, v) {
          if (v is Map) {
            list.add(UserSessionHistory.fromMap(k.toString(), v));
          }
        });
        list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return list;
      }
      return [];
    });
  }

  /// Ubah status room ke 'kalibrasi' (Hanya Host)
  Future<void> startCalibration(String roomId) async {
    await _db.ref('rooms/$roomId').update({
      'status': 'kalibrasi',
    });
  }

  /// Keluar dari room (hanya pengguna yang keluar, TIDAK mengakhiri sesi ruangan)
  Future<void> leaveRoom(String roomId) async {
    final uid = currentUid;
    if (uid == null) return;

    // 1. Set state member menjadi 'keluar'
    await _db.ref('roomMembers/$roomId/$uid/state').set('keluar');
    // 2. Hapus status active room pengguna saat ini
    await _db.ref('userActiveRoom/$uid').remove();

    // 3. Cek apakah user adalah host
    final roomSnap = await _db.ref('rooms/$roomId').get();
    if (roomSnap.exists && roomSnap.value is Map) {
      final roomData = roomSnap.value as Map;
      final hostUid = roomData['hostUid']?.toString();

      if (hostUid != uid) {
        // Jika bukan host, hapus dari userRooms pengguna (karena keluar/batal partisipasi)
        await _db.ref('userRooms/$uid/$roomId').remove();
      }

      // Jika ada anggota lain yang aktif, kita bisa delegasikan host ke anggota berikutnya
      final membersSnap = await _db.ref('roomMembers/$roomId').get();
      if (membersSnap.exists && membersSnap.value is Map) {
        final membersMap = membersSnap.value as Map;
        RoomMemberModel? nextHost;

        membersMap.forEach((k, v) {
          if (v is Map && k != uid) {
            final m = RoomMemberModel.fromMap(k.toString(), v);
            if (m.state != 'keluar') {
              if (nextHost == null || m.joinedAt < nextHost!.joinedAt) {
                nextHost = m;
              }
            }
          }
        });

        if (hostUid == uid && nextHost != null) {
          // Transfer host ke anggota terawal berikutnya
          await _db.ref('rooms/$roomId/hostUid').set(nextHost!.uid);
          await _db.ref('roomMembers/$roomId/${nextHost!.uid}/isHost').set(true);
          await _db.ref('roomMembers/$roomId/$uid/isHost').set(false);
          await _db.ref('userRooms/${nextHost!.uid}/$roomId/role').set('host');
        }
        // PERHATIAN: JANGAN pernah mengubah status room menjadi 'selesai' di sini!
        // Sesi hanya berakhir ketika tombol 'Akhiri Ruang' ditekan atau sesuai jam yang di-set.
      }
    }
  }

  /// Eksplisit mengakhiri ruangan (hanya dipanggil saat klik button "Akhiri Ruang")
  Future<void> endRoom(String roomId) async {
    final uid = currentUid;
    final roomSnap = await _db.ref('rooms/$roomId').get();
    if (!roomSnap.exists || roomSnap.value is! Map) return;

    final roomData = roomSnap.value as Map;
    final code = roomData['code']?.toString();
    final name = roomData['name']?.toString() ?? 'Ruang Belajar';
    final durationMin = (roomData['durationMinutes'] as num?)?.toInt() ?? 45;
    final startAt = (roomData['startAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Ubah status ruangan menjadi selesai
    await _db.ref('rooms/$roomId/status').set('selesai');

    // 2. Nonaktifkan kode ruangan
    if (code != null) {
      await _db.ref('roomCodes/$code/active').set(false);
    }

    // 3. Update status userRooms dan bersihkan userActiveRoom untuk semua anggota
    final membersSnap = await _db.ref('roomMembers/$roomId').get();
    if (membersSnap.exists && membersSnap.value is Map) {
      final membersMap = membersSnap.value as Map;
      for (final entry in membersMap.entries) {
        final mUid = entry.key.toString();
        await _db.ref('userActiveRoom/$mUid').remove();
        await _db.ref('userRooms/$mUid/$roomId/status').set('selesai');

        // Pastikan tersimpan di riwayat sesi
        await _db.ref('userSessions/$mUid/$roomId').set({
          'roomId': roomId,
          'roomName': name,
          'roomCode': code ?? '',
          'startAt': startAt,
          'completedAt': now,
          'durationDoneMin': ((now - startAt) / 60000).ceil().clamp(1, durationMin),
          'violationCount': 0,
          'endedHow': 'host',
          'isCreatedByMe': mUid == uid,
          'status': 'Selesai',
          'memberCount': membersMap.length,
          'meetingLink': code != null ? 'https://kerkom.app/j/$code' : '',
        });
      }
    }
  }

  /// Stream daftar ruang milik pengguna (host atau member) dari userRooms/{uid}
  Stream<List<UserRoomIndex>> watchUserRooms(String uid) {
    return _db.ref('userRooms/$uid').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final map = event.snapshot.value as Map;
        final list = <UserRoomIndex>[];
        map.forEach((k, v) {
          if (v is Map) {
            list.add(UserRoomIndex.fromMap(k.toString(), v));
          }
        });
        list.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
        return list;
      }
      return <UserRoomIndex>[];
    }).handleError((_) => <UserRoomIndex>[]);
  }

  /// Migrasi idempotent satu kali untuk memetakan ruang lama ke userRooms/{uid}
  Future<int> syncAndMigrateUserRooms(String uid) async {
    int migratedCount = 0;
    try {
      final snap = await _db.ref('rooms').get();
      if (snap.exists && snap.value is Map) {
        final allRoomsMap = snap.value as Map;
        final updates = <String, dynamic>{};

        allRoomsMap.forEach((roomIdKey, roomVal) {
          if (roomVal is Map) {
            final roomId = roomVal['id']?.toString() ?? roomIdKey.toString();
            final hostUid = roomVal['hostUid']?.toString() ??
                roomVal['leaderId']?.toString() ??
                roomVal['ownerId']?.toString() ??
                '';
            final membersMap = roomVal['members'] is Map ? (roomVal['members'] as Map) : null;
            final isMember = membersMap != null && membersMap.containsKey(uid);
            final isHost = hostUid == uid;

            if (isHost || isMember) {
              final name = roomVal['name']?.toString() ?? roomVal['title']?.toString() ?? 'Ruang Belajar';
              final code = roomVal['code']?.toString() ?? roomId;
              final duration = (roomVal['durationMinutes'] as num?)?.toInt() ?? 45;
              final scheduled = (roomVal['startAt'] ??
                      roomVal['startedAt'] ??
                      roomVal['sessionStartedAt'] ??
                      roomVal['createdAt'] as num?)
                  ?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch;
              final status = roomVal['status']?.toString() ??
                  (roomVal['isSessionActive'] == true ? 'berjalan' : 'lobi');

              updates['userRooms/$uid/$roomId'] = {
                'roomId': roomId,
                'name': name,
                'code': code,
                'scheduledStart': scheduled,
                'durationMin': duration,
                'role': isHost ? 'host' : 'member',
                'status': status,
                'note': roomVal['note']?.toString() ?? '',
                'reminder': roomVal['reminder']?.toString() ?? '',
                'createdAt': (roomVal['createdAt'] as num?)?.toInt() ?? scheduled,
              };
              migratedCount++;
            }
          }
        });

        if (updates.isNotEmpty) {
          await _db.ref().update(updates);
        }
      }
    } catch (_) {}
    return migratedCount;
  }

  /// Update Ruang (Hanya Host)
  Future<void> updateRoom({
    required String roomId,
    required String name,
    required int durationMinutes,
    String? note,
    String? reminder,
    int? scheduledStart,
  }) async {
    final uid = currentUid;
    if (uid == null) throw 'Pengguna belum terautentikasi';

    final roomSnap = await _db.ref('rooms/$roomId').get();
    if (!roomSnap.exists || roomSnap.value is! Map) throw 'Ruang tidak ditemukan';

    final roomData = roomSnap.value as Map;
    final hostUid = roomData['hostUid']?.toString() ?? roomData['leaderId']?.toString();
    if (hostUid != uid) throw 'Hanya Host yang dapat mengedit ruangan';

    final updates = <String, dynamic>{
      'rooms/$roomId/name': name.trim(),
      'rooms/$roomId/durationMinutes': durationMinutes,
      if (note != null) 'rooms/$roomId/note': note.trim(),
      'rooms/$roomId/reminder': ?reminder,
      'rooms/$roomId/startAt': ?scheduledStart,
      'userRooms/$uid/$roomId/name': name.trim(),
      'userRooms/$uid/$roomId/durationMin': durationMinutes,
      if (note != null) 'userRooms/$uid/$roomId/note': note.trim(),
      'userRooms/$uid/$roomId/reminder': ?reminder,
      'userRooms/$uid/$roomId/scheduledStart': ?scheduledStart,
    };

    try {
      final membersSnap = await _db.ref('roomMembers/$roomId').get();
      if (membersSnap.exists && membersSnap.value is Map) {
        final membersMap = membersSnap.value as Map;
        membersMap.forEach((mUid, _) {
          updates['userRooms/$mUid/$roomId/name'] = name.trim();
          updates['userRooms/$mUid/$roomId/durationMin'] = durationMinutes;
          if (scheduledStart != null) updates['userRooms/$mUid/$roomId/scheduledStart'] = scheduledStart;
        });
      }
    } catch (_) {}

    await _db.ref().update(updates);
  }

  /// Hapus Ruang (Hanya Host, tidak boleh saat sesi 'berjalan')
  Future<void> deleteRoom(String roomId) async {
    final uid = currentUid;
    if (uid == null) throw 'Pengguna belum terautentikasi';

    final roomSnap = await _db.ref('rooms/$roomId').get();
    if (!roomSnap.exists || roomSnap.value is! Map) return;

    final roomData = roomSnap.value as Map;
    final hostUid = roomData['hostUid']?.toString() ?? roomData['leaderId']?.toString();
    if (hostUid != uid) throw 'Hanya Host yang dapat menghapus ruangan';

    final status = roomData['status']?.toString() ??
        (roomData['isSessionActive'] == true ? 'berjalan' : 'lobi');
    if (status == 'berjalan') {
      throw 'Ruangan sedang dalam sesi berjalan. Akhiri sesi terlebih dahulu sebelum menghapus.';
    }

    final code = roomData['code']?.toString();
    final updates = <String, dynamic>{
      'rooms/$roomId': null,
      'roomMembers/$roomId': null,
      'roomEvents/$roomId': null,
      if (code != null) 'roomCodes/$code': null,
      'userRooms/$uid/$roomId': null,
      'userActiveRoom/$uid': null,
    };

    try {
      final membersSnap = await _db.ref('roomMembers/$roomId').get();
      if (membersSnap.exists && membersSnap.value is Map) {
        final membersMap = membersSnap.value as Map;
        membersMap.forEach((mUid, _) {
          updates['userRooms/$mUid/$roomId'] = null;
          updates['userActiveRoom/$mUid'] = null;
        });
      }
    } catch (_) {}

    await _db.ref().update(updates);
  }
}
