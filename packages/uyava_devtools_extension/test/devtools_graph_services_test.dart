import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_devtools_extension/graph_view_page.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevToolsGraphPersistence', () {
    late RecordingViewportStorage viewportStorage;
    late RecordingPanelLayoutStorage panelStorage;
    final List<String> loggedMessages = <String>[];

    DevToolsGraphPersistence createPersistence() {
      return DevToolsGraphPersistence(
        viewportStorage: viewportStorage,
        panelLayoutStorage: panelStorage,
        viewportSaveDebounce: const Duration(milliseconds: 10),
        logSink: (message, error, stackTrace) {
          loggedMessages.add(message);
        },
      );
    }

    setUp(() {
      viewportStorage = RecordingViewportStorage();
      panelStorage = RecordingPanelLayoutStorage();
      loggedMessages.clear();
    });

    test('scheduleViewportSave debounces and persists last state', () {
      fakeAsync((async) {
        final persistence = createPersistence();
        final GraphViewportState first = GraphViewportState(
          scale: 1,
          translation: const Offset(1, 2),
        );
        final GraphViewportState second = GraphViewportState(
          scale: 2,
          translation: const Offset(3, 4),
        );

        persistence.scheduleViewportSave(first);
        persistence.scheduleViewportSave(second);

        expect(viewportStorage.savedStates, isEmpty);
        async.elapse(const Duration(milliseconds: 10));

        expect(viewportStorage.savedStates, [second]);
      });
    });

    test(
      'restoreViewportState logs error and returns null on failure',
      () async {
        viewportStorage.loadError = StateError('broken');
        final persistence = createPersistence();

        final GraphViewportState? restored = await persistence
            .restoreViewportState();

        expect(restored, isNull);
        expect(loggedMessages, contains('Failed to restore viewport state'));
      },
    );

    test(
      'persistPanelLayout saves and restorePanelLayout decodes snapshot',
      () async {
        final persistence = createPersistence();
        final UyavaPanelLayoutState state = UyavaPanelLayoutState(
          configurationId: 'cfg',
          entries: <UyavaPanelLayoutEntry>[
            UyavaPanelLayoutEntry(
              id: UyavaPanelId('graph'),
              visibility: UyavaPanelVisibility.visible,
            ),
          ],
        );

        persistence.persistPanelLayout(state);
        await Future<void>.delayed(Duration.zero);

        final UyavaPanelLayoutState? restored = await persistence
            .restorePanelLayout();

        expect(restored?.configurationId, state.configurationId);
        expect(restored?.entries.first.id, state.entries.first.id);
        expect(panelStorage.writes, isNotEmpty);
      },
    );

    test('persistPanelLayout logs when storage throws', () async {
      panelStorage.throwOnWrite = true;
      final persistence = createPersistence();
      final UyavaPanelLayoutState state = UyavaPanelLayoutState(
        configurationId: 'cfg-2',
        entries: const <UyavaPanelLayoutEntry>[],
      );

      persistence.persistPanelLayout(state);
      await Future<void>.delayed(Duration.zero);

      expect(loggedMessages, contains('Failed to persist panel layout'));
    });
  });

  group('DevToolsGraphHoverController', () {
    late DevToolsGraphHoverController controller;
    late TransformationController transformationController;
    int changeCount = 0;

    DevToolsGraphHoverController createController({
      Duration tooltipDelay = const Duration(milliseconds: 5),
    }) {
      transformationController = TransformationController();
      changeCount = 0;
      return DevToolsGraphHoverController(
        transformationController: transformationController,
        renderConfig: const RenderConfig(),
        onChanged: () => changeCount++,
        tooltipDelay: tooltipDelay,
      );
    }

    test('updates highlight and shows tooltip after delay', () {
      fakeAsync((async) {
        controller = createController();
        final DisplayNode node = _displayNode(
          id: 'node-a',
          position: const Offset(12, 16),
        );

        controller.updateFromViewportLocal(
          localPosition: const Offset(12, 16),
          viewportSize: const Size(200, 120),
          displayNodes: <DisplayNode>[node],
          childrenByParent: const <String, List<UyavaNode>>{},
          edges: const <UyavaEdge>[],
        );

        expect(controller.highlight?.target.node?.id, 'node-a');
        expect(controller.tooltip, isNull);
        expect(changeCount, 1);

        async.elapse(const Duration(milliseconds: 5));

        expect(controller.tooltip?.target.node?.id, 'node-a');
        expect(changeCount, 2);
        controller.dispose();
      });
    });

    test('clears hover state when pointer exits viewport slack', () {
      controller = createController(tooltipDelay: Duration.zero);
      final DisplayNode node = _displayNode(
        id: 'node-b',
        position: const Offset(4, 4),
      );

      controller.updateFromViewportLocal(
        localPosition: const Offset(4, 4),
        viewportSize: const Size(100, 100),
        displayNodes: <DisplayNode>[node],
        childrenByParent: const <String, List<UyavaNode>>{},
        edges: const <UyavaEdge>[],
      );
      expect(controller.highlight, isNotNull);

      controller.updateFromViewportLocal(
        localPosition: const Offset(-50, -50),
        viewportSize: const Size(100, 100),
        displayNodes: <DisplayNode>[node],
        childrenByParent: const <String, List<UyavaNode>>{},
        edges: const <UyavaEdge>[],
      );

      expect(controller.highlight, isNull);
      expect(controller.tooltip, isNull);
      expect(changeCount, 2);
      controller.dispose();
    });

    test('clear returns true when hover state existed', () {
      controller = createController();
      final DisplayNode node = _displayNode(
        id: 'node-c',
        position: const Offset(8, 8),
      );

      controller.updateFromViewportLocal(
        localPosition: const Offset(8, 8),
        viewportSize: const Size(80, 80),
        displayNodes: <DisplayNode>[node],
        childrenByParent: const <String, List<UyavaNode>>{},
        edges: const <UyavaEdge>[],
      );

      final bool cleared = controller.clear();

      expect(cleared, isTrue);
      expect(controller.highlight, isNull);
      expect(controller.tooltip, isNull);
      expect(changeCount, 2);
      controller.dispose();
    });
  });
}

