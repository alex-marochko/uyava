import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphPainter', () {
    test('dims disposed nodes compared to initialized ones', () async {
      final sampler = await _renderGraphPainter(
        nodes: <DisplayNode>[
          _buildDisplayNode(
            id: 'init',
            lifecycle: NodeLifecycle.initialized,
            position: const Offset(40, 40),
          ),
          _buildDisplayNode(
            id: 'disposed',
            lifecycle: NodeLifecycle.disposed,
            position: const Offset(120, 40),
          ),
        ],
      );

      final Color initializedPixel = sampler.colorAt(const Offset(40, 40));
      final Color disposedPixel = sampler.colorAt(const Offset(120, 40));

      expect(initializedPixel.a, greaterThan(disposedPixel.a));
    });

    test('draws focus glow with configured focus color', () async {
      final sampler = await _renderGraphPainter(
        nodes: <DisplayNode>[
          _buildDisplayNode(
            id: 'focus',
            lifecycle: NodeLifecycle.initialized,
            position: const Offset(80, 60),
          ),
        ],
        focusedIds: const <String>{'focus'},
      );

      expect(sampler.containsApproxColor(const Color(0xFF64B5F6)), isTrue);
    });
  });
}

DisplayNode _buildDisplayNode({
  required String id,
  required NodeLifecycle lifecycle,
  required Offset position,
}) {
  final UyavaNode node = UyavaNode(
    rawData: <String, dynamic>{
      'id': id,
      'type': 'service',
      'label': id,
      'lifecycle': lifecycle.name,
    },
  );
  return DisplayNode(node: node, position: position);
}

Future<_GraphPaintSampler> _renderGraphPainter({
  required List<DisplayNode> nodes,
  Set<String> focusedIds = const <String>{},
}) async {
  final GraphPainter painter = GraphPainter(
    displayNodes: nodes,
    edges: const <UyavaEdge>[],
    events: const <UyavaEvent>[],
    nodeEvents: const <UyavaNodeEvent>[],
    collapsedParents: const <String>{},
    collapseProgress: const <String, double>{},
    directChildCounts: const <String, int>{},
    isParentId: (_) => false,
    parentById: const <String, String?>{},
    edgePolicy: EdgeAggregationPolicy(
      collapsedParents: const <String>{},
      collapseProgress: const <String, double>{},
      parentById: const <String, String?>{},
    ),
    cloudPolicy: CloudVisibilityPolicy(
      collapsedParents: const <String>{},
      collapseProgress: const <String, double>{},
    ),
    renderConfig: const RenderConfig(),
    edgeGlobalOpacity: 1.0,
    cloudGlobalOpacity: 1.0,
    eventQueueLabels: const <String, int>{},
    eventQueueLabelAlphas: const <String, double>{},
    eventQueueLabelSeverities: const <String, UyavaSeverity?>{},
    nodeEventBadgeLabels: const <String, int>{},
    nodeEventBadgeAlphas: const <String, double>{},
    nodeEventBadgeSeverities: const <String, UyavaSeverity?>{},
    highlightedNodeIds: const <String>{},
    highlightedEdges: const <GraphHighlightEdge>{},
    focusedNodeIds: focusedIds,
    focusedEdgeIds: const <String>{},
    focusColor: const Color(0xFF64B5F6),
  );

  const Size paintSize = Size(160, 120);
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  painter.paint(canvas, paintSize);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(
    paintSize.width.toInt(),
    paintSize.height.toInt(),
  );
  final ByteData data = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!;
  return _GraphPaintSampler(
    data: data,
    width: image.width,
    height: image.height,
  );
}

class _GraphPaintSampler {
  _GraphPaintSampler({
    required this.data,
    required this.width,
    required this.height,
  });

  final ByteData data;
  final int width;
  final int height;

  Color colorAt(Offset position) {
    final int x = position.dx.round().clamp(0, width - 1);
    final int y = position.dy.round().clamp(0, height - 1);
    final int offset = ((y * width) + x) * 4;
    final int r = data.getUint8(offset);
    final int g = data.getUint8(offset + 1);
    final int b = data.getUint8(offset + 2);
    final int a = data.getUint8(offset + 3);
    return Color.fromARGB(a, r, g, b);
  }

  bool containsApproxColor(Color expected, {int tolerance = 12}) {
    final int length = data.lengthInBytes;
    for (int offset = 0; offset < length; offset += 4) {
      final int r = data.getUint8(offset);
      final int g = data.getUint8(offset + 1);
      final int b = data.getUint8(offset + 2);
      final int a = data.getUint8(offset + 3);
      if (_withinTolerance(r, expected.r, tolerance) &&
          _withinTolerance(g, expected.g, tolerance) &&
          _withinTolerance(b, expected.b, tolerance) &&
          _withinTolerance(a, expected.a, tolerance * 3)) {
        return true;
      }
    }
    return false;
  }

  bool _withinTolerance(int actual, double channel, int tolerance) {
    final int target = (channel * 255.0).round().clamp(0, 255);
    return (actual - target).abs() <= tolerance;
  }
}
