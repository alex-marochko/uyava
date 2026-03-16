import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_devtools_extension/main.dart';
import 'package:uyava_ui/uyava_ui.dart';

void registerGraphViewTestHarness() {
  setUp(() {
    removeGlobal(ServiceManager);
    setGraphViewAnimationsEnabled(false);
  });

  tearDown(() {
    removeGlobal(ServiceManager);
    setGraphViewAnimationsEnabled(true);
  });
}

Finder panelMenuItemFinder(String label) {
  return find.byWidgetPredicate((widget) {
    if (widget is! CheckedPopupMenuItem) return false;
    final Widget? child = widget.child;
    return child is Text && child.data == label;
  });
}

Map<String, dynamic> basicGraphPayload() => <String, dynamic>{
  'nodes': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'serviceA',
      'type': 'service',
      'label': 'Service A',
    },
    <String, dynamic>{
      'id': 'serviceB',
      'type': 'service',
      'label': 'Service B',
    },
  ],
  'edges': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'serviceA-serviceB',
      'source': 'serviceA',
      'target': 'serviceB',
    },
  ],
};

Map<String, dynamic> taggedGraphPayload() => <String, dynamic>{
  'nodes': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'serviceA',
      'type': 'service',
      'label': 'Service A',
      'tags': <String>['Core', 'Backend'],
    },
    <String, dynamic>{
      'id': 'serviceB',
      'type': 'service',
      'label': 'Service B',
      'tags': <String>['Backend'],
    },
    <String, dynamic>{
      'id': 'serviceC',
      'type': 'service',
      'label': 'Service C',
      'tags': <String>['UI'],
    },
  ],
  'edges': const <Map<String, dynamic>>[],
};

Map<String, dynamic> hierarchyGraphPayload() => <String, dynamic>{
  'nodes': <Map<String, dynamic>>[
    <String, dynamic>{'id': 'root', 'type': 'group', 'label': 'Root'},
    <String, dynamic>{
      'id': 'childA',
      'type': 'service',
      'label': 'Child A',
      'parentId': 'root',
    },
    <String, dynamic>{
      'id': 'childB',
      'type': 'service',
      'label': 'Child B',
      'parentId': 'root',
    },
    <String, dynamic>{
      'id': 'grandChild',
      'type': 'service',
      'label': 'Grand Child',
      'parentId': 'childA',
    },
  ],
  'edges': const <Map<String, dynamic>>[],
};

class TestViewportStorage implements ViewportPersistenceAdapter {
  GraphViewportState? lastSavedState;

  @override
  Future<GraphViewportState?> load() async => lastSavedState;

  @override
  Future<void> save(GraphViewportState state) async {
    lastSavedState = state;
  }

  @override
  Future<void> clear() async {
    lastSavedState = null;
  }
}

class InMemoryPanelLayoutStorage extends UyavaPanelLayoutStorage {
  InMemoryPanelLayoutStorage() : super(maxAge: const Duration(days: 30));

  String? _raw;
  UyavaPanelLayoutState? lastSavedState;

  @override
  Future<String?> readRaw() async => _raw;

  @override
  Future<void> writeRaw(String data) async {
    _raw = data;
  }

  @override
  Future<void> deleteRaw() async {
    _raw = null;
  }

  @override
  Future<void> saveState(UyavaPanelLayoutState state) async {
    lastSavedState = state;
    await super.saveState(state);
  }
}

Future<dynamic> pumpGraphViewPage(
  WidgetTester tester, {
  Map<String, dynamic>? graphPayload,
  ViewportPersistenceAdapter? viewportStorage,
  UyavaPanelLayoutStorage? panelLayoutStorage,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GraphViewPage(
        viewportStorage: viewportStorage,
        panelLayoutStorage: panelLayoutStorage,
      ),
    ),
  );
  await tester.pump();

  final dynamic graphState = tester.state(find.byType(GraphViewPage));
  if (graphPayload != null) {
    graphState.replaceGraphForTesting(graphPayload);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }
  return graphState;
}
