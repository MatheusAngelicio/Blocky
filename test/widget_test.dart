import 'package:blocky/app/blocky_app.dart';
import 'package:blocky/ui/game_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Blocky game screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BlockyApp());

    expect(find.byType(GameScreen), findsOneWidget);
  });
}
