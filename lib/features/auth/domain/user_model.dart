class UserSettings {
  final double tiltToleranceDeg;
  final String alarmMode;
  final String monitorPermission;
  final double volume;

  const UserSettings({
    this.tiltToleranceDeg = 15.0,
    this.alarmMode = 'both',
    this.monitorPermission = 'whileSession',
    this.volume = 0.8,
  });

  factory UserSettings.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const UserSettings();
    return UserSettings(
      tiltToleranceDeg: (map['tiltToleranceDeg'] as num?)?.toDouble() ?? 15.0,
      alarmMode: map['alarmMode']?.toString() ?? 'both',
      monitorPermission: map['monitorPermission']?.toString() ?? 'whileSession',
      volume: (map['volume'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tiltToleranceDeg': tiltToleranceDeg,
      'alarmMode': alarmMode,
      'monitorPermission': monitorPermission,
      'volume': volume,
    };
  }
}

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String provider;
  final String photoUrl;
  final UserSettings settings;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.provider,
    this.photoUrl = '',
    this.settings = const UserSettings(),
  });

  factory AppUser.fromMap(String uid, Map<dynamic, dynamic> map) {
    return AppUser(
      uid: uid,
      displayName: map['displayName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      provider: map['provider']?.toString() ?? 'password',
      photoUrl: map['photoUrl']?.toString() ?? '',
      settings: UserSettings.fromMap(
        map['settings'] is Map ? map['settings'] as Map : null,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'provider': provider,
      'photoUrl': photoUrl,
      'settings': settings.toMap(),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? provider,
    String? photoUrl,
    UserSettings? settings,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      photoUrl: photoUrl ?? this.photoUrl,
      settings: settings ?? this.settings,
    );
  }
}
