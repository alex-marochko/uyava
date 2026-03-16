import 'dart:async';

import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('GraphController.updateSubtreeLifecycle', () {
    late GraphController controller;
    late StreamSubscription<GraphFilterResult> filterSubscription;
    final List<GraphFilterResult> filterEmissions = <GraphFilterResult>[];

    setUp(() {
      controller = GraphController();
      filterSubscription = controller.filtersStream.listen(filterEmissions.add);
      controller.replaceGraph({
        'nodes': [
          {'id': 'root', 'label': 'Root'},
          {
            'id': 'auth',
            'label': 'Auth',
            'parentId': 'root',
            'lifecycle': 'initialized',
          },
          {'id': 'login', 'parentId': 'auth'},
          {'id': 'billing', 'parentId': 'root'},
          {'id': 'orphan'},
          {'id': 'dangling', 'parentId': 'ghost'},
        ],
        'edges': const <Map<String, Object?>>[],
      }, const Size2D(600, 400));
      filterEmissions.clear();
    });

    tearDown(() async {
      await filterSubscription.cancel();
      controller.dispose();
    });

    test('includeRoot true updates entire descendant tree', () {
      controller.updateSubtreeLifecycle('auth', NodeLifecycle.disposed);

      expect(controller.lifecycleForNode('auth'), NodeLifecycle.disposed);
      expect(controller.lifecycleForNode('login'), NodeLifecycle.disposed);
      expect(controller.lifecycleForNode('billing'), NodeLifecycle.unknown);
      expect(controller.lifecycleForNode('root'), NodeLifecycle.unknown);
      expect(controller.lifecycleForNode('orphan'), NodeLifecycle.unknown);
      expect(controller.lifecycleForNode('dangling'), NodeLifecycle.unknown);
    });

    test('includeRoot false leaves root lifecycle untouched', () {
      controller.updateSubtreeLifecycle(
        'auth',
        NodeLifecycle.disposed,
        includeRoot: false,
      );

      expect(controller.lifecycleForNode('auth'), NodeLifecycle.initialized);
      expect(controller.lifecycleForNode('login'), NodeLifecycle.disposed);
      expect(controller.lifecycleForNode('billing'), NodeLifecycle.unknown);
      expect(controller.lifecycleForNode('root'), NodeLifecycle.unknown);
    });

    test('unknown root id is a no-op without new filter emissions', () async {
      final int emissionsBefore = filterEmissions.length;
      controller.updateSubtreeLifecycle('missing', NodeLifecycle.disposed);
      await Future<void>.delayed(Duration.zero);

      expect(filterEmissions.length, emissionsBefore);
    });
  });
}
