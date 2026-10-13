class UserStats {
  final int roomsCreated; // dari userRooms/{uid} dengan role == 'host'
  final int roomsJoined; // dari userRooms/{uid} dengan role == 'member'
  final int sessionsCompleted; // dari userSessions/{uid} dengan status == 'Selesai'
  final double totalFocusHours; // sum(durationDoneMin) / 60 dari userSessions/{uid}
  final int totalViolations; // sum(violationCount) dari userSessions/{uid}
  final double performancePercent; // persentase kedisiplinan dan capaian mingguan real
  final List<bool> weeklyActivity; // 7 hari (Sen..Min) aktivitas di minggu berjalan
  final List<int> dailyMinutes; // Total menit fokus per hari (Sen..Min) minggu berjalan

  const UserStats({
    this.roomsCreated = 0,
    this.roomsJoined = 0,
    this.sessionsCompleted = 0,
    this.totalFocusHours = 0.0,
    this.totalViolations = 0,
    this.performancePercent = 0.0,
    this.weeklyActivity = const [false, false, false, false, false, false, false],
    this.dailyMinutes = const [0, 0, 0, 0, 0, 0, 0],
  });
}
