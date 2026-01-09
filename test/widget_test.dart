import 'package:flutter_test/flutter_test.dart';
import 'package:blocked_game/main.dart';
import 'package:blocked_game/screens/game_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BlockedApp());

    // Verify that GameScreen is present
    expect(find.byType(GameScreen), findsOneWidget);

    // Verify Level text is present (initially Level 1)
    // Note: It might take a moment to load if async, but initial state has default values?
    // GameController loads async, but initial text might be "Level 0" or loading?
    // Let's just check for the Title or basic UI elements
    await tester.pumpAndSettle(); // Wait for all animations and futures

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });
}
