class RoomEvent {
  final String key;
  final String type; // 'violation' | 'keluar'
  final String title;
  final String uid; // Real FirebaseAuth UID
  final int tsServer;
  final int clientTs;
  final double deltaTiltDeg;
  final double zScore;

  const RoomEvent({
    required this.key,
    required this.type,
    this.title = '',
    required this.uid,
    required this.tsServer,
    required this.clientTs,
    required this.deltaTiltDeg,
    required this.zScore,
  });

  factory RoomEvent.fromMap(String key, Map map) {
    return RoomEvent(
      key: key,
      type: map['type'] as String? ?? 'violation',
      title: map['title'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      tsServer: (map['tsServer'] as num?)?.toInt() ?? 0,
      clientTs: (map['clientTs'] as num?)?.toInt() ?? 0,
      deltaTiltDeg: (map['deltaTiltDeg'] as num?)?.toDouble() ?? 0.0,
      zScore: (map['zScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'title': title,
        'uid': uid,
        'tsServer': tsServer,
        'clientTs': clientTs,
        'deltaTiltDeg': deltaTiltDeg,
        'zScore': zScore,
      };
}

class UserSessionRecord {
  final String roomId;
  final String roomName;
  final int startAt;
  final int completedAt;
  final int durationDoneMin;
  final int violationCount;
  final String endedHow; // 'timer' | 'host' | 'keluar'
  final String? note;
  final String? roomCode;
  final bool isCreatedByMe;
  final String status; // 'Selesai' | 'Dibatalkan'
  final int memberCount;
  final String? meetingLink;

  const UserSessionRecord({
    required this.roomId,
    required this.roomName,
    required this.startAt,
    int? completedAt,
    required this.durationDoneMin,
    required this.violationCount,
    required this.endedHow,
    this.note,
    this.roomCode,
    this.isCreatedByMe = false,
    this.status = 'Selesai',
    this.memberCount = 1,
    this.meetingLink,
  }) : completedAt = completedAt ?? (startAt + (durationDoneMin * 60 * 1000));

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'roomName': roomName,
        'startAt': startAt,
        'completedAt': completedAt,
        'durationDoneMin': durationDoneMin,
        'durationMinutes': durationDoneMin,
        'violationCount': violationCount,
        'distractionCount': violationCount,
        'endedHow': endedHow,
        if (note != null) 'note': note,
        if (roomCode != null) 'roomCode': roomCode,
        'isCreatedByMe': isCreatedByMe,
        'status': status,
        'memberCount': memberCount,
        if (meetingLink != null) 'meetingLink': meetingLink,
      };

  factory UserSessionRecord.fromMap(String roomId, Map map) {
    final int start = (map['startAt'] as num?)?.toInt() ?? 0;
    final int dur = ((map['durationDoneMin'] ?? map['durationMinutes']) as num?)?.toInt() ?? 0;
    final int comp = (map['completedAt'] as num?)?.toInt() ??
        (start > 0 ? (start + (dur * 60 * 1000)) : DateTime.now().millisecondsSinceEpoch);

    return UserSessionRecord(
      roomId: roomId,
      roomName: map['roomName'] as String? ?? 'Sesi Fokus',
      startAt: start,
      completedAt: comp,
      durationDoneMin: dur,
      violationCount: (map['violationCount'] ?? map['distractionCount'] as num?)?.toInt() ?? 0,
      endedHow: map['endedHow'] as String? ?? 'timer',
      note: map['note'] as String?,
      roomCode: map['roomCode'] as String?,
      isCreatedByMe: map['isCreatedByMe'] == true,
      status: map['status'] as String? ?? 'Selesai',
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 1,
      meetingLink: map['meetingLink'] as String?,
    );
  }
}
