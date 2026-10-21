import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_room/features/profile/presentation/s23_tentang_aplikasi_screen.dart';
import 'package:focus_room/features/profile/presentation/s25_pengaturan_akun_screen.dart';
import 'package:focus_room/features/history/presentation/s24_detail_riwayat_screen.dart';
import 'package:focus_room/features/profile/presentation/s22_notifikasi_screen.dart';
import 'package:focus_room/features/auth/presentation/auth_controller.dart';
import 'package:focus_room/features/room/presentation/room_controller.dart';
import 'package:focus_room/features/profile/presentation/s14_profil_screen.dart';
import 'package:focus_room/features/room/presentation/s20_daftar_ruang_screen.dart';
import 'package:focus_room/features/stats/presentation/stats_controller.dart';
import 'package:focus_room/features/stats/domain/stats_model.dart';
import 'package:focus_room/features/session/presentation/session_controller.dart';

void main() {
  testWidgets('S23TentangAplikasiScreen renders direct inline texts and no redirect arrows', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: S23TentangAplikasiScreen(),
        ),
      ),
    );

    expect(find.text('Tentang Aplikasi'), findsOneWidget);
    expect(find.text('KerKom'), findsOneWidget);
    expect(find.text('Fitur Utama'), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    expect(find.text('Syarat & Ketentuan'), findsOneWidget);
    expect(find.text('Lisensi Open Source'), findsOneWidget);
  });

  testWidgets('S25PengaturanAkunScreen renders sensor, alarm, logout, and delete account', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: S25PengaturanAkunScreen(),
        ),
      ),
    );

    expect(find.text('Pengaturan Akun'), findsOneWidget);
    expect(find.text('Sensitivitas Sensor'), findsOneWidget);
    expect(find.text('Pengaturan Alarm'), findsOneWidget);
    expect(find.text('Keluar Akun'), findsOneWidget);
    expect(find.text('Hapus Akun'), findsOneWidget);
  });

  testWidgets('S24DetailRiwayatScreen renders session details and delete button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSessionsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: S24DetailRiwayatScreen(roomId: 'test-session-123'),
        ),
      ),
    );

    expect(find.text('Detail Riwayat'), findsOneWidget);
    expect(find.text('Anggota'), findsOneWidget);
    expect(find.text('Kode Ruang'), findsOneWidget);
    expect(find.text('Link Meeting'), findsOneWidget);
    expect(find.text('Hapus dari Riwayat'), findsOneWidget);
  });

  testWidgets('New users have no fabricated notifications', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRoomsStreamProvider.overrideWith((ref) => Stream.value([])),
          allRoomsProvider.overrideWith((ref) => Stream.value([])),
          userSessionsProvider.overrideWith((ref) => Stream.value([])),
          currentUserProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(
          home: S22NotifikasiScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
    expect(find.text('Hari ini'), findsNothing);
    expect(find.text('Kemarin'), findsNothing);
    expect(find.text('Tandai Baca'), findsOneWidget);
  });

  testWidgets('S14ProfilScreen renders top-level menu rows without grouping', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(null)),
          userStatsStreamProvider.overrideWith((ref) => Stream.value(const UserStats())),
        ],
        child: const MaterialApp(
          home: S14ProfilScreen(),
        ),
      ),
    );

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Sensitivitas Sensor'), findsOneWidget);
    expect(find.text('Pengaturan Alarm'), findsOneWidget);
    expect(find.text('Integrasi Kalender'), findsNothing);
    expect(find.text('Tentang Aplikasi'), findsOneWidget);
    expect(find.text('Keluar Akun'), findsOneWidget);
    expect(find.text('Hapus Akun'), findsOneWidget);
  });


  testWidgets('S20DaftarRuangScreen renders filter chips and tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRoomsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: S20DaftarRuangScreen(),
        ),
      ),
    );

    expect(find.text('Ruang'), findsOneWidget);
    expect(find.text('Kalender'), findsOneWidget);
    expect(find.text('Daftar Ruang'), findsOneWidget);

    // Switch to Daftar Ruang tab
    await tester.tap(find.text('Daftar Ruang'));
    await tester.pumpAndSettle();

    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('3 hari ke depan'), findsOneWidget);
    expect(find.text('7 hari ke depan'), findsOneWidget);
    expect(find.text('Minggu ini'), findsOneWidget);
    expect(find.text('Bulan ini'), findsOneWidget);
    expect(find.text('Pilih tanggal'), findsOneWidget);
    expect(find.text('Belum ada ruangan yang dibuat'), findsOneWidget);
  });
}
