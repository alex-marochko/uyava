import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  const RenderConfig renderConfig = RenderConfig();

  group('journal_reveal_helpers', () {
    test('buildFocusHighlight merges focused edges into the node set', () {
      final UyavaNode parent = _node('root');
      final UyavaNode child = _node('leaf', parentId: 'root');
      final UyavaEdge edge = _edge('edge-root-leaf', 'root', 'leaf');
      final _TestGraphController controller = _TestGraphController(
        nodes: [parent, child],
        edges: [edge],
        positions: const {'root': Vector2(0, 0), 'leaf': Vector2(20, 0)},
      );

      final GraphHighlight highlight = buildFocusHighlight(
        focusState: GraphFocusState(
          nodeIds: const {'root'},
          edgeIds: const {'edge-root-leaf'},
        ),
        graphController: controller,
      );

      expect(highlight.nodeIds, containsAll(<String>['root', 'leaf']));
      expect(
        highlight.edges,
        contains(const GraphHighlightEdge(sourceId: 'root', targetId: 'leaf')),
      );
    });

    test('resolveJournalLinkReveal returns null when target is missing', () {
      final _TestGraphController controller = _TestGraphController(
        nodes: const [],
        edges: const [],
        positions: const {},
      );

      final JournalRevealRequest? request = resolveJournalLinkReveal(
        link: const GraphJournalNodeLink(nodeId: 'ghost'),
        graphController: controller,
        renderConfig: renderConfig,
        manualCollapsedParents: const <String>{},
        collapseProgress: const <String, double>{},
        autoCollapseOverrides: const <String>{},
      );

      expect(request, isNull);
    });

    test(
      'resolveJournalLinkReveal surfaces filtered nodes and collapsed parents',
      () {
        final UyavaNode parent = _node('group');
        final UyavaNode child = _node('leaf', parentId: 'group');
        final _TestGraphController controller = _TestGraphController(
          nodes: [parent, child],
          edges: const [],
          positions: const {'group': Vector2(0, 0), 'leaf': Vector2(80, 0)},
          filteredNodes: [parent],
        );

        final JournalRevealRequest? request = resolveJournalLinkReveal(
          link: const GraphJournalNodeLink(nodeId: 'leaf'),
          graphController: controller,
          renderConfig: renderConfig,
          manualCollapsedParents: const {'group'},
          collapseProgress: const <String, double>{},
          autoCollapseOverrides: const <String>{},
        );

        expect(request, isNotNull);
        final JournalRevealPlan plan = request!.revealPlan;
        expect(plan.hiddenByFilters, isTrue);
        expect(plan.filteredNodeIds, contains('leaf'));
        expect(plan.parentsToExpand, contains('group'));
        expect(request.focusResult, isNotNull);
      },
    );

    test(
      'buildFocusRevealRequest returns viewport target for visible focus',
      () {
        final UyavaNode parent = _node('root');
        final UyavaNode child = _node('leaf', parentId: 'root');
        final _TestGraphController controller = _TestGraphController(
          nodes: [parent, child],
          edges: const [],
          positions: const {'root': Vector2(0, 0), 'leaf': Vector2(40, 0)},
        );

        final JournalRevealRequest? request = buildFocusRevealRequest(
          focusState: GraphFocusState(nodeIds: const {'leaf'}),
          graphController: controller,
          renderConfig: renderConfig,
          manualCollapsedParents: const <String>{},
          collapseProgress: const <String, double>{},
          autoCollapseOverrides: const <String>{},
        );

        expect(request, isNotNull);
        expect(request!.highlight.nodeIds, contains('leaf'));
        expect(request.focusResult, isNotNull);
        expect(request.revealPlan.isFullyVisible, isTrue);
      },
    );
  });
}

UyavaNode _node(String id, {String? parentId}) {
  return UyavaNode(
    rawData: {
      'id': id,
      'label': id,
      if (parentId != null) 'parentId': parentId,
    },
  );
}

UyavaEdge _edge(String id, String source, String target) {
  return UyavaEdge(data: {'id': id, 'source': source, 'target': target});
}

class _TestGraphController extends GraphController {
  _TestGraphController({
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
    required Map<String, Vector2> positions,
    List<UyavaNode>? filteredNodes,
    List<UyavaEdge>? filteredEdges,
    Set<String>? autoCollapsedParents,
  }) : _filteredNodes = List<UyavaNode>.unmodifiable(filteredNodes ?? nodes),
       _filteredEdges = List<UyavaEdge>.unmodifiable(filteredEdges ?? edges),
       _autoCollapsedParents = Set<String>.from(
         autoCollapsedParents ?? const <String>{},
       ),
       super(engine: GridLayout()) {
    this.nodes = nodes;
    this.edges = edges;
    this.positions = Map<String, Vector2>.from(positions);
  }

  final List<UyavaNode> _filteredNodes;
  final List<UyavaEdge> _filteredEdges;
  final Set<String> _autoCollapsedParents;

  @override
  List<UyavaNode> get filteredNodes => _filteredNodes;

  @override
  List<UyavaEdge> get filteredEdges => _filteredEdges;

  @override
  Set<String> get autoCollapsedParents => _autoCollapsedParents;
}
