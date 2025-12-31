import 'package:flutter_test/flutter_test.dart';
import 'package:unwaver/main.dart'; // Ensure this matches your project name

void main() {
  testWidgets('Hello', (WidgetTester tester) async {
    // 1. Load the UnwaverApp widget
    await tester.pumpWidget(const UnwaverApp());

    // 2. Check if 'Unwaver' appears in the AppBar
    expect(find.text('Unwaver'), findsOneWidget);

    // 3. Check if 'Hello World' appears on the screen
    expect(find.text('Hello World'), findsOneWidget);
  });
}