class RoomModel {
  final String id;
  final String code;
  final String name;
  final String hostUid;
  final int durationMinutes;
  final String status; // 'lobi', 'kalibrasi', 'berjalan', 'selesai'
  final int createdAt;
  final int? startAt;
  final int? endAt;
  final int remainingSeconds;
  final String? reminder;
  final String? note;
  final String? meetingLink;

  int? get startedAt => startAt;

  const RoomModel({
    required this.id,
    required this.code,
    required this.name,
    required this.hostUid,
    required this.durationMinutes,
    this.status = 'lobi',
    required this.createdAt,
    this.startAt,
    this.endAt,
    required this.remainingSeconds,
    this.reminder,
    this.note,
    this.meetingLink,
  });

  factory RoomModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final effectiveId = (map['id'] != null && map['id'].toString().isNotEmpty)
        ? map['id'].toString()
        : id;
    final name = map['name']?.toString() ?? map['title']?.toString() ?? 'Ruang Belajar';
    final hostUid = map['hostUid']?.toString() ??
        map['leaderId']?.toString() ??
        map['ownerId']?.toString() ??
        '';
    final code = map['code']?.toString() ?? effectiveId;
    final duration = (map['durationMinutes'] as num?)?.toInt() ?? 45;

    String status = map['status']?.toString() ?? 'lobi';
    if (map['isSessionActive'] == true && status == 'lobi') {
      status = 'berjalan';
    }

    final createdAt =
        (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
    final startAt =
        (map['startAt'] ?? map['startedAt'] ?? map['sessionStartedAt'] as num?)?.toInt();
    final endAt = (map['endAt'] as num?)?.toInt();
    final remainingSeconds =
        (map['remainingSeconds'] as num?)?.toInt() ?? (duration * 60);

    return RoomModel(
      id: effectiveId,
      code: code,
      name: name,
      hostUid: hostUid,
      durationMinutes: duration,
      status: status,
      createdAt: createdAt,
      startAt: startAt,
      endAt: endAt,
      remainingSeconds: remainingSeconds,
      reminder: map['reminder']?.toString(),
      note: map['note']?.toString(),
      meetingLink: map['meetingLink']?.toString() ??
          (map['code'] != null ? 'https://kerkom.app/j/${map['code']}' : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'hostUid': hostUid,
      'durationMinutes': durationMinutes,
      'status': status,
      'createdAt': createdAt,
      'startAt': startAt,
      'endAt': endAt,
      'remainingSeconds': remainingSeconds,
      if (reminder != null) 'reminder': reminder,
      if (note != null) 'note': note,
      if (meetingLink != null) 'meetingLink': meetingLink,
    };
  }

  RoomModel copyWith({
    String? status,
    String? hostUid,
    int? remainingSeconds,
    int? startAt,
    int? endAt,
    String? note,
    String? meetingLink,
  }) {
    return RoomModel(
      id: id,
      code: code,
      name: name,
      hostUid: hostUid ?? this.hostUid,
      durationMinutes: durationMinutes,
      status: status ?? this.status,
      createdAt: createdAt,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      reminder: reminder,
      note: note ?? this.note,
      meetingLink: meetingLink ?? this.meetingLink,
    );
  }
}

class RoomMemberModel {
  final String uid;
  final String name;
  final String photoUrl;
  final bool isHost;
  final String state; // 'aman', 'terangkat', 'terputus', 'keluar'
  final int joinedAt;
  final int lastSeen;
  final int liftCount;

  const RoomMemberModel({
    required this.uid,
    required this.name,
    this.photoUrl = '',
    required this.isHost,
    this.state = 'aman',
    required this.joinedAt,
    this.lastSeen = 0,
    this.liftCount = 0,
  });

  factory RoomMemberModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return RoomMemberModel(
      uid: uid,
      name: map['name']?.toString() ?? 'Anggota',
      photoUrl: map['photoUrl']?.toString() ?? '',
      isHost: map['isHost'] == true,
      state: map['state']?.toString() ?? 'aman',
      joinedAt: (map['joinedAt'] as num?)?.toInt() ?? 0,
      lastSeen: (map['lastSeen'] as num?)?.toInt() ?? 0,
      liftCount: (map['liftCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photoUrl': photoUrl,
      'isHost': isHost,
      'state': state,
      'joinedAt': joinedAt,
      'lastSeen': lastSeen,
      'liftCount': liftCount,
    };
  }
}

class UserSessionHistory {
  final String roomId;
  final String roomCode;
  final String roomName;
  final int durationMinutes;
  final int completedAt;
  final int distractionCount;

  const UserSessionHistory({
    required this.roomId,
    required this.roomCode,
    required this.roomName,
    required this.durationMinutes,
    required this.completedAt,
    this.distractionCount = 0,
  });

  factory UserSessionHistory.fromMap(String roomId, Map<dynamic, dynamic> map) {
    return UserSessionHistory(
      roomId: roomId,
      roomCode: map['roomCode']?.toString() ?? '',
      roomName: map['roomName']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 45,
      completedAt: (map['completedAt'] as num?)?.toInt() ?? 0,
      distractionCount: (map['distractionCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomCode': roomCode,
      'roomName': roomName,
      'durationMinutes': durationMinutes,
      'completedAt': completedAt,
      'distractionCount': distractionCount,
    };
  }
}

class UserRoomIndex {
  final String roomId;
  final String name;
  final String code;
  final int scheduledStart;
  final int durationMin;
  final String role; // 'host' | 'member'
  final String status; // 'lobi', 'berjalan', 'selesai'
  final String? note;
  final String? reminder;
  final int createdAt;

  bool get isHost => role == 'host';

  const UserRoomIndex({
    required this.roomId,
    required this.name,
    required this.code,
    required this.scheduledStart,
    required this.durationMin,
    required this.role,
    required this.status,
    this.note,
    this.reminder,
    required this.createdAt,
  });

  factory UserRoomIndex.fromMap(String id, Map<dynamic, dynamic> map) {
    return UserRoomIndex(
      roomId: id,
      name: map['name']?.toString() ?? map['title']?.toString() ?? 'Ruang Belajar',
      code: map['code']?.toString() ?? '',
      scheduledStart: (map['scheduledStart'] ?? map['startAt'] ?? map['createdAt'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      durationMin: (map['durationMin'] ?? map['durationMinutes'] as num?)?.toInt() ?? 45,
      role: map['role']?.toString() ?? 'member',
      status: map['status']?.toString() ?? 'lobi',
      note: map['note']?.toString(),
      reminder: map['reminder']?.toString(),
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'name': name,
        'code': code,
        'scheduledStart': scheduledStart,
        'durationMin': durationMin,
        'role': role,
        'status': status,
        if (note != null) 'note': note,
        if (reminder != null) 'reminder': reminder,
        'createdAt': createdAt,
      };
}
