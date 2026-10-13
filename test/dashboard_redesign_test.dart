import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_room/features/home/presentation/s04_beranda_screen.dart';
import 'package:focus_room/features/room/presentation/s05_sheet_buat_ruang.dart';
import 'package:focus_room/features/room/presentation/s06_sheet_gabung_kode.dart';

void main() {
  testWidgets('Redesigned S04BerandaScreen elements smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: S04BerandaScreen(),
        ),
      ),
    );

    // Header & KerKom Brand
    expect(find.text('KerKom'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // Profile & Greeting
    expect(find.text('Siap kerja kelompok hari ini?'), findsOneWidget);

    // Performa Card
    expect(find.text('Performa'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);

    // Main Actions
    expect(find.text('Buat Ruang'), findsOneWidget);
    expect(find.text('Gabung'), findsOneWidget);
    expect(find.text('dengan Kode'), findsOneWidget);

    // Jadwal Terdekat
    expect(find.text('Jadwal Terdekat'), findsOneWidget);
    expect(find.text('Lihat Semua'), findsOneWidget);
  });

  testWidgets('S05SheetBuatRuang elements smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: S05SheetBuatRuang(),
          ),
        ),
      ),
    );

    expect(find.text('Buat Ruang Kerja'), findsOneWidget);
    expect(find.text('Judul kegiatan'), findsOneWidget);
    expect(find.text('Tanggal'), findsOneWidget);
    expect(find.text('Waktu'), findsOneWidget);
    expect(find.text('Ruang akan dibuat dengan'), findsOneWidget);
    expect(find.text('Kode ruang'), findsOneWidget);
    expect(find.text('Link meeting (KerKom)'), findsOneWidget);
    expect(find.text('Buat Ruang'), findsOneWidget);
  });

  testWidgets('S06SheetGabungKode elements smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: S06SheetGabungKode(),
          ),
        ),
      ),
    );

    expect(find.text('Gabung ke Ruang'), findsNWidgets(2));
    expect(find.text('Masukkan kode ruang'), findsOneWidget);
    expect(find.text('atau'), findsOneWidget);
    expect(find.text('Gabung lewat Link'), findsOneWidget);
  });
}
