import 'package:firebase_database/firebase_database.dart';
import '../domain/stats_model.dart';

class StatsRepository {
  final FirebaseDatabase _db;

  StatsRepository({FirebaseDatabase? db})
      : _db = db ??
            FirebaseDatabase.instanceFor(
              app: FirebaseDatabase.instance.app,
              databaseURL: 'https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/',
            );

  Stream<UserStats> watchUserStats(String uid) {
    // Listen to userRooms and userSessions updates
    return _db.ref('userRooms/$uid').onValue.asyncMap((roomEvent) async {
      int roomsCreated = 0;
      int roomsJoined = 0;

      if (roomEvent.snapshot.exists && roomEvent.snapshot.value is Map) {
        final rMap = roomEvent.snapshot.value as Map;
        rMap.forEach((_, v) {
          if (v is Map) {
            final role = v['role']?.toString();
            if (role == 'host') {
              roomsCreated++;
            } else {
              roomsJoined++;
            }
          }
        });
      }

      int sessionsCompleted = 0;
      int totalMinutes = 0;
      int totalViolations = 0;

      // 7 days weekly activity in current device week (Monday..Sunday)
      final now = DateTime.now();
      final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
      final mondayStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: currentWeekday - 1));
      final sundayEnd = mondayStart.add(const Duration(days: 7));
      final weeklyActivity = List<bool>.filled(7, false);
      final dailyMinutes = List<int>.filled(7, 0);

      try {
        final sessSnap = await _db.ref('userSessions/$uid').get();
        if (sessSnap.exists && sessSnap.value is Map) {
          final sMap = sessSnap.value as Map;
          sMap.forEach((_, val) {
            if (val is Map) {
              final status = val['status']?.toString();
              if (status == 'Selesai') sessionsCompleted++;

              final duration = (val['durationDoneMin'] as num?)?.toInt() ?? 0;
              totalMinutes += duration;

              final viol = (val['violationCount'] as num?)?.toInt() ?? 0;
              totalViolations += viol;

              // Check if completed in current week
              final completedAt = (val['completedAt'] as num?)?.toInt();
              if (completedAt != null) {
                final date = DateTime.fromMillisecondsSinceEpoch(completedAt);
                if (date.isAfter(mondayStart) && date.isBefore(sundayEnd)) {
                  final dayIndex = date.weekday - 1; // 0..6
                  if (dayIndex >= 0 && dayIndex < 7) {
                    weeklyActivity[dayIndex] = true;
                    dailyMinutes[dayIndex] += duration;
                  }
                }
              }
            }
          });
        }
      } catch (_) {}

      // Hitung persentase capaian performa real
      // Rasio keberhasilan: jika ada sesi, 100 - (gangguan * 5) dengan batas min 0
      double perfPercent = 0.0;
      if (sessionsCompleted > 0) {
        final penalty = totalViolations * 5.0;
        perfPercent = (100.0 - penalty).clamp(10.0, 100.0);
      } else if (roomsCreated > 0 || roomsJoined > 0) {
        perfPercent = 100.0; // Baru membuat ruang, target awal optimal
      }

      return UserStats(
        roomsCreated: roomsCreated,
        roomsJoined: roomsJoined,
        sessionsCompleted: sessionsCompleted,
        totalFocusHours: totalMinutes / 60.0,
        totalViolations: totalViolations,
        performancePercent: perfPercent,
        weeklyActivity: weeklyActivity,
        dailyMinutes: dailyMinutes,
      );
    });
  }
}
