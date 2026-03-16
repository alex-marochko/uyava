import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  group('LayoutViewportSizer', () {
    final RenderConfig config = const RenderConfig();

    test('falls back to default viewport when size is invalid', () {
      final sizer = LayoutViewportSizer(renderConfig: config);
      final result = sizer.resolve(viewportSize: Size.zero, nodeCount: 0);
      expect(result.viewportSize.width, 1024);
      expect(result.viewportSize.height, 768);
      expect(result.layoutSize, result.viewportSize);
    });

    test('preserves aspect ratio while expanding for dense graphs', () {
      final sizer = LayoutViewportSizer(renderConfig: config);
      const Size viewport = Size(640, 360);
      final resultSparse = sizer.resolve(viewportSize: viewport, nodeCount: 4);
      final resultDense = sizer.resolve(viewportSize: viewport, nodeCount: 400);

      expect(resultSparse.layoutSize.width, viewport.width);
      expect(
        resultDense.layoutSize.width,
        greaterThan(resultSparse.layoutSize.width),
      );
      expect(
        resultDense.layoutSize.height,
        greaterThan(resultSparse.layoutSize.height),
      );

      final double expectedAspect = viewport.width / viewport.height;
      final double actualAspect =
          resultDense.layoutSize.width / resultDense.layoutSize.height;
      expect(actualAspect, closeTo(expectedAspect, 1e-6));
    });

    test('caps layout size at configured maximum extent', () {
      final sizer = LayoutViewportSizer(
        renderConfig: config,
        maxVirtualExtent: 2000,
      );
      final result = sizer.resolve(
        viewportSize: const Size(800, 600),
        nodeCount: 5000,
      );
      expect(result.layoutSize.width, lessThanOrEqualTo(2000));
      expect(result.layoutSize.height, lessThanOrEqualTo(2000));
    });

    test('controller reuses recorded viewport size and payload node count', () {
      final controller = LayoutSizingController(renderConfig: config);
      controller.recordViewportSize(const Size(500, 300));
      final payload = <String, dynamic>{
        'nodes': List.generate(25, (index) => {'id': '$index'}),
      };
      final result = controller.resolveForPayload(
        payload: payload,
        viewportHint: Size.zero,
        fallbackNodeCount: 0,
      );
      expect(result.viewportSize, const Size(500, 300));
      expect(result.layoutSize.width, greaterThan(500));
      expect(result.layoutSize.height, greaterThan(300));
    });
  });
}
