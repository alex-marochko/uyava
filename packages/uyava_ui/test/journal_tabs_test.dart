import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_ui/src/journal/journal_tabs.dart';

void main() {
  testWidgets('GraphJournalTabHost surfaces active tab changes', (
    tester,
  ) async {
    final displayController = GraphJournalDisplayController(
      initialTab: GraphJournalTab.diagnostics,
    );
    GraphJournalTab? latestTab;

    await tester.pumpWidget(
      MaterialApp(
        home: GraphJournalTabHost(
          initialTab: GraphJournalTab.events,
          displayController: displayController,
          onTabChanged: (tab) => latestTab = tab,
          builder: (context, tabController, activeTab) {
            return Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  controller: tabController,
                  tabs: const [
                    Tab(text: 'Events'),
                    Tab(text: 'Diagnostics'),
                  ],
                ),
              ),
              body: Center(child: Text('Active: ${activeTab.name}')),
            );
          },
        ),
      ),
    );

    expect(find.text('Active: diagnostics'), findsOneWidget);

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(latestTab, GraphJournalTab.events);
    expect(find.text('Active: events'), findsOneWidget);

    displayController.setActiveTab(GraphJournalTab.diagnostics);
    await tester.pumpAndSettle();

    expect(latestTab, GraphJournalTab.diagnostics);
    expect(find.text('Active: diagnostics'), findsOneWidget);
  });
}
