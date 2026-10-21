import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/s00_landing_screen.dart';
import '../../features/auth/presentation/s01_splash_screen.dart';
import '../../features/auth/presentation/s02_masuk_screen.dart';
import '../../features/auth/presentation/s03_lengkapi_profil_screen.dart';
import '../../features/auth/presentation/s18_daftar_screen.dart';
import '../../features/auth/presentation/s02_sheet_lupa_kata_sandi.dart';

import '../../features/home/presentation/s04_beranda_screen.dart';
import '../../features/history/presentation/s13_riwayat_screen.dart';
import '../../features/history/presentation/s24_detail_riwayat_screen.dart';
import '../../features/profile/presentation/s14_profil_screen.dart';
import '../../features/profile/presentation/s15_edit_profil_screen.dart';
import '../../features/profile/presentation/s16_sensitivitas_sensor_screen.dart';
import '../../features/profile/presentation/s17_pengaturan_alarm_screen.dart';
import '../../features/profile/presentation/s22_notifikasi_screen.dart';
import '../../features/profile/presentation/s23_tentang_aplikasi_screen.dart';
import '../../features/profile/presentation/s25_pengaturan_akun_screen.dart';

import '../../features/room/presentation/s05_sheet_buat_ruang.dart';
import '../../features/room/presentation/s06_sheet_gabung_kode.dart';
import '../../features/room/presentation/s07_lobi_screen.dart';
import '../../features/room/presentation/s20_daftar_ruang_screen.dart';
import '../../features/sensor/presentation/s08_kalibrasi_screen.dart';
import '../../features/sensor/presentation/s19_sheet_izin_pemantauan.dart';
import '../../features/session/presentation/s09_sesi_aktif_screen.dart';
import '../../features/session/presentation/s10_alarm_pelanggar_screen.dart';
import '../../features/session/presentation/s11_alarm_anggota_lain_screen.dart';
import '../../features/session/presentation/s12_ringkasan_sesi_screen.dart';

import 'dart:async';
import '../../features/debug/presentation/data_inspector_screen.dart';
import '../widgets/bottom_nav_shell.dart';
import 'session_access_gate.dart';
import 'app_back_button_dispatcher.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  _AuthRefreshNotifier(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRoute _rootRoute({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
}) => GoRoute(
  path: path,
  builder: (context, state) {
    final child = builder(context, state);
      if (path == '/' || path == '/landing' || path == '/active-session/:roomId') {
      return child;
      }
    return RootBackScope(
      router: GoRouter.of(context),
      navigatorKey: rootNavigatorKey,
      child: child,
    );
  },
);

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final notifier = _AuthRefreshNotifier(authRepo.authStateChanges);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = authRepo.currentFirebaseUser != null;
      final isAuthRoute =
          state.matchedLocation == '/landing' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isSplash = state.matchedLocation == '/';

      if (isSplash) return null; // Let splash perform initial check

      if (!isLoggedIn && !isAuthRoute) {
        return '/landing';
      }

      // Login/registration chooses its destination after the profile is saved.
      if (isLoggedIn && state.matchedLocation == '/landing') {
        return '/home';
      }

      return null;
    },
    routes: [
      _rootRoute(
        path: '/',
        builder: (context, state) => const S01SplashScreen(),
      ),
      _rootRoute(
        path: '/landing',
        builder: (context, state) => const S00LandingScreen(),
      ),
      _rootRoute(
        path: '/login',
        builder: (context, state) => const S02MasukScreen(),
      ),
      _rootRoute(
        path: '/register',
        builder: (context, state) => const S18DaftarScreen(),
      ),
      _rootRoute(
        path: '/forgot-password',
        builder: (context, state) => const Scaffold(
          backgroundColor: Color(0xFF071930),
          body: S02SheetLupaKataSandi(),
        ),
      ),
      _rootRoute(
        path: '/complete-profile',
        builder: (context, state) => const S03LengkapiProfilScreen(),
      ),

      // StatefulShellRoute for Bottom Navigation Tabs (S04, S13, S14)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RootBackScope(
            router: GoRouter.of(context),
            navigatorKey: rootNavigatorKey,
            child: BottomNavShell(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              _rootRoute(
                path: '/home',
                builder: (context, state) => const S04BerandaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _rootRoute(
                path: '/rooms',
                builder: (context, state) => const S20DaftarRuangScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _rootRoute(
                path: '/history',
                builder: (context, state) => const S13RiwayatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _rootRoute(
                path: '/profile',
                builder: (context, state) => const S14ProfilScreen(),
              ),
            ],
          ),
        ],
      ),

      // Other routes outside BottomNavShell
      _rootRoute(
        path: '/create-room',
        builder: (context, state) => const Scaffold(body: S05SheetBuatRuang()),
      ),
      _rootRoute(
        path: '/join-code',
        builder: (context, state) => const Scaffold(body: S06SheetGabungKode()),
      ),
      _rootRoute(
        path: '/j/:code',
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return Scaffold(body: S06SheetGabungKode(initialCode: code));
        },
      ),
      _rootRoute(
        path: '/lobby/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return SessionAccessGate(
            roomId: roomId,
            child: S07LobiScreen(roomId: roomId),
          );
        },
      ),
      _rootRoute(
        path: '/calibration/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return SessionAccessGate(
            roomId: roomId,
            child: S08KalibrasiScreen(roomId: roomId),
          );
        },
      ),
      _rootRoute(
        path: '/active-session/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return SessionAccessGate(
            roomId: roomId,
            child: S09SesiAktifScreen(roomId: roomId),
          );
        },
      ),
      _rootRoute(
        path: '/alarm-violator/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return SessionAccessGate(
            roomId: roomId,
            child: S10AlarmPelanggarScreen(roomId: roomId),
          );
        },
      ),
      _rootRoute(
        path: '/alarm-peer/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return SessionAccessGate(
            roomId: roomId,
            child: S11AlarmAnggotaLainScreen(
              roomId: roomId,
              violatorName: extra?['violatorName'] ?? 'Anggota',
            ),
          );
        },
      ),
      _rootRoute(
        path: '/session-summary/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final readOnly = state.uri.queryParameters['readOnly'] == 'true';
          return S12RingkasanSesiScreen(roomId: roomId, readOnly: readOnly);
        },
      ),
      _rootRoute(
        path: '/edit-profile',
        builder: (context, state) => const S15EditProfilScreen(),
      ),
      _rootRoute(
        path: '/sensor-settings',
        builder: (context, state) => const S16SensitivitasSensorScreen(),
      ),
      _rootRoute(
        path: '/sensor-sensitivity',
        builder: (context, state) => const S16SensitivitasSensorScreen(),
      ),
      _rootRoute(
        path: '/alarm-settings',
        builder: (context, state) => const S17PengaturanAlarmScreen(),
      ),
      _rootRoute(
        path: '/permission-info',
        builder: (context, state) => const S19SheetIzinPemantauanScreen(),
      ),
      _rootRoute(
        path: '/history-detail/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return S24DetailRiwayatScreen(roomId: roomId);
        },
      ),
      _rootRoute(
        path: '/account-settings',
        builder: (context, state) => const S25PengaturanAkunScreen(),
      ),
      _rootRoute(
        path: '/notifications',
        builder: (context, state) => const S22NotifikasiScreen(),
      ),
      _rootRoute(
        path: '/about-app',
        builder: (context, state) => const S23TentangAplikasiScreen(),
      ),
      _rootRoute(
        path: '/data-inspector',
        builder: (context, state) => const DataInspectorScreen(),
      ),
    ],
  );
});
