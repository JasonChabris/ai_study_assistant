import 'package:flutter_test/flutter_test.dart';
import 'package:ai_study_assistant/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AIStudyApp());
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.byType(AIStudyApp), findsOneWidget);
  });
}
