import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/room_model.dart';
import 'backend_service.dart';
import 'sensor_service.dart';

class RoomService extends ChangeNotifier {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  final _backend = BackendService.instance;
  final _sensor = PhoneMotionService();
  final _uuid = const Uuid();
  final _alerts = StreamController<String>.broadcast();
  Stream<String> get distractionAlertStream => _alerts.stream;
  StreamSubscription? _roomSub, _membersSub, _presenceSub, _eventsSub, _sessionSub;
  Timer? _clock, _heartbeat;
  final _seenEvents = <String>{};
  StudyRoom? _room;
  Member? _me;
  String? _sessionId;
  DateTime? _endsAt;
  int _remainingSeconds = 0;

  StudyRoom? get currentRoom => _room;
  Member? get currentUser => _me;
  int get remainingSeconds => _remainingSeconds;
  bool get isSessionRunning => _room?.isSessionActive ?? false;
  String get formattedTimer =>
      '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}';

  Future<StudyRoom> createRoom({required String leaderName, required String title,
      int durationMinutes = 30}) async {
    final data = await _backend.createRoom(leaderName, title, durationMinutes);
    _open(data, leaderName, true);
    return _room!;
  }

  Future<void> joinRoom({required String memberName, required String roomCode}) async {
    final data = await _backend.joinRoom(memberName, roomCode);
    _open(data, memberName, false);
  }

  void _open(Map<String, dynamic> data, String name, bool leader) {
    _closeSubscriptions();
    final id = data['roomId'] as String;
    _me = Member(id: _backend.uid, name: name, isLeader: leader);
    _room = StudyRoom(id: id, code: data['code'] as String,
        title: data['title'] as String,
        leaderId: leader ? _backend.uid : '',
        durationMinutes: (data['durationMinutes'] as num).toInt(),
        createdAt: DateTime.now(), members: [_me!]);
    _remainingSeconds = _room!.durationMinutes * 60;
    _roomSub = _backend.watchRoom(id).listen((snapshot) {
      final value = snapshot.data();
      if (value == null || _room?.id != id) return;
      _room!.isSessionActive = value['state'] == 'active';
      final next = value['currentSessionId'] as String?;
      if (_room!.isSessionActive && next != null && next != _sessionId) {
        _attachSession(next);
      } else if (!_room!.isSessionActive && _sessionId != null) {
        _stopLocalSession();
      }
      notifyListeners();
    }, onError: _reportError);
    _membersSub = _backend.watchMembers(id).listen((snapshot) {
      if (_room?.id != id) return;
      final old = {for (final member in _room!.members) member.id: member};
      _room!.members = snapshot.docs.where((doc) => doc.data()['active'] == true).map((doc) {
        final data = doc.data();
        final member = old[doc.id] ?? Member(id: doc.id,
            name: data['displayName'] as String? ?? 'Anggota');
        member.distractionCount = (data['distractionCount'] as num? ?? 0).toInt();
        return Member(id: doc.id, name: data['displayName'] as String? ?? 'Anggota',
            isLeader: data['role'] == 'leader', status: member.status,
            distractionCount: member.distractionCount);
      }).toList();
      final mine = _room!.members.where((member) => member.id == _backend.uid);
      if (mine.isNotEmpty) _me = mine.first;
      notifyListeners();
    }, onError: _reportError);
    notifyListeners();
  }

  Future<void> startSession() async {
    final room = _room;
    if (room == null || _me?.isLeader != true || room.isSessionActive) return;
    try {
      final result = await _backend.startSession(room.id);
      _attachSession(result['sessionId'] as String);
    } catch (error) {
      _reportError(error);
    }
  }

