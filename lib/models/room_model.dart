import 'dart:convert';

enum MemberStatus {
  focusing, // Sedang fokus, HP ditaruh di meja
  phoneLifted, // Terdistraksi, HP diangkat/digerakkan
  away, // Tidak aktif / keluar
}

class Member {
  final String id;
  final String name;
  final bool isLeader;
  MemberStatus status;
  int distractionCount;
  DateTime? lastDistractionTime;
  double lastAccelerationMagnitude;
  double pitch;
  double roll;
  double vibration;
  String? avatarUrl;

  Member({
    required this.id,
    required this.name,
    this.isLeader = false,
    this.status = MemberStatus.focusing,
    this.distractionCount = 0,
    this.lastDistractionTime,
    this.lastAccelerationMagnitude = 0.0,
    this.pitch = 0.0,
    this.roll = 0.0,
    this.vibration = 0.0,
    this.avatarUrl,
  });

  bool get isPhoneLifted => status == MemberStatus.phoneLifted;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isLeader': isLeader,
      'status': status.name,
      'distractionCount': distractionCount,
      'lastDistractionTime': lastDistractionTime?.toIso8601String(),
      'lastAccelerationMagnitude': lastAccelerationMagnitude,
      'pitch': pitch,
      'roll': roll,
      'vibration': vibration,
      'avatarUrl': avatarUrl,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Peserta',
      isLeader: map['isLeader'] == true,
      status: MemberStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MemberStatus.focusing,
      ),
      distractionCount: (map['distractionCount'] as num?)?.toInt() ?? 0,
      lastDistractionTime: map['lastDistractionTime'] != null
          ? DateTime.tryParse(map['lastDistractionTime'].toString())
          : null,
      lastAccelerationMagnitude: (map['lastAccelerationMagnitude'] as num?)?.toDouble() ?? 0.0,
      pitch: (map['pitch'] as num?)?.toDouble() ?? 0.0,
      roll: (map['roll'] as num?)?.toDouble() ?? 0.0,
      vibration: (map['vibration'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: map['avatarUrl']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());
  factory Member.fromJson(String source) => Member.fromMap(json.decode(source));
}

class StudyRoom {
  final String id;
  final String code;
  final String title;
  final String leaderId;
  final int durationMinutes;
  final DateTime createdAt;
  bool isSessionActive;
  List<Member> members;

  StudyRoom({
    required this.id,
    required this.code,
    required this.title,
    required this.leaderId,
    required this.durationMinutes,
    required this.createdAt,
    this.isSessionActive = false,
    List<Member>? members,
  }) : members = members ?? [];

  Map<String, dynamic> toMap() {
    // Simpan members dalam bentuk Map id -> memberMap agar kompatibel dengan Firebase RTDB
    final membersMap = <String, dynamic>{};
    for (final m in members) {
      membersMap[m.id] = m.toMap();
    }

    return {
      'id': id,
      'code': code,
      'title': title,
      'leaderId': leaderId,
      'durationMinutes': durationMinutes,
      'createdAt': createdAt.toIso8601String(),
      'isSessionActive': isSessionActive,
      'members': membersMap,
    };
  }

  factory StudyRoom.fromMap(Map<String, dynamic> map) {
    List<Member> parsedMembers = [];
    final rawMembers = map['members'];

    if (rawMembers is Map) {
      rawMembers.forEach((key, value) {
        if (value is Map) {
          parsedMembers.add(Member.fromMap(Map<String, dynamic>.from(value)));
        }
      });
    } else if (rawMembers is List) {
      parsedMembers = rawMembers
          .whereType<Map>()
          .map((x) => Member.fromMap(Map<String, dynamic>.from(x)))
          .toList();
    }

    return StudyRoom(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Ruang Belajar',
      leaderId: map['leaderId']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 45,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isSessionActive: map['isSessionActive'] == true,
      members: parsedMembers,
    );
  }
}
