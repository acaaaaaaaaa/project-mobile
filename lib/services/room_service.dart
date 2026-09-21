import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/room_model.dart';
import 'sensor_service.dart';

class RoomService extends ChangeNotifier {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  final _uuid = const Uuid();
  final PhoneMotionService _sensorService = PhoneMotionService();

  StudyRoom? _currentRoom;
  Member? _currentUser;
  Timer? _studyTimer;
  int _remainingSeconds = 0;
  Timer? _mockNetworkSimulationTimer;

  // Alert event stream untuk pop-up/banner saat ada yang angkat HP
  final _distractionAlertController = StreamController<String>.broadcast();
  Stream<String> get distractionAlertStream => _distractionAlertController.stream;

  StudyRoom? get currentRoom => _currentRoom;
  Member? get currentUser => _currentUser;
  int get remainingSeconds => _remainingSeconds;
  bool get isSessionRunning => _currentRoom?.isSessionActive ?? false;

  String get formattedTimer {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Membuat Room baru (sebagai Leader)
  StudyRoom createRoom({
    required String leaderName,
    required String title,
    int durationMinutes = 30,
  }) {
    final leaderId = _uuid.v4();
    final roomCode = 'ROOM-${Random().nextInt(9000) + 1000}';

    _currentUser = Member(
      id: leaderId,
      name: leaderName,
      isLeader: true,
      status: MemberStatus.focusing,
    );

    _currentRoom = StudyRoom(
      id: _uuid.v4(),
      code: roomCode,
      title: title.isEmpty ? 'Sesi Belajar Kelompok' : title,
      leaderId: leaderId,
      durationMinutes: durationMinutes,
      createdAt: DateTime.now(),
      members: [
        _currentUser!,
        // Dummy members awal untuk mensimulasikan lingkungan room belajar
        Member(id: 'mock-1', name: 'Ahmad Fauzi (Anggota)', isLeader: false),
        Member(id: 'mock-2', name: 'Siti Rahma (Anggota)', isLeader: false),
      ],
    );

    _remainingSeconds = durationMinutes * 60;
    notifyListeners();
    return _currentRoom!;
  }

  /// Bergabung ke Room yang sudah ada
  bool joinRoom({
    required String memberName,
    required String roomCode,
  }) {
    final memberId = _uuid.v4();
    _currentUser = Member(
      id: memberId,
      name: memberName,
      isLeader: false,
      status: MemberStatus.focusing,
    );

    // Jika belum ada room aktif, buat room dengan kode tersebut
    _currentRoom = StudyRoom(
      id: _uuid.v4(),
      code: roomCode.toUpperCase(),
      title: 'Ruang Belajar Bersama',
      leaderId: 'leader-external',
      durationMinutes: 45,
      createdAt: DateTime.now(),
      members: [
        Member(id: 'leader-external', name: 'Ketua Kelompok', isLeader: true),
        _currentUser!,
        Member(id: 'mock-budi', name: 'Budi Santoso', isLeader: false),
      ],
    );

    _remainingSeconds = 45 * 60;
    notifyListeners();
    return true;
  }

  /// Mulai sesi belajar dan aktifkan pemantauan sensor
  void startSession() {
    if (_currentRoom == null) return;
    _currentRoom!.isSessionActive = true;

    // Mulai sensor
    _sensorService.startMonitoring(
      onLifted: _handleLocalPhoneLifted,
      onResting: _handleLocalPhoneResting,
    );

    // Mulai Countdown Timer
    _studyTimer?.cancel();
    _studyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopSession();
      }
    });

    // Jalankan simulasi aktivitas anggota nirkabel lain secara periodik
    _startWirelessMemberSimulation();

    notifyListeners();
  }

  /// Hentikan sesi belajar
  void stopSession() {
    _studyTimer?.cancel();
    _mockNetworkSimulationTimer?.cancel();
    _sensorService.stopMonitoring();

    if (_currentRoom != null) {
      _currentRoom!.isSessionActive = false;
    }
    notifyListeners();
  }

  void _handleLocalPhoneLifted() {
    if (_currentUser == null) return;
    _currentUser!.status = MemberStatus.phoneLifted;
    _currentUser!.distractionCount++;
    _currentUser!.lastDistractionTime = DateTime.now();

    final alertMsg = 'PERINGATAN: HP Anda (${_currentUser!.name}) terdeteksi diangkat!';
    _distractionAlertController.add(alertMsg);
    notifyListeners();
  }

  void _handleLocalPhoneResting() {
    if (_currentUser == null) return;
    _currentUser!.status = MemberStatus.focusing;
    notifyListeners();
  }

  /// Simulasi nirkabel (Wireless broadcast) dari anggota lain di room
  void _startWirelessMemberSimulation() {
    _mockNetworkSimulationTimer?.cancel();
    _mockNetworkSimulationTimer = Timer.periodic(const Duration(seconds: 18), (timer) {
      if (_currentRoom == null || !_currentRoom!.isSessionActive) return;

      // Cari anggota selain currentUser
      final otherMembers = _currentRoom!.members.where((m) => m.id != _currentUser?.id).toList();
      if (otherMembers.isEmpty) return;

      final randomMember = otherMembers[Random().nextInt(otherMembers.length)];

      // Toggle status anggota lain
      if (randomMember.status == MemberStatus.focusing) {
        randomMember.status = MemberStatus.phoneLifted;
        randomMember.distractionCount++;
        randomMember.lastDistractionTime = DateTime.now();

        _distractionAlertController.add(
          '🚨 ${randomMember.name} baru saja mengangkat HP! Fokus kerja kelompok terganggu.',
        );
        notifyListeners();

        // Kembalikan ke focusing setelah 6 detik
        Future.delayed(const Duration(seconds: 6), () {
          randomMember.status = MemberStatus.focusing;
          notifyListeners();
        });
      }
    });
  }

  /// Trigger simulasi angkat HP secara manual (sangat berguna untuk demo di Android Studio Emulator)
  void triggerManualLiftSimulation() {
    final isCurrentlyLifted = _sensorService.isPhoneLifted;
    _sensorService.simulatePhoneLift(
      !isCurrentlyLifted,
      onLifted: _handleLocalPhoneLifted,
      onResting: _handleLocalPhoneResting,
    );
  }

  /// Share kode room ke aplikasi lain (WhatsApp, Telegram, dll)
  Future<void> shareRoomInvitation() async {
    if (_currentRoom == null) return;
    final text = 'Yuk gabung ke sesi belajar kelompok kami di FocusRoom!\n\n'
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
    stopSession();
    _currentRoom = null;
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopSession();
    _sensorService.dispose();
    _distractionAlertController.close();
    super.dispose();
  }
}
