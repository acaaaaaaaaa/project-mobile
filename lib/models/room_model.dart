import 'dart:convert';

enum MemberStatus {
  focusing, // Sedang fokus, HP ditaruh di meja
  phoneLifted, // Terdistraksi, HP diangkat/digerakkan
  away, // Tidak aktif
}

class Member {
  final String id;
  final String name;
  final bool isLeader;
  MemberStatus status;
  int distractionCount;
  DateTime? lastDistractionTime;
  double lastAccelerationMagnitude;

  Member({
    required this.id,
    required this.name,
    this.isLeader = false,
    this.status = MemberStatus.focusing,
    this.distractionCount = 0,
    this.lastDistractionTime,
    this.lastAccelerationMagnitude = 0.0,
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
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Peserta',
      isLeader: map['isLeader'] ?? false,
      status: MemberStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MemberStatus.focusing,
      ),
      distractionCount: map['distractionCount'] ?? 0,
      lastDistractionTime: map['lastDistractionTime'] != null
          ? DateTime.tryParse(map['lastDistractionTime'])
          : null,
      lastAccelerationMagnitude: (map['lastAccelerationMagnitude'] as num?)?.toDouble() ?? 0.0,
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
    return {
      'id': id,
      'code': code,
      'title': title,
      'leaderId': leaderId,
      'durationMinutes': durationMinutes,
      'createdAt': createdAt.toIso8601String(),
      'isSessionActive': isSessionActive,
      'members': members.map((x) => x.toMap()).toList(),
    };
  }

  factory StudyRoom.fromMap(Map<String, dynamic> map) {
    return StudyRoom(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      title: map['title'] ?? 'Ruang Belajar',
      leaderId: map['leaderId'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 45,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isSessionActive: map['isSessionActive'] ?? false,
      members: (map['members'] as List<dynamic>?)
              ?.map((x) => Member.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
