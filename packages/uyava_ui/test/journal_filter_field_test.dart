import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uyava_ui/src/journal/journal_filter_field.dart';

void main() {
  testWidgets('GraphJournalFilterField clears input', (tester) async {
    final controller = TextEditingController();

    Future<void> pumpField() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GraphJournalFilterField(controller: controller)),
        ),
      );
    }

    await pumpField();

    expect(find.byIcon(Icons.close), findsNothing);

    controller.text = 'nodeA';
    await pumpField();

    final Finder clearButton = find.byIcon(Icons.close);
    expect(clearButton, findsOneWidget);

    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(controller.text, isEmpty);
  });
}
