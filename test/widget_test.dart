import 'package:flutter_test/flutter_test.dart';
import 'package:focus_room/main.dart';

void main() {
  testWidgets('StudyPact smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FocusRoomApp());
    await tester.pumpAndSettle();

    // Verify that StudyPact branding and Farhan greeting render
    expect(find.text('StudyPact'), findsWidgets);
    expect(find.text('Halo, Farhan!'), findsOneWidget);
  });
}
