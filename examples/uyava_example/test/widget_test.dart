import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_example/main.dart';

void main() {
  testWidgets('ExampleApp UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // App bar title
    expect(find.text('Food Delivery App Simulation'), findsOneWidget);

    // Feature toggles present (anchor via title text)
    expect(find.text('All Features'), findsOneWidget);
    expect(find.text('Authentication'), findsOneWidget);

    final featuresList = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Order & Checkout'),
      200,
      scrollable: featuresList,
    );
    expect(find.text('Order & Checkout'), findsOneWidget);

    // Slider and label
    expect(find.byType(Slider), findsOneWidget);
    expect(find.textContaining('Events per second:'), findsOneWidget);

    // Control buttons
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
  });
}
