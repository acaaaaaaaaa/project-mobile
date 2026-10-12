import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/room_model.dart';
import 'firebase_service.dart';
import 'sensor_service.dart';

class RoomService extends ChangeNotifier {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  final _uuid = const Uuid();
  final PhoneMotionService _sensorService = PhoneMotionService();
  final FirebaseRealtimeService _firebaseService = FirebaseRealtimeService.instance;

  StudyRoom? _currentRoom;
  Member? _currentUser;
  Timer? _studyTimer;
  int _remainingSeconds = 0;

  String _userName = 'Mahasiswa';
  int _userLevel = 1;
  int _userXp = 0;
  int _streakDays = 1;
  StreamSubscription? _userSub;

  StreamSubscription? _membersSub;
  StreamSubscription? _roomSub;
  StreamSubscription? _alertsSub;

  // Alert stream untuk banner / notifikasi popup saat ada anggota yang angkat HP
  final _distractionAlertController = StreamController<String>.broadcast();
  Stream<String> get distractionAlertStream => _distractionAlertController.stream;

  StudyRoom? get currentRoom => _currentRoom;
  Member? get currentUser => _currentUser;
  int get remainingSeconds => _remainingSeconds;
  bool get isSessionRunning => _currentRoom?.isSessionActive ?? false;

  String get userName => _userName;
  int get userLevel => _userLevel;
  int get userXp => _userXp;
  int get streakDays => _streakDays;

