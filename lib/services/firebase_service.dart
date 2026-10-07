import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/room_model.dart';

class FirebaseRealtimeService {
  FirebaseRealtimeService._internal();
  static final FirebaseRealtimeService instance = FirebaseRealtimeService._internal();

  static const String databaseUrl =
      'https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/';

  FirebaseDatabase? _database;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  FirebaseDatabase get db {
    if (_database == null) {
      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl,
      );
      // Aktifkan offline persistence agar sinkronisasi tetap stabil saat jaringan berfluktuasi
      try {
        _database!.setPersistenceEnabled(true);
      } catch (e) {
        debugPrint('Persistence already configured: $e');
      }
    }
    return _database!;
  }

  /// Inisialisasi koneksi Firebase Database
  Future<void> initialize() async {
    try {
      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl,
      );
      _isInitialized = true;
      debugPrint('Firebase Realtime Database berhasil terhubung ke: $databaseUrl');
    } catch (e) {
      debugPrint('Error inisialisasi Firebase Database: $e');
      _isInitialized = false;
    }
  }

  // ==========================================
  // 1. PENYIMPANAN DATA PENGGUNA (USER DATA)
  // ==========================================

  /// Simpan atau perbarui profil data pengguna ke Firebase (/users/$userId)
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    int level = 14,
    int xp = 840,
    int streakDays = 7,
  }) async {
    try {
      final userRef = db.ref('users/$userId');
      await userRef.update({
        'id': userId,
        'name': name,
        'level': level,
        'xp': xp,
        'streakDays': streakDays,
        'lastActive': ServerValue.timestamp,
      });
      debugPrint('Data user $userId berhasil disimpan ke Firebase.');
    } catch (e) {
      debugPrint('Gagal menyimpan data user: $e');
    }
  }

  /// Ambil data profil pengguna dari Firebase
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final snapshot = await db.ref('users/$userId').get();
      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint('Gagal mengambil data user: $e');
    }
    return null;
  }

  /// Simpan riwayat sesi belajar yang telah selesai (/session_logs/$userId/$logId)
  Future<void> saveSessionLog({
    required String userId,
    required String roomCode,
    required String title,
    required int durationMinutes,
    required int distractionCount,
    required int xpEarned,
  }) async {
    try {
      final logRef = db.ref('session_logs/$userId').push();
      await logRef.set({
        'id': logRef.key,
        'roomCode': roomCode,
        'title': title,
        'durationMinutes': durationMinutes,
        'distractionCount': distractionCount,
        'xpEarned': xpEarned,
        'completedAt': ServerValue.timestamp,
      });

      // Tambahkan akumulasi XP ke profil pengguna
      final userRef = db.ref('users/$userId/xp');
      final currentXpSnap = await userRef.get();
      final currentXp = (currentXpSnap.value as num?)?.toInt() ?? 840;
      await userRef.set(currentXp + xpEarned);

      debugPrint('Sesi $roomCode berhasil dicatat ke riwayat log.');
    } catch (e) {
      debugPrint('Gagal menyimpan log sesi: $e');
    }
  }

  // ==============================================================
  // 2. PENYEBARAN DATA & SINKRONISASI REALTIME (FITUR FOCUS / ROOM)
  // ==============================================================

  /// Host membuat Room baru di Firebase (/rooms/$roomCode)
  Future<bool> createRoom(StudyRoom room, Member host) async {
    try {
      final roomRef = db.ref('rooms/${room.code}');
      
      final roomData = {
        'id': room.id,
        'code': room.code,
        'title': room.title,
        'leaderId': host.id,
        'leaderName': host.name,
        'durationMinutes': room.durationMinutes,
        'remainingSeconds': room.durationMinutes * 60,
        'isSessionActive': false,
        'createdAt': ServerValue.timestamp,
        'members': {
          host.id: host.toMap(),
        },
      };

      await roomRef.set(roomData);
      debugPrint('Room ${room.code} berhasil dibuat di Firebase.');
      return true;
    } catch (e) {
      debugPrint('Gagal membuat room di Firebase: $e');
      return false;
    }
  }

  /// Anggota bergabung ke Room yang sudah ada (/rooms/$roomCode/members/$memberId)
  Future<bool> joinRoom(String roomCode, Member member) async {
    try {
      final roomRef = db.ref('rooms/$roomCode');
      final snapshot = await roomRef.get();

      if (!snapshot.exists) {
        debugPrint('Room $roomCode tidak ditemukan di Firebase.');
        return false;
      }

      // Masukkan data member ke node members
      await db.ref('rooms/$roomCode/members/${member.id}').set(member.toMap());
      debugPrint('${member.name} berhasil bergabung ke room $roomCode.');
      return true;
    } catch (e) {
      debugPrint('Gagal join room di Firebase: $e');
      return false;
    }
  }

  /// Update status fokus anggota secara real-time
  /// (HP di meja vs HP diangkat / pergerakan sensor)
  Future<void> updateMemberFocusStatus({
    required String roomCode,
    required String memberId,
    required MemberStatus status,
    required int distractionCount,
    double pitch = 0.0,
    double roll = 0.0,
    double vibration = 0.0,
  }) async {
    try {
      final memberRef = db.ref('rooms/$roomCode/members/$memberId');
      await memberRef.update({
        'status': status.name,
        'distractionCount': distractionCount,
        'pitch': pitch,
        'roll': roll,
        'vibration': vibration,
        'lastUpdated': ServerValue.timestamp,
        if (status == MemberStatus.phoneLifted)
          'lastDistractionTime': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Gagal update focus status member: $e');
    }
  }

  /// Kirim sinyal darurat / peringatan pelanggaran (Distraction Broadcast Alert)
  /// Menyebarkan notifikasi ke seluruh user di dalam room
  Future<void> broadcastDistractionAlert({
    required String roomCode,
    required String memberName,
    required String message,
  }) async {
    try {
      final alertRef = db.ref('rooms/$roomCode/alerts').push();
      await alertRef.set({
        'id': alertRef.key,
        'memberName': memberName,
        'message': message,
        'timestamp': ServerValue.timestamp,
      });
      debugPrint('Peringatan distraksi dikirim ke room $roomCode: $message');
    } catch (e) {
      debugPrint('Gagal broadcast alert: $e');
    }
  }

  /// Update status aktif sesi (dimulai / dihentikan oleh Host)
  Future<void> setSessionActive(String roomCode, bool isActive) async {
    try {
      await db.ref('rooms/$roomCode').update({
        'isSessionActive': isActive,
        'sessionStartedAt': isActive ? ServerValue.timestamp : null,
      });
    } catch (e) {
      debugPrint('Gagal update session active: $e');
    }
  }

  /// Update sisa waktu hitung mundur sesi
  Future<void> updateRemainingSeconds(String roomCode, int remainingSeconds) async {
    try {
      await db.ref('rooms/$roomCode').update({
        'remainingSeconds': remainingSeconds,
      });
    } catch (e) {
      debugPrint('Gagal update timer di Firebase: $e');
    }
  }

  /// Keluar dari Room
  Future<void> leaveRoom(String roomCode, String memberId) async {
    try {
      await db.ref('rooms/$roomCode/members/$memberId').remove();
      debugPrint('Member $memberId telah keluar dari room $roomCode.');
    } catch (e) {
      debugPrint('Gagal keluar room: $e');
    }
  }

  /// Stream perubahan room secara keseluruhan (Data Sync)
  Stream<DatabaseEvent> watchRoom(String roomCode) {
    return db.ref('rooms/$roomCode').onValue;
  }

  /// Stream daftar anggota dan perubahan status fokus mereka secara realtime
  Stream<DatabaseEvent> watchMembers(String roomCode) {
    return db.ref('rooms/$roomCode/members').onValue;
  }

  /// Stream notifikasi & peringatan pelanggaran realtime
  Stream<DatabaseEvent> watchAlerts(String roomCode) {
    return db.ref('rooms/$roomCode/alerts').limitToLast(10).onChildAdded;
  }
}
