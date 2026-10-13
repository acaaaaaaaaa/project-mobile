import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_room/features/auth/presentation/s01_splash_screen.dart';

void main() {
  testWidgets('Kerkom S01 Splash branding smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: S01SplashScreen(autoNavigate: false),
      ),
    );

    // Verify S01 Splash renders Kerkom branding
    expect(find.text('kerkom'), findsOneWidget);
    expect(find.text('Kerja kelompok tanpa distraksi'), findsOneWidget);
  });
}
