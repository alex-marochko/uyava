import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final bool passed =
        result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

DisplayNode _displayNode({
  required String id,
  required Offset position,
  String type = 'service',
  String? parentId,
  NodeLifecycle lifecycle = NodeLifecycle.initialized,
}) {
  return DisplayNode(
    node: UyavaNode(
      rawData: <String, Object?>{
        'id': id,
        'type': type,
        'label': id,
        'lifecycle': lifecycle.name,
        if (parentId != null) 'parentId': parentId,
      },
    ),
    position: position,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders layered graph elements', (tester) async {
    final GoldenFileComparator previousComparator = goldenFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      Uri.parse('test/graph_layers_golden_test.dart'),
      precisionTolerance: 0.02,
    );
    addTearDown(() => goldenFileComparator = previousComparator);

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 220);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final RenderConfig config = const RenderConfig(
      badgeTintBySeverity: true,
      nodeEventBadgeEnabled: true,
    );
    final Map<String, String?> parentById = <String, String?>{
      'child': 'parent',
      'sibling': null,
      'parent': null,
    };
    final List<DisplayNode> nodes = <DisplayNode>[
      _displayNode(
        id: 'parent',
        position: const Offset(110, 110),
        type: 'service',
      ),
      _displayNode(
        id: 'child',
        position: const Offset(200, 110),
        parentId: 'parent',
        type: 'component',
        lifecycle: NodeLifecycle.unknown,
      ),
      _displayNode(
        id: 'sibling',
        position: const Offset(180, 60),
        type: 'service',
        lifecycle: NodeLifecycle.disposed,
      ),
    ];
    final EdgeAggregationPolicy edgePolicy = EdgeAggregationPolicy(
      collapsedParents: const <String>{},
      collapseProgress: const <String, double>{},
      parentById: parentById,
    );
    final CloudVisibilityPolicy cloudPolicy = CloudVisibilityPolicy(
      collapsedParents: const <String>{},
      collapseProgress: const <String, double>{},
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: Colors.black,
          child: Center(
            child: CustomPaint(
              size: const Size(280, 180),
              painter: GraphPainter(
                displayNodes: nodes,
                edges: <UyavaEdge>[
                  UyavaEdge(
                    data: const <String, Object?>{
                      'id': 'edge_pc',
                      'source': 'parent',
                      'target': 'child',
                    },
                  ),
                  UyavaEdge(
                    data: const <String, Object?>{
                      'id': 'edge_ps',
                      'source': 'parent',
                      'target': 'sibling',
                      'bidirectional': true,
                    },
                  ),
                ],
                events: const <UyavaEvent>[],
                nodeEvents: const <UyavaNodeEvent>[],
                collapsedParents: const <String>{},
                collapseProgress: const <String, double>{},
                directChildCounts: const <String, int>{'parent': 1},
                isParentId: (String id) => id == 'parent',
                parentById: parentById,
                edgePolicy: edgePolicy,
                cloudPolicy: cloudPolicy,
                renderConfig: config,
                edgeGlobalOpacity: 1.0,
                cloudGlobalOpacity: 1.0,
                eventQueueLabels: const <String, int>{'parent->child': 6},
                eventQueueLabelAlphas: const <String, double>{
                  'parent->child': 1,
                },
                eventQueueLabelSeverities: const <String, UyavaSeverity?>{
                  'parent->child': UyavaSeverity.warn,
                },
                nodeEventBadgeLabels: const <String, int>{'child': 3},
                nodeEventBadgeAlphas: const <String, double>{'child': 1},
                nodeEventBadgeSeverities: const <String, UyavaSeverity?>{
                  'child': UyavaSeverity.error,
                },
                uiForegroundColor: Colors.white,
                hoveredNodeId: 'child',
                hoveredEdgeId: 'edge_pc',
                highlightedNodeIds: const <String>{'parent'},
                highlightedEdges: <GraphHighlightEdge>{
                  GraphHighlightEdge(sourceId: 'parent', targetId: 'child'),
                },
                focusedNodeIds: const <String>{'sibling'},
                focusedEdgeIds: const <String>{'edge_ps'},
                focusColor: Colors.tealAccent,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CustomPaint),
      matchesGoldenFile('goldens/graph_layers.png'),
    );
  });
}
