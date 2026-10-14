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
import '../../features/profile/presentation/s21_integrasi_kalender_screen.dart';
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final notifier = _AuthRefreshNotifier(authRepo.authStateChanges);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = authRepo.currentFirebaseUser != null;
      final isAuthRoute = state.matchedLocation == '/landing' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isSplash = state.matchedLocation == '/';

      if (isSplash) return null; // Let splash perform initial check

      if (!isLoggedIn && !isAuthRoute) {
        return '/landing';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const S01SplashScreen(),
      ),
      GoRoute(
        path: '/landing',
        builder: (context, state) => const S00LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const S02MasukScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const S18DaftarScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const Scaffold(
          backgroundColor: Color(0xFF071930),
          body: S02SheetLupaKataSandi(),
        ),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const S03LengkapiProfilScreen(),
      ),

      // StatefulShellRoute for Bottom Navigation Tabs (S04, S13, S14)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const S04BerandaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rooms',
                builder: (context, state) => const S20DaftarRuangScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const S13RiwayatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const S14ProfilScreen(),
              ),
            ],
          ),
        ],
      ),

      // Other routes outside BottomNavShell
      GoRoute(
        path: '/create-room',
        builder: (context, state) => const Scaffold(body: S05SheetBuatRuang()),
      ),
      GoRoute(
        path: '/join-code',
        builder: (context, state) => const Scaffold(body: S06SheetGabungKode()),
      ),
      GoRoute(
        path: '/j/:code',
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return Scaffold(body: S06SheetGabungKode(initialCode: code));
        },
      ),
      GoRoute(
        path: '/lobby/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return S07LobiScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/calibration/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return S08KalibrasiScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/active-session/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return S09SesiAktifScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/alarm-violator/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return S10AlarmPelanggarScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/alarm-peer/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return S11AlarmAnggotaLainScreen(
            roomId: roomId,
            violatorName: extra?['violatorName'] ?? 'Anggota',
          );
        },
      ),
      GoRoute(
        path: '/session-summary/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final readOnly = state.uri.queryParameters['readOnly'] == 'true';
          return S12RingkasanSesiScreen(roomId: roomId, readOnly: readOnly);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const S15EditProfilScreen(),
      ),
      GoRoute(
        path: '/sensor-settings',
        builder: (context, state) => const S16SensitivitasSensorScreen(),
      ),
      GoRoute(
        path: '/sensor-sensitivity',
        builder: (context, state) => const S16SensitivitasSensorScreen(),
      ),
      GoRoute(
        path: '/alarm-settings',
        builder: (context, state) => const S17PengaturanAlarmScreen(),
      ),
      GoRoute(
        path: '/permission-info',
        builder: (context, state) => const S19SheetIzinPemantauanScreen(),
      ),
      GoRoute(
        path: '/history-detail/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return S24DetailRiwayatScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/account-settings',
        builder: (context, state) => const S25PengaturanAkunScreen(),
      ),
      GoRoute(
        path: '/calendar-integration',
        builder: (context, state) => const S21IntegrasiKalenderScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const S22NotifikasiScreen(),
      ),
      GoRoute(
        path: '/about-app',
        builder: (context, state) => const S23TentangAplikasiScreen(),
      ),
      GoRoute(
        path: '/data-inspector',
        builder: (context, state) => const DataInspectorScreen(),
      ),
    ],
  );
});
