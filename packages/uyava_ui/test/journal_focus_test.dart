import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GraphController controller;
  const RenderConfig renderConfig = RenderConfig();

  setUp(() {
    controller = GraphController();
    controller.nodes = <UyavaNode>[
      UyavaNode.fromPayload(
        const UyavaGraphNodePayload(id: 'nodeA', label: 'Node A'),
      ),
      UyavaNode.fromPayload(
        const UyavaGraphNodePayload(id: 'nodeB', label: 'Node B'),
      ),
    ];
    controller.edges = <UyavaEdge>[
      UyavaEdge.fromPayload(
        const UyavaGraphEdgePayload(
          id: 'edge1',
          source: 'nodeA',
          target: 'nodeB',
        ),
      ),
    ];
    controller.positions = <String, Vector2>{
      'nodeA': const Vector2(0, 0),
      'nodeB': const Vector2(120, 40),
    };
  });

  test('resolveJournalLinkTarget returns highlight for node events', () {
    final GraphJournalFocusResult? result = resolveJournalLinkTarget(
      link: const GraphJournalNodeLink(nodeId: 'nodeA'),
      graphController: controller,
      renderConfig: renderConfig,
    );
    expect(result, isNotNull);
    expect(result!.highlight.nodeIds, contains('nodeA'));
    expect(result.highlight.edges, isEmpty);
    expect(result.focusPoint, const Offset(0, 0));
    expect(result.focusBounds, isNotNull);
    expect(result.focusBounds!.contains(const Offset(0, 0)), isTrue);
  });

  test('resolveJournalLinkTarget returns highlight for edge events', () {
    final GraphJournalFocusResult? result = resolveJournalLinkTarget(
      link: const GraphJournalEdgeLink(from: 'nodeA', to: 'nodeB'),
      graphController: controller,
      renderConfig: renderConfig,
    );
    expect(result, isNotNull);
    expect(result!.highlight.nodeIds, containsAll(<String>['nodeA', 'nodeB']));
    expect(
      result.highlight.edges,
      contains(const GraphHighlightEdge(sourceId: 'nodeA', targetId: 'nodeB')),
    );
    expect(result.focusPoint, isNotNull);
    expect(result.focusBounds, isNotNull);
    expect(result.focusBounds!.contains(const Offset(60, 20)), isTrue);
  });

  test('resolveJournalLinkTarget falls back to subjects', () {
    final GraphJournalFocusResult? nodeSubject = resolveJournalLinkTarget(
      link: const GraphJournalSubjectLink(subjectId: 'nodeB'),
      graphController: controller,
      renderConfig: renderConfig,
    );
    expect(nodeSubject, isNotNull);
    expect(nodeSubject!.highlight.nodeIds, contains('nodeB'));

    final GraphJournalFocusResult? edgeSubject = resolveJournalLinkTarget(
      link: const GraphJournalSubjectLink(subjectId: 'edge1'),
      graphController: controller,
      renderConfig: renderConfig,
    );
    expect(edgeSubject, isNotNull);
    expect(
      edgeSubject!.highlight.edges,
      contains(const GraphHighlightEdge(sourceId: 'nodeA', targetId: 'nodeB')),
    );
  });

  test('resolveJournalLinkTarget returns null when element missing', () {
    final GraphJournalFocusResult? result = resolveJournalLinkTarget(
      link: const GraphJournalNodeLink(nodeId: 'missing'),
      graphController: controller,
      renderConfig: renderConfig,
    );
    expect(result, isNull);
  });
}
