import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:focus_room/core/router/app_back_button_dispatcher.dart';
import 'package:focus_room/core/router/session_access_gate.dart';
import 'package:focus_room/core/widgets/avatar_circle.dart';
import 'package:focus_room/core/widgets/bottom_nav_shell.dart';
import 'package:focus_room/features/auth/domain/user_model.dart';
import 'package:focus_room/features/auth/presentation/auth_controller.dart';
import 'package:focus_room/features/home/presentation/s04_beranda_screen.dart';
import 'package:focus_room/features/profile/data/notification_repository.dart';
import 'package:focus_room/features/profile/domain/notification_item.dart';
import 'package:focus_room/features/profile/presentation/notification_controller.dart';
import 'package:focus_room/features/profile/presentation/s22_notifikasi_screen.dart';
import 'package:focus_room/features/room/domain/room_models.dart';
import 'package:focus_room/features/room/presentation/room_controller.dart';
import 'package:focus_room/features/session/domain/server_time_service.dart';
import 'package:focus_room/features/session/domain/session_models.dart';
import 'package:focus_room/features/session/presentation/session_controller.dart';
import 'package:focus_room/features/stats/domain/stats_model.dart';
import 'package:focus_room/features/stats/presentation/stats_controller.dart';

class MemoryNotificationRepository extends NotificationRepository {
  final stored = <String, Set<String>>{};
  bool failWrites = false;

  @override
  Stream<Set<String>> watchReadIds(String uid) =>
      Stream.value({...?stored[uid]});

  @override
  Future<void> markRead(String uid, Set<String> ids) async {
    if (failWrites) throw StateError('offline');
    stored.putIfAbsent(uid, () => {}).addAll(ids);
  }
}

UserSessionRecord record(String id, DateTime completed) => UserSessionRecord(
  roomId: id,
  roomName: 'Belajar $id',
  startAt: completed
      .subtract(const Duration(minutes: 25))
      .millisecondsSinceEpoch,
  completedAt: completed.millisecondsSinceEpoch,
  durationDoneMin: 25,
  violationCount: 0,
  endedHow: 'timer',
);

