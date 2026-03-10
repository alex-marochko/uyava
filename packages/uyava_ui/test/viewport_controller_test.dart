import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphViewportController', () {
    late TransformationController transform;
    late GraphViewportController controller;
    const RenderConfig renderConfig = RenderConfig();
    const Size viewportSize = Size(400, 300);

    setUp(() {
      transform = TransformationController();
      controller = GraphViewportController(
        renderConfig: renderConfig,
        transformationController: transform,
      );
    });

    tearDown(() {
      controller.dispose();
      transform.dispose();
    });

    test('GraphViewportState round-trips through JSON', () {
      const GraphViewportState state = GraphViewportState(
        scale: 1.5,
        translation: Offset(12, -24),
      );
      final Map<String, Object?> json = state.toJson();
      final GraphViewportState? restored = GraphViewportState.fromJson(json);
      expect(restored, isNotNull);
      expect(restored, equals(state));
    });

    test('computeDisplayNodeBounds inflates single node', () {
      final UyavaNode node = UyavaNode.fromPayload(
        const UyavaGraphNodePayload(id: 'a', label: 'Node A'),
      );
      final DisplayNode displayNode = DisplayNode(
        node: node,
        position: Offset.zero,
      );

      final Rect? rect = computeDisplayNodeBounds(<DisplayNode>[
        displayNode,
      ], renderConfig);
      expect(rect, isNotNull);
      // Padding applied on both sides.
      final double expectedWidth =
          renderConfig.childNodeRadius * 2 +
          renderConfig.viewportFitPadding * 2;
      expect((rect!.width - expectedWidth).abs() < 0.001, isTrue);
      expect(rect.contains(Offset.zero), isTrue);
    });

    test('fitToNodes centers content in viewport', () {
      final UyavaNode left = UyavaNode.fromPayload(
        const UyavaGraphNodePayload(id: 'l', label: 'Left'),
      );
      final UyavaNode right = UyavaNode.fromPayload(
        const UyavaGraphNodePayload(id: 'r', label: 'Right'),
      );
      final DisplayNode leftDisplay = DisplayNode(
        node: left,
        position: const Offset(-120, 40),
      );
      final DisplayNode rightDisplay = DisplayNode(
        node: right,
        position: const Offset(140, -20),
      );

      final bool applied = controller.fitToNodes(<DisplayNode>[
        leftDisplay,
        rightDisplay,
      ], viewportSize);
      expect(applied, isTrue);

      final Offset viewportCenter = Offset(
        viewportSize.width / 2,
        viewportSize.height / 2,
      );
      final Offset contentCenter = computeDisplayNodeBounds(<DisplayNode>[
        leftDisplay,
        rightDisplay,
      ], renderConfig)!.center;
      final Offset transformed = MatrixUtils.transformPoint(
        transform.value,
        contentCenter,
      );
      expect((transformed.dx - viewportCenter.dx).abs() < 0.1, isTrue);
      expect((transformed.dy - viewportCenter.dy).abs() < 0.1, isTrue);
    });

    test('zoomBy clamps scale within bounds', () {
      controller.reset(viewportSize);
      final double originalScale = controller.state.scale;
      controller.zoomBy(renderConfig.viewportZoomStep, viewportSize);
      expect(
        controller.state.scale,
        closeTo(originalScale * renderConfig.viewportZoomStep, 0.001),
      );

      // Zoom out repeatedly until hitting the min bound.
      for (int i = 0; i < 50; i++) {
        controller.zoomBy(0.5, viewportSize);
      }
      expect(controller.state.scale >= renderConfig.minViewportScale, isTrue);
      expect(controller.state.scale <= renderConfig.maxViewportScale, isTrue);
    });

    test('centerOnPoint recenters viewport', () {
      controller.reset(viewportSize);
      final Offset target = const Offset(300, -150);
      controller.centerOnPoint(target, viewportSize);
      final Offset viewportCenter = Offset(
        viewportSize.width / 2,
        viewportSize.height / 2,
      );
      final Offset transformed = MatrixUtils.transformPoint(
        transform.value,
        target,
      );
      expect((transformed.dx - viewportCenter.dx).abs() < 0.1, isTrue);
      expect((transformed.dy - viewportCenter.dy).abs() < 0.1, isTrue);
    });
  });
}
