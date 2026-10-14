import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../room/presentation/room_controller.dart';
import '../../session/presentation/session_controller.dart';

enum NotificationCategory {
  sessionStarting,
  sessionCompleted,
  memberUpdate,
  sessionCancelled,
  systemNotice,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String group; // 'Hari ini' or 'Kemarin'
  final NotificationCategory category;
  final bool isRead;
  final String? route;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.group,
    required this.category,
    this.isRead = false,
    this.route,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      time: time,
      group: group,
      category: category,
      isRead: isRead ?? this.isRead,
      route: route,
    );
  }
}

class S22NotifikasiScreen extends ConsumerStatefulWidget {
  const S22NotifikasiScreen({super.key});

  @override
  ConsumerState<S22NotifikasiScreen> createState() => _S22NotifikasiScreenState();
}

class _S22NotifikasiScreenState extends ConsumerState<S22NotifikasiScreen> {
  final Set<String> _readIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadNotifications();
  }

  Future<void> _loadReadNotifications() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snap = await FirebaseDatabase.instance.ref('userNotifications/$uid').get();
      if (snap.exists && snap.value is Map) {
        final map = snap.value as Map;
        final loaded = <String>{};
        map.forEach((k, v) {
          if (v == true || v == 'read') loaded.add(k.toString());
        });
        if (mounted) {
          setState(() {
            _readIds.addAll(loaded);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _markAsRead(String id) async {
    setState(() {
      _readIds.add(id);
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseDatabase.instance.ref('userNotifications/$uid/$id').set(true);
      }
    } catch (_) {}
  }

  Future<void> _markAllAsRead(List<NotificationItem> items) async {
    setState(() {
      _readIds.addAll(items.map((n) => n.id));
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final updates = <String, dynamic>{};
        for (final item in items) {
          updates[item.id] = true;
        }
        await FirebaseDatabase.instance.ref('userNotifications/$uid').update(updates);
      }
    } catch (_) {}
  }

  List<NotificationItem> _generateNotifications() {
    final userRooms = ref.watch(userRoomsStreamProvider).value ?? [];
    final allRooms = ref.watch(allRoomsProvider).value ?? [];
    final sessions = ref.watch(userSessionsProvider).value ?? [];

    final list = <NotificationItem>[];

    // 1. Notifikasi dari ruang aktif milik pengguna
    if (userRooms.isNotEmpty) {
      final activeRooms = userRooms.where((r) => r.status != 'selesai').toList();
      for (final room in activeRooms) {
        list.add(
          NotificationItem(
            id: 'start_${room.roomId}',
            title: 'Sesi akan dimulai: ${room.name}',
            message: 'Ruang "${room.name}" dijadwalkan segera. Klik untuk masuk ke lobi ruangan.',
            time: '15 menit lagi',
            group: 'Hari ini',
            category: NotificationCategory.sessionStarting,
            route: '/lobby/${room.roomId}',
          ),
        );

        list.add(
          NotificationItem(
            id: 'member_${room.roomId}',
            title: 'Pembaruan anggota: ${room.name}',
            message: 'Anggota telah bergabung di ruang "${room.name}". Buka lobi untuk melihat daftar anggota.',
            time: '1 jam lalu',
            group: 'Hari ini',
            category: NotificationCategory.memberUpdate,
            route: '/lobby/${room.roomId}',
          ),
        );
      }
    } else if (allRooms.isNotEmpty) {
      final room = allRooms.first;
      list.add(
        NotificationItem(
          id: 'room_${room.id}',
          title: 'Sesi akan dimulai: ${room.name}',
          message: 'Ruang "${room.name}" siap digunakan. Klik untuk masuk ke lobi.',
          time: '30 menit lalu',
          group: 'Hari ini',
          category: NotificationCategory.sessionStarting,
          route: '/lobby/${room.id}',
        ),
      );
    } else {
      list.add(
        const NotificationItem(
          id: 'notif_default_1',
          title: 'Ruang belajar siap',
          message: 'Buat atau gabung ke ruang belajar kelompok Anda.',
          time: 'Baru saja',
          group: 'Hari ini',
          category: NotificationCategory.sessionStarting,
          route: '/rooms',
        ),
      );
    }

    // 2. Notifikasi dari sesi yang telah selesai
    if (sessions.isNotEmpty) {
      for (final sess in sessions.take(3)) {
        list.add(
          NotificationItem(
            id: 'sess_${sess.roomId}',
            title: 'Sesi selesai: ${sess.roomName}',
            message: 'Sesi "${sess.roomName}" telah diselesaikan (${sess.durationDoneMin} menit). Klik untuk melihat detail riwayat.',
            time: 'Kemarin',
            group: 'Kemarin',
            category: NotificationCategory.sessionCompleted,
            route: '/history-detail/${sess.roomId}',
          ),
        );
      }
    }

    // 3. Notifikasi sistem dan kalibrasi
    list.add(
      const NotificationItem(
        id: 'notif_sys_sensor',
        title: 'Sensitivitas Sensor Siap',
        message: 'Pengaturan kalibrasi gravitasi dan batas kemiringan siap digunakan. Klik untuk cek kalibrasi.',
        time: 'Kemarin, 09:00',
        group: 'Kemarin',
        category: NotificationCategory.systemNotice,
        route: '/sensor-sensitivity',
      ),
    );

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _generateNotifications();
    final todayList = notifications.where((n) => n.group == 'Hari ini').toList();
    final yesterdayList = notifications.where((n) => n.group == 'Kemarin').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Notifikasi',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              _markAllAsRead(notifications);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua notifikasi ditandai dibaca'),
                  backgroundColor: AppColors.navy,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Text(
              'Tandai Baca',
              style: AppTheme.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            if (todayList.isNotEmpty) ...[
              _buildSectionHeader('Hari ini'),
              const SizedBox(height: 8),
              ...todayList.map((item) => _buildNotificationCard(item)),
              const SizedBox(height: 18),
            ],
            if (yesterdayList.isNotEmpty) ...[
              _buildSectionHeader('Kemarin'),
              const SizedBox(height: 8),
              ...yesterdayList.map((item) => _buildNotificationCard(item)),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  void _showNotificationDetail(NotificationItem item, ({IconData icon, Color color, Color bg}) style) {
    _markAsRead(item.id);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(style.icon, color: style.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: AppTheme.headlineSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  item.time,
                  style: AppTheme.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.message,
              style: AppTheme.bodyMedium.copyWith(color: AppColors.textPrimary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: AppColors.textMuted)),
          ),
          if (item.route != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                final route = item.route!;
                if (route.startsWith('/lobby/') ||
                    route.startsWith('/active-session/') ||
                    route.startsWith('/history-detail/') ||
                    route.startsWith('/sensor-sensitivity')) {
                  context.push(route);
                } else {
                  context.go(route);
                }
              },
              child: const Text('Buka Halaman'),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: AppTheme.headlineSmall.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final isRead = _readIds.contains(item.id);

    final ({IconData icon, Color color, Color bg}) style = switch (item.category) {
      NotificationCategory.sessionStarting => (
        icon: Icons.timer_outlined,
        color: AppColors.primary,
        bg: const Color(0xFFEFF6FF),
      ),
      NotificationCategory.sessionCompleted => (
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF10B981),
        bg: const Color(0xFFECFDF5),
      ),
      NotificationCategory.memberUpdate => (
        icon: Icons.group_outlined,
        color: const Color(0xFF0284C7),
        bg: const Color(0xFFE0F2FE),
      ),
      NotificationCategory.sessionCancelled => (
        icon: Icons.cancel_outlined,
        color: AppColors.red,
        bg: const Color(0xFFFEE2E2),
      ),
      NotificationCategory.systemNotice => (
        icon: Icons.info_outline_rounded,
        color: AppColors.navy,
        bg: const Color(0xFFF1F5F9),
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showNotificationDetail(item, style),
        borderRadius: BorderRadius.circular(16),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          // Subtle highlight if unread
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                              color: AppColors.navy,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      style: AppTheme.bodySmall.copyWith(
                        color: isRead ? AppColors.textMuted : AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.time,
                      style: AppTheme.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