void main() {
  test(
    'Notifications use completion dates, including dates older than yesterday',
    () {
      final now = DateTime(2026, 10, 21, 10);
      final items = buildNotifications(
        rooms: [],
        sessions: [
          record('today', now),
          record('yesterday', DateTime(2026, 10, 20, 23)),
          record('old', DateTime(2026, 10, 18)),
        ],
      );
      expect(items.map((item) => item.groupAt(now)), [
        'Hari ini',
        'Kemarin',
        '18/10/2026',
      ]);
      expect(items.first.route, '/session-summary/today?readOnly=true');
      expect(buildNotifications(rooms: [], sessions: []), isEmpty);
    },
  );

  test(
    'Scheduled rooms group by creation date and completed rooms cannot open lobby',
    () {
      final created = DateTime(2026, 10, 21, 9);
      final room = UserRoomIndex(
        roomId: 'one',
        name: 'Kelompok',
        code: 'ABC123',
        scheduledStart: DateTime(2026, 10, 25).millisecondsSinceEpoch,
        durationMin: 25,
        role: 'host',
        status: 'lobi',
        createdAt: created.millisecondsSinceEpoch,
      );
      final items = buildNotifications(rooms: [room], sessions: []);
      expect(items.single.groupAt(created), 'Hari ini');
      expect(items.single.time, '21/10/2026 09:00');
      final finished = buildNotifications(
        rooms: [room],
        sessions: [record('one', created)],
      );
      expect(finished.length, 1);
      expect(finished.single.category, NotificationCategory.sessionCompleted);
    },
  );

  test(
    'Read status survives controller recreation and stays isolated per account',
    () async {
      final repository = MemoryNotificationRepository();
      final first = NotificationReadController(repository, 'roma');
      await Future<void>.delayed(Duration.zero);
      await first.markRead(['one', 'two']);
      first.dispose();
      final reopened = NotificationReadController(repository, 'roma');
      final other = NotificationReadController(repository, 'other');
      await Future<void>.delayed(Duration.zero);
      expect(reopened.state.value, {'one', 'two'});
      expect(other.state.value, isEmpty);
      reopened.dispose();
      other.dispose();
    },
  );

  test(
    'Failed read writes roll back instead of falsely claiming persistence',
    () async {
      final repository = MemoryNotificationRepository()..failWrites = true;
      final controller = NotificationReadController(repository, 'roma');
      await Future<void>.delayed(Duration.zero);
      await expectLater(controller.markRead(['one']), throwsStateError);
      expect(controller.state.value, isEmpty);
      controller.dispose();
    },
  );

  testWidgets('Mark all read stays read when notification page is reopened', (
    tester,
  ) async {
    final repository = MemoryNotificationRepository();
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const S22NotifikasiScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => Stream.value(
              const AppUser(
                uid: 'roma',
                displayName: 'Roma',
                email: 'roma@example.com',
                provider: 'password',
              ),
            ),
          ),
          userRoomsStreamProvider.overrideWith((ref) => Stream.value([])),
          userSessionsProvider.overrideWith(
            (ref) => Stream.value([record('one', DateTime.now())]),
          ),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-unread')), findsOneWidget);
    await tester.tap(find.text('Tandai Baca'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-unread')), findsNothing);
    router.go('/home');
    await tester.pumpAndSettle();
    router.go('/notifications');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-unread')), findsNothing);
    expect(repository.stored['roma'], {'sess_one'});
  });

  testWidgets('Dashboard waits for profile and greets the registered name', (
    tester,
  ) async {
    final userStream = StreamController<AppUser?>();
    addTearDown(userStream.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => userStream.stream),
          notificationRepositoryProvider.overrideWithValue(
            MemoryNotificationRepository(),
          ),
          userRoomsStreamProvider.overrideWith((ref) => Stream.value([])),
          userSessionsProvider.overrideWith((ref) => Stream.value([])),
          userActiveRoomBannerProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
          userStatsStreamProvider.overrideWith(
            (ref) => Stream.value(const UserStats()),
          ),
        ],
        child: const MaterialApp(home: S04BerandaScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Memuat profil...'), findsOneWidget);
    expect(find.textContaining('Farhan'), findsNothing);
    userStream.add(
      const AppUser(
        uid: 'roma',
        displayName: 'Roma Putri',
        email: 'roma@example.com',
        provider: 'password',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Halo, Roma'), findsOneWidget);
  });

  testWidgets('Avatar reuses decoded image when member heartbeat rebuilds', (
    tester,
  ) async {
    final png =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    await tester.pumpWidget(
      MaterialApp(
        home: AvatarCircle(name: 'Roma', photoUrl: png),
      ),
    );
    await tester.pumpAndSettle();
    final provider = tester.widget<Image>(find.byType(Image)).image;
    await tester.pumpWidget(
      MaterialApp(
        home: AvatarCircle(name: 'Roma Putri', photoUrl: png),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      identical(tester.widget<Image>(find.byType(Image)).image, provider),
      isTrue,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: AvatarCircle(
          name: 'Roma',
          photoUrl: 'data:image/png;base64,invalid',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('R'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final status in ['selesai', 'berjalan']) {
    testWidgets(
      'Completed or expired $status room never mounts session child',
      (tester) async {
        final room = RoomModel(
          id: 'one',
          code: 'ABC123',
          name: 'Belajar',
          hostUid: 'roma',
          durationMinutes: 25,
          status: status,
          createdAt: 1,
          remainingSeconds: 0,
          endAt: 2,
        );
        var childMounted = false;
        final router = GoRouter(
          initialLocation: '/calibration/one',
          routes: [
            GoRoute(
              path: '/calibration/:id',
              builder: (_, _) => SessionAccessGate(
                roomId: 'one',
                child: Builder(
                  builder: (_) {
                    childMounted = true;
                    return const Text('Calibration');
                  },
                ),
              ),
            ),
            GoRoute(
              path: '/session-summary/:id',
              builder: (_, _) => const Scaffold(body: Text('Ringkasan Sesi')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roomProvider('one').overrideWith((ref) => Stream.value(room)),
              userSessionsProvider.overrideWith((ref) => Stream.value([])),
              serverTimeServiceProvider.overrideWith(
                (ref) => ServerTimeService(),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Ringkasan Sesi'), findsOneWidget);
        expect(childMounted, isFalse);
      },
    );
  }

  testWidgets(
    'Active running room that has not ended allows re-entry even if user has previous record',
    (tester) async {
      final now = DateTime.now();
      final room = RoomModel(
        id: 'one',
        code: 'ABC123',
        name: 'Belajar',
        hostUid: 'roma',
        durationMinutes: 25,
        status: 'berjalan',
        createdAt: now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
        remainingSeconds: 20 * 60,
        endAt: now.add(const Duration(minutes: 20)).millisecondsSinceEpoch,
      );
      var childMounted = false;
      final router = GoRouter(
        initialLocation: '/active-session/one',
        routes: [
          GoRoute(
            path: '/active-session/:id',
            builder: (_, _) => SessionAccessGate(
              roomId: 'one',
              child: Builder(
                builder: (_) {
                  childMounted = true;
                  return const Text('Active Session Screen');
                },
              ),
            ),
          ),
          GoRoute(
            path: '/session-summary/:id',
            builder: (_, _) => const Scaffold(body: Text('Ringkasan Sesi')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomProvider('one').overrideWith((ref) => Stream.value(room)),
            userSessionsProvider.overrideWith(
              (ref) => Stream.value([record('one', now)]),
            ),
            serverTimeServiceProvider.overrideWith(
              (ref) => ServerTimeService(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Active Session Screen'), findsOneWidget);
      expect(childMounted, isTrue);
    },
  );

  testWidgets(
    'Hardware back pops one page, returns root tab to dashboard, then confirms exit',
    (tester) async {
      final key = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: key,
        initialLocation: '/profile',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => RootBackScope(
              router: GoRouter.of(context),
              navigatorKey: key,
              child: BottomNavShell(navigationShell: shell),
            ),
            branches: [
              for (final path in ['/home', '/rooms', '/history', '/profile'])
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: path,
                      builder: (context, state) => RootBackScope(
                        router: GoRouter.of(context),
                        navigatorKey: key,
                        child: Scaffold(body: Text(path)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          GoRoute(
            path: '/edit-profile',
            builder: (context, state) => RootBackScope(
              router: GoRouter.of(context),
              navigatorKey: key,
              child: const Scaffold(body: Text('/edit-profile')),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      final dispatcher = AppBackButtonDispatcher(
        router: router,
        navigatorKey: key,
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
          backButtonDispatcher: dispatcher,
        ),
      );
      await tester.pumpAndSettle();
      router.push('/edit-profile');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('/profile'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('/home'), findsOneWidget);
      final pendingBack = tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari aplikasi?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      await pendingBack;
      expect(find.text('/home'), findsOneWidget);
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final exitBack = tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      await exitBack;
      expect(calls.any((call) => call.method == 'SystemNavigator.pop'), isTrue);
    },
  );
}
