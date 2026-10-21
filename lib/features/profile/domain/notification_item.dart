import 'package:intl/intl.dart';

import '../../room/domain/room_models.dart';
import '../../session/domain/session_models.dart';

enum NotificationCategory {
  sessionStarting,
  sessionCompleted,
  sessionCancelled,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final int timestamp;
  final NotificationCategory category;
  final String route;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    required this.route,
  });

  String get time => DateFormat(
    'dd/MM/yyyy HH:mm',
  ).format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  String groupAt(DateTime now) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Hari ini';
    if (day == DateTime(now.year, now.month, now.day - 1)) return 'Kemarin';
    return DateFormat('dd/MM/yyyy').format(day);
  }
}

List<NotificationItem> buildNotifications({
  required List<UserRoomIndex> rooms,
  required List<UserSessionRecord> sessions,
}) {
  final completedIds = sessions.map((session) => session.roomId).toSet();
  final items = <NotificationItem>[
    for (final room in rooms)
      if (room.status != 'selesai' && !completedIds.contains(room.roomId))
        NotificationItem(
          id: 'start_${room.roomId}',
          title: 'Ruang belajar dibuat: ${room.name}',
          message:
              'Ruang "${room.name}" dijadwalkan pada '
              '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(room.scheduledStart))}.',
          timestamp: room.createdAt,
          category: NotificationCategory.sessionStarting,
          route: '/lobby/${room.roomId}',
        ),
    for (final session in sessions)
      NotificationItem(
        id: 'sess_${session.roomId}',
        title:
            '${session.status == 'Dibatalkan' ? 'Sesi dibatalkan' : 'Sesi selesai'}: ${session.roomName}',
        message:
            'Sesi "${session.roomName}" '
            '${session.status == 'Dibatalkan' ? 'dibatalkan' : 'telah selesai (${session.durationDoneMin} menit)'}. '
            'Buka untuk melihat ringkasan sesi.',
        timestamp: session.completedAt,
        category: session.status == 'Dibatalkan'
            ? NotificationCategory.sessionCancelled
            : NotificationCategory.sessionCompleted,
        route: '/session-summary/${session.roomId}?readOnly=true',
      ),
  ];
  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items;
}