  void _attachSession(String sessionId) {
    if (_room == null || sessionId == _sessionId) return;
    _stopLocalSession();
    final roomId = _room!.id;
    _sessionId = sessionId;
    _room!.isSessionActive = true;
    _sessionSub = _backend.firestore.doc('rooms/$roomId/sessions/$sessionId').snapshots().listen((snapshot) {
      final endsAt = snapshot.data()?['endsAt'];
      if (endsAt is Timestamp) {
        _endsAt = endsAt.toDate();
        _tick();
      }
    }, onError: _reportError);
    _presenceSub = _backend.watchPresence(roomId, sessionId).listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        for (final member in _room?.members ?? <Member>[]) {
          if (member.id != doc.id) continue;
          final heartbeat = data['heartbeatAt'];
          final stale = heartbeat is Timestamp &&
              DateTime.now().difference(heartbeat.toDate()).inSeconds > 45;
          member.status = stale ? MemberStatus.away :
              data['state'] == 'suspected_use' ? MemberStatus.phoneLifted :
              MemberStatus.focusing;
        }
      }
      notifyListeners();
    }, onError: _reportError);
    _seenEvents.clear();
    var firstSnapshot = true;
    _eventsSub = _backend.watchEvents(roomId, sessionId).listen((snapshot) {
      for (final doc in snapshot.docs) {
        if (!_seenEvents.add(doc.id) || firstSnapshot) continue;
        final data = doc.data();
        if (data['liveEligible'] == true && data['actorUid'] != _backend.uid) {
          _alerts.add('${data['actorName'] ?? 'Anggota'}: indikasi HP dipindahkan atau dimiringkan.');
        }
      }
      firstSnapshot = false;
    }, onError: _reportError);
    _sensor.startMonitoring(onLifted: _onLifted, onResting: _onResting);
    _sendHeartbeat();
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) => _sendHeartbeat());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    if (_endsAt == null) return;
    _remainingSeconds = _endsAt!.difference(DateTime.now()).inSeconds.clamp(0, 10800);
    notifyListeners();
    if (_remainingSeconds == 0 && _me?.isLeader == true) {
      stopSession();
    }
  }

  Future<void> stopSession() async {
    final id = _room?.id, session = _sessionId;
    if (id == null || session == null || _me?.isLeader != true) return;
    try {
      await _backend.endSession(id, session);
    } catch (error) {
      _reportError(error);
    }
  }

  void _onLifted(MotionEpisode episode) {
    final id = _room?.id, session = _sessionId;
    if (id == null || session == null) return;
    if (_me != null) _me!.status = MemberStatus.phoneLifted;
    _alerts.add('Indikasi HP Anda dipindahkan atau dimiringkan.');
    notifyListeners();
    _backend.submitSuspectedUse(roomId: id, sessionId: session,
        episodeId: _uuid.v4(), observedAt: episode.observedAt,
        durationMs: episode.durationMs, peakAccel: episode.peakAccel,
        peakGyro: episode.peakGyro,
        orientationChangeDeg: episode.orientationChangeDeg,
        confidence: episode.confidence).catchError(_reportError);
  }

  void _onResting() {
    if (_me != null) _me!.status = MemberStatus.focusing;
    _sendHeartbeat();
    notifyListeners();
  }

  void _sendHeartbeat() {
    final id = _room?.id, session = _sessionId;
    if (id == null || session == null) return;
    _backend.heartbeat(id, session,
        _sensor.isPhoneLifted ? 'suspected_use' : 'focusing').catchError(_reportError);
  }

  void triggerManualLiftSimulation() =>
      _sensor.simulatePhoneLift(!_sensor.isPhoneLifted);

  Future<void> shareRoomInvitation() async {
    final room = _room;
    if (room == null) return;
    await SharePlus.instance.share(ShareParams(text:
        'Gabung FocusRoom: ${room.title}\nKode: ${room.code}\nDurasi: ${room.durationMinutes} menit'));
  }

  void _stopLocalSession() {
    _clock?.cancel(); _heartbeat?.cancel();
    _sessionSub?.cancel(); _presenceSub?.cancel(); _eventsSub?.cancel();
    _sensor.stopMonitoring();
    _sessionId = null;
    _endsAt = null;
    if (_room != null) _room!.isSessionActive = false;
  }

  void _closeSubscriptions() {
    _stopLocalSession();
    _roomSub?.cancel(); _membersSub?.cancel();
  }

  void leaveRoom() {
    final id = _room?.id;
    final session = _sessionId;
    if (id != null && session != null && _me?.isLeader == true) {
      _backend.endSession(id, session).catchError(_reportError);
    }
    _closeSubscriptions();
    _room = null; _me = null;
    notifyListeners();
    if (id != null) _backend.leaveRoom(id).catchError(_reportError);
  }

  void _reportError(Object error) {
    debugPrint('FocusRoom backend: $error');
    if (!_alerts.isClosed) _alerts.add('Koneksi bermasalah: $error');
  }
}
