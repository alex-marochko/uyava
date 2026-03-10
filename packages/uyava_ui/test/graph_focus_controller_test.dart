import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  group('GraphFocusController', () {
    test('manages node and edge focus sets', () {
      final controller = GraphFocusController();
      expect(controller.state.isEmpty, isTrue);

      int notifications = 0;
      controller.addListener(() => notifications += 1);

      expect(controller.addNode('nodeA'), isTrue);
      expect(controller.state.nodeIds.contains('nodeA'), isTrue);
      expect(notifications, 1);

      // Duplicate additions should not trigger notifications.
      expect(controller.addNode('nodeA'), isFalse);
      expect(notifications, 1);

      expect(controller.toggleEdge('edge1'), isTrue);
      expect(controller.state.edgeIds.contains('edge1'), isTrue);
      expect(notifications, 2);

      expect(controller.toggleEdge('edge1'), isTrue);
      expect(controller.state.edgeIds.contains('edge1'), isFalse);
      expect(notifications, 3);

      controller.clear();
      expect(controller.state.isEmpty, isTrue);
      expect(notifications, 4);
    });
  });
}
