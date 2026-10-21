import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../room/presentation/room_controller.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/notification_item.dart';
import 'notification_controller.dart';

class S22NotifikasiScreen extends ConsumerWidget {
  const S22NotifikasiScreen({super.key});

  Future<bool> _markRead(
    BuildContext context,
    WidgetRef ref,
    Iterable<String> ids,
  ) async {
    try {
      await ref.read(notificationReadProvider.notifier).markRead(ids);
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status baca gagal disimpan. Silakan coba lagi.'),
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationItemsProvider);
    final reads = ref.watch(notificationReadProvider);
    final rooms = ref.watch(userRoomsStreamProvider);
    final sessions = ref.watch(userSessionsProvider);
    final loading = rooms.isLoading || sessions.isLoading || reads.isLoading;
    final hasError = rooms.hasError || sessions.hasError || reads.hasError;
    final groups = <String, List<NotificationItem>>{};
    final now = DateTime.now();
    for (final item in items) {
      groups.putIfAbsent(item.groupAt(now), () => []).add(item);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: loading || items.isEmpty
                ? null
                : () async {
                    final saved = await _markRead(
                      context,
                      ref,
                      items.map((item) => item.id),
                    );
                    if (saved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Semua notifikasi ditandai dibaca'),
                        ),
                      );
                    }
                  },
            child: const Text('Tandai Baca'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Notifikasi belum dapat dimuat.'),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(notificationReadProvider);
                      ref.invalidate(userRoomsStreamProvider);
                      ref.invalidate(userSessionsProvider);
                    },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            )
          : items.isEmpty
          ? const Center(child: Text('Belum ada notifikasi'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final group in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 8),
                    child: Text(
                      group.key,
                      style: AppTheme.headlineSmall.copyWith(fontSize: 14),
                    ),
                  ),
                  for (final item in group.value)
                    _card(
                      context,
                      ref,
                      item,
                      reads.valueOrNull?.contains(item.id) ?? false,
                    ),
                ],
              ],
            ),
    );
  }

  Widget _card(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
    bool isRead,
  ) {
    final (icon, color) = switch (item.category) {
      NotificationCategory.sessionStarting => (
        Icons.timer_outlined,
        AppColors.primary,
      ),
      NotificationCategory.sessionCompleted => (
        Icons.check_circle_outline_rounded,
        const Color(0xFF10B981),
      ),
      NotificationCategory.sessionCancelled => (
        Icons.cancel_outlined,
        AppColors.red,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          _markRead(context, ref, [item.id]);
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(item.title),
              content: Text('${item.time}\n\n${item.message}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Tutup'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.push(item.route);
                  },
                  child: const Text('Buka Halaman'),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
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
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        if (!isRead)
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: AppColors.primary,
                            key: ValueKey('notification-unread'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.time,
                      style: AppTheme.labelSmall.copyWith(
                        color: AppColors.textMuted,
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