  String get formattedTimer {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Inisialisasi profil pengguna dari Firebase
  Future<void> loadUserProfile() async {
    final uid = _firebaseService.currentUserId;
    try {
      final profile = await _firebaseService.getUserProfile(uid);
      if (profile != null) {
        _userName = profile['name']?.toString() ?? 'Mahasiswa';
        _userLevel = (profile['level'] as num?)?.toInt() ?? 1;
        _userXp = (profile['xp'] as num?)?.toInt() ?? 0;
        _streakDays = (profile['streakDays'] as num?)?.toInt() ?? 1;
      } else {
        await _firebaseService.saveUserProfile(
          userId: uid,
          name: _userName,
          level: _userLevel,
          xp: _userXp,
          streakDays: _streakDays,
        );
      }
      
      _userSub?.cancel();
      _userSub = _firebaseService.watchUserProfile(uid).listen((event) {
        if (event.snapshot.exists && event.snapshot.value is Map) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          _userName = data['name']?.toString() ?? _userName;
          _userLevel = (data['level'] as num?)?.toInt() ?? _userLevel;
          _userXp = (data['xp'] as num?)?.toInt() ?? _userXp;
          _streakDays = (data['streakDays'] as num?)?.toInt() ?? _streakDays;
          notifyListeners();
        }
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  /// Ubah nama pengguna dan sinkronkan ke Firebase
  Future<void> updateUserName(String newName) async {
    if (newName.trim().isEmpty) return;
    _userName = newName.trim();
    final uid = _firebaseService.currentUserId;
    await _firebaseService.saveUserProfile(
      userId: uid,
      name: _userName,
    );
    if (_currentUser != null) {
      _currentUser = Member(
        id: _currentUser!.id,
        name: _userName,
        isLeader: _currentUser!.isLeader,
        status: _currentUser!.status,
        avatarUrl: _currentUser!.avatarUrl,
        distractionCount: _currentUser!.distractionCount,
      );
      if (_currentRoom != null) {
        _firebaseService.joinRoom(_currentRoom!.code, _currentUser!);
      }
    }
    notifyListeners();
  }

  /// Membuat Ruang Belajar Baru (sebagai Host / Leader)
  Future<StudyRoom> createRoom({
    required String leaderName,
    required String title,
    int durationMinutes = 45,
  }) async {
    _closeSubscriptions();

    final actualName = leaderName.trim().isNotEmpty ? leaderName.trim() : _userName;
    _userName = actualName;
    final leaderId = _firebaseService.currentUserId;
    final roomCode = 'PACT-${Random().nextInt(9000) + 1000}';

    _currentUser = Member(
      id: leaderId,
      name: actualName,
      isLeader: true,
      status: MemberStatus.focusing,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=120&q=80',
    );

    // Hanya anggota nyata (Host), TIDAK ADA DUMMY MEMBER!
    _currentRoom = StudyRoom(
      id: _uuid.v4(),
      code: roomCode,
      title: title.trim().isNotEmpty ? title.trim() : 'Ruang Belajar Bersama',
      leaderId: leaderId,
      leaderName: actualName,
      durationMinutes: durationMinutes,
      createdAt: DateTime.now(),
      members: [
        _currentUser!,
      ],
    );

    _remainingSeconds = durationMinutes * 60;
    notifyListeners();

    // 1. Simpan profil user ke Firebase
    _firebaseService.saveUserProfile(
      userId: leaderId,
      name: actualName,
    );

    // 2. Simpan room ke Firebase Realtime Database
    try {
      await _firebaseService.createRoom(_currentRoom!, _currentUser!);
      _setupFirebaseRoomListeners(roomCode);
    } catch (e) {
      debugPrint('Error create room di Firebase: $e');
    }

    return _currentRoom!;
  }

  /// Bergabung ke Ruang Belajar via Kode Ruang (sebagai Peserta)
  Future<bool> joinRoom({
    required String memberName,
    required String roomCode,
  }) async {
    _closeSubscriptions();

    final cleanCode = roomCode.trim().toUpperCase();
    final actualName = memberName.trim().isNotEmpty ? memberName.trim() : _userName;
    _userName = actualName;
    final memberId = _firebaseService.currentUserId;

    // 1. Cek terlebih dahulu apakah Room benar-benar ada di Firebase
    final liveRoom = await _firebaseService.getRoom(cleanCode);
    if (liveRoom == null) {
      debugPrint('Room dengan kode $cleanCode tidak ditemukan di server Firebase.');
      return false;
    }

    _currentUser = Member(
      id: memberId,
      name: actualName,
      isLeader: liveRoom.leaderId == memberId,
      status: MemberStatus.focusing,
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&q=80',
    );

    _currentRoom = liveRoom;
    _remainingSeconds = liveRoom.durationMinutes * 60;

    // Pastikan user sendiri ada di daftar members
    final existingIdx = _currentRoom!.members.indexWhere((m) => m.id == memberId);
    if (existingIdx >= 0) {
      _currentRoom!.members[existingIdx] = _currentUser!;
    } else {
      _currentRoom!.members.add(_currentUser!);
    }
    notifyListeners();

    // 2. Simpan profil pengguna ke Firebase
    _firebaseService.saveUserProfile(
      userId: memberId,
      name: actualName,
    );

    // 3. Masukkan ke daftar member room di Firebase
    try {
      final joined = await _firebaseService.joinRoom(cleanCode, _currentUser!);
      if (joined) {
        _setupFirebaseRoomListeners(cleanCode);
        return true;
      }
    } catch (e) {
      debugPrint('Koneksi join room ke Firebase error: $e');
    }

    return true;
  }

  /// Menghubungkan Listener Firebase Realtime Database
  void _setupFirebaseRoomListeners(String roomCode) {
    // 1. Dengar pembaruan seluruh anggota room secara real-time
    _membersSub = _firebaseService.watchMembers(roomCode).listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final membersMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        final List<Member> liveMembers = [];

        membersMap.forEach((key, val) {
          if (val is Map) {
            final m = Member.fromMap(Map<String, dynamic>.from(val));
            liveMembers.add(m);
            if (m.id == _currentUser?.id) {
              _currentUser = m;
            }
          }
        });

        if (_currentRoom != null) {
          _currentRoom!.members = liveMembers;
          notifyListeners();
        }
      }
    });

    // 2. Dengar pembaruan room (status sesi aktif & waktu & judul)
    _roomSub = _firebaseService.watchRoom(roomCode).listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (_currentRoom != null) {
          final isNowActive = data['isSessionActive'] == true;
          if (_currentRoom!.isSessionActive != isNowActive) {
            _currentRoom!.isSessionActive = isNowActive;
            if (isNowActive && !(_sensorService.isMonitoring)) {
              // Jika Host memulai sesi, otomatis aktifkan pemantauan di HP anggota juga!
              _startLocalMonitoring();
            } else if (!isNowActive && _sensorService.isMonitoring) {
              stopSession();
            }
          }
          if (data['title'] != null || data['leaderName'] != null) {
            _currentRoom = StudyRoom(
              id: _currentRoom!.id,
              code: _currentRoom!.code,
              title: data['title']?.toString() ?? _currentRoom!.title,
              leaderId: data['leaderId']?.toString() ?? _currentRoom!.leaderId,
              leaderName: data['leaderName']?.toString() ?? _currentRoom!.leaderName,
              durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? _currentRoom!.durationMinutes,
              createdAt: _currentRoom!.createdAt,
              isSessionActive: _currentRoom!.isSessionActive,
              members: _currentRoom!.members,
            );
          }
          notifyListeners();
        }
      }
    });

    // 3. Dengar broadcast peringatan pelanggaran (HP diangkat) dari anggota lain
    _alertsSub = _firebaseService.watchAlerts(roomCode).listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final alertData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final alertMemberName = alertData['memberName']?.toString() ?? 'Seseorang';
        final message = alertData['message']?.toString() ?? 'HP terangkat!';

        // Hanya tampilkan alert jika bukan berasal dari diri sendiri
        if (alertMemberName != _currentUser?.name) {
          _distractionAlertController.add('🚨 $message');
        }
      }
    });
  }

  /// Memulai sesi belajar dan pemantauan sensor accelerometer
  void startSession() {
    if (_currentRoom == null) return;
    _currentRoom!.isSessionActive = true;

    // Sinkronkan ke Firebase jika Host
    if (_currentUser?.isLeader == true) {
      _firebaseService.setSessionActive(_currentRoom!.code, true);
    }

    _startLocalMonitoring();
    notifyListeners();
  }

  void _startLocalMonitoring() {
    // Mulai sensor hardware HP
    _sensorService.startMonitoring(
      onLifted: (episode) => _handleLocalPhoneLifted(),
      onResting: _handleLocalPhoneResting,
    );

    // Mulai Countdown Timer
    _studyTimer?.cancel();
    _studyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_remainingSeconds % 10 == 0 && _currentRoom != null && _currentUser?.isLeader == true) {
          _firebaseService.updateRemainingSeconds(_currentRoom!.code, _remainingSeconds);
        }
        notifyListeners();
      } else {
        stopSession();
      }
    });
  }

  /// Menghentikan sesi belajar
  void stopSession() {
    _studyTimer?.cancel();
    _sensorService.stopMonitoring();

    if (_currentRoom != null) {
      _currentRoom!.isSessionActive = false;

      // Update status ke Firebase
      if (_currentUser?.isLeader == true) {
        _firebaseService.setSessionActive(_currentRoom!.code, false);
      }

      // Catat log sesi ke Firebase untuk pengguna saat ini
      if (_currentUser != null) {
        _firebaseService.saveSessionLog(
          userId: _currentUser!.id,
          roomCode: _currentRoom!.code,
          title: _currentRoom!.title,
          durationMinutes: _currentRoom!.durationMinutes,
          distractionCount: _currentUser!.distractionCount,
          xpEarned: max(15, 34 - (_currentUser!.distractionCount * 5)),
        );
      }
    }

    notifyListeners();
  }

  /// Handler saat HP pengguna lokal terdeteksi diangkat dari meja
  void _handleLocalPhoneLifted() {
    if (_currentUser == null) return;
    _currentUser!.status = MemberStatus.phoneLifted;
    _currentUser!.distractionCount++;
    _currentUser!.lastDistractionTime = DateTime.now();

    final alertMsg = 'PERINGATAN: HP Anda (${_currentUser!.name}) terdeteksi diangkat!';
    _distractionAlertController.add(alertMsg);
    notifyListeners();

    // Broadcast ke Firebase agar teman satu kelompok langsung ter-update
    if (_currentRoom != null) {
      _firebaseService.updateMemberFocusStatus(
        roomCode: _currentRoom!.code,
        memberId: _currentUser!.id,
        status: MemberStatus.phoneLifted,
        distractionCount: _currentUser!.distractionCount,
      );

      _firebaseService.broadcastDistractionAlert(
        roomCode: _currentRoom!.code,
        memberName: _currentUser!.name,
        message: '${_currentUser!.name} baru saja mengangkat smartphone! Fokus kelompok terganggu.',
      );
    }
  }

  /// Handler saat HP pengguna lokal diletakkan kembali di atas meja
  void _handleLocalPhoneResting() {
    if (_currentUser == null) return;
    _currentUser!.status = MemberStatus.focusing;
    notifyListeners();

    // Broadcast ke Firebase
    if (_currentRoom != null) {
      _firebaseService.updateMemberFocusStatus(
        roomCode: _currentRoom!.code,
        memberId: _currentUser!.id,
        status: MemberStatus.focusing,
        distractionCount: _currentUser!.distractionCount,
      );
    }
  }

  /// Trigger simulasi angkat HP secara manual (praktis untuk uji coba)
  void triggerManualLiftSimulation() {
    final isCurrentlyLifted = _sensorService.isPhoneLifted;
    _sensorService.simulatePhoneLift(!isCurrentlyLifted);
  }

  /// Membagikan undangan ruang belajar
  Future<void> shareRoomInvitation() async {
    if (_currentRoom == null) return;
    final text = 'Yuk gabung ke sesi belajar kelompok kami di StudyPact!\n\n'
        'Judul: ${_currentRoom!.title}\n'
        'Kode Room: ${_currentRoom!.code}\n'
        'Durasi: ${_currentRoom!.durationMinutes} Menit\n'
        'Ayo letakkan HP di meja dan fokus belajar bersama!';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Undangan Belajar Kelompok - ${_currentRoom!.title}',
      ),
    );
  }

  void leaveRoom() {
    if (_currentRoom != null && _currentUser != null) {
      _firebaseService.leaveRoom(_currentRoom!.code, _currentUser!.id);
    }
    stopSession();
    _closeSubscriptions();
    _currentRoom = null;
    _currentUser = null;
    notifyListeners();
  }

  void _closeSubscriptions() {
    _membersSub?.cancel();
    _roomSub?.cancel();
    _alertsSub?.cancel();
  }

  @override
  void dispose() {
    stopSession();
    _closeSubscriptions();
    _userSub?.cancel();
    _sensorService.stopMonitoring();
    _distractionAlertController.close();
    super.dispose();
  }
}
