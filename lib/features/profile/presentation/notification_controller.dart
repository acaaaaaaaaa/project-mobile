import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../room/presentation/room_controller.dart';
import '../../session/presentation/session_controller.dart';
import '../data/notification_repository.dart';
import '../domain/notification_item.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationItemsProvider = Provider<List<NotificationItem>>((ref) {
  return buildNotifications(
    rooms: ref.watch(userRoomsStreamProvider).valueOrNull ?? [],
    sessions: ref.watch(userSessionsProvider).valueOrNull ?? [],
  );
});

class NotificationReadController
    extends StateNotifier<AsyncValue<Set<String>>> {
  final NotificationRepository repository;
  final String? uid;
  StreamSubscription<Set<String>>? _subscription;
  Set<String> _storedIds = {};
  final Set<String> _pendingIds = {};

  NotificationReadController(this.repository, this.uid)
    : super(uid == null ? const AsyncData(<String>{}) : const AsyncLoading()) {
    if (uid != null) {
      _subscription = repository
          .watchReadIds(uid!)
          .listen(
            (ids) {
              _storedIds = ids;
              state = AsyncData({..._storedIds, ..._pendingIds});
            },
            onError: (Object error, StackTrace stack) {
              state = AsyncError(error, stack);
            },
          );
    }
  }

  Future<void> markRead(Iterable<String> ids) async {
    if (uid == null) return;
    final added = ids.toSet().difference(_storedIds).difference(_pendingIds);
    if (added.isEmpty) return;
    _pendingIds.addAll(added);
    state = AsyncData({..._storedIds, ..._pendingIds});
    try {
      await repository.markRead(uid!, added);
      _storedIds.addAll(added);
    } finally {
      _pendingIds.removeAll(added);
      if (mounted) state = AsyncData({..._storedIds, ..._pendingIds});
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final notificationReadProvider =
    StateNotifierProvider<NotificationReadController, AsyncValue<Set<String>>>((
      ref,
    ) {
      final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
      return NotificationReadController(
        ref.watch(notificationRepositoryProvider),
        uid,
      );
    });

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final reads = ref.watch(notificationReadProvider);
  if (!reads.hasValue) return false;
  return ref
      .watch(notificationItemsProvider)
      .any((item) => !reads.value!.contains(item.id));
});