DisplayNode _displayNode({required String id, required Offset position}) {
  return DisplayNode(
    node: UyavaNode.fromPayload(UyavaGraphNodePayload(id: id, label: id)),
    position: position,
  );
}

class RecordingViewportStorage implements ViewportPersistenceAdapter {
  final List<GraphViewportState> savedStates = <GraphViewportState>[];
  GraphViewportState? loadResult;
  Object? loadError;
  Object? saveError;

  @override
  Future<void> clear() async {}

  @override
  Future<GraphViewportState?> load() async {
    if (loadError != null) throw loadError!;
    return loadResult;
  }

  @override
  Future<void> save(GraphViewportState state) async {
    if (saveError != null) throw saveError!;
    savedStates.add(state);
  }
}

class RecordingPanelLayoutStorage extends UyavaPanelLayoutStorage {
  RecordingPanelLayoutStorage()
    : super(maxAge: const Duration(days: 30), now: () => DateTime(2025, 1, 1));

  final List<String> writes = <String>[];
  bool throwOnWrite = false;
  bool throwOnRead = false;
  String? storedSnapshot;

  @override
  Future<void> deleteRaw() async {
    storedSnapshot = null;
  }

  @override
  Future<String?> readRaw() async {
    if (throwOnRead) throw StateError('read error');
    return storedSnapshot ?? (writes.isEmpty ? null : writes.last);
  }

  @override
  Future<void> writeRaw(String data) async {
    if (throwOnWrite) throw StateError('write error');
    writes.add(data);
    storedSnapshot = data;
  }
}
