import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';

void main() {
  group('GraphController validation', () {
    test('deduplicates nodes and records duplicate diagnostics', () {
      final controller = GraphController();
      controller.replaceGraph({
        'nodes': [
          {'id': 'n1', 'label': 'first'},
          {'id': 'n1', 'label': 'second'},
        ],
        'edges': const [],
      }, const Size2D(200, 200));

      expect(controller.nodes, hasLength(1));
      expect(controller.nodes.single.label, 'second');
      final issueCodes = controller.integrity.issues
          .map((issue) => issue.code)
          .toSet();
      expect(
        issueCodes.contains(UyavaGraphIntegrityCode.nodesDuplicateId),
        isTrue,
      );
      final duplicateIssue = controller.integrity.issues.firstWhere(
        (issue) => issue.code == UyavaGraphIntegrityCode.nodesDuplicateId,
      );
      expect(duplicateIssue.level, UyavaDiagnosticLevel.warning);
    });

    test('skips nodes without id and records diagnostics', () {
      final controller = GraphController();
      controller.replaceGraph({
        'nodes': [
          {'label': 'missing'},
          {'id': 'keep'},
        ],
        'edges': const [],
      }, const Size2D(200, 200));

      expect(controller.nodes.map((n) => n.id).toList(), ['keep']);
      final missing = controller.integrity.issues.singleWhere(
        (issue) => issue.code == UyavaGraphIntegrityCode.nodesMissingId,
      );
      expect(missing.level, UyavaDiagnosticLevel.error);
    });

    test('drops edges missing endpoints and records diagnostics', () {
      final controller = GraphController();
      controller.replaceGraph({
        'nodes': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'edges': [
          {'id': 'e1', 'source': 'a'},
          {'id': 'e2', 'target': 'b'},
        ],
      }, const Size2D(200, 200));

      expect(controller.edges, isEmpty);
      final codes = controller.integrity.issues
          .map((issue) => issue.code)
          .toSet();
      expect(
        codes.contains(UyavaGraphIntegrityCode.edgesMissingTarget),
        isTrue,
      );
      expect(
        codes.contains(UyavaGraphIntegrityCode.edgesMissingSource),
        isTrue,
      );
      final missingSource = controller.integrity.issues.singleWhere(
        (issue) => issue.code == UyavaGraphIntegrityCode.edgesMissingSource,
      );
      final missingTarget = controller.integrity.issues.singleWhere(
        (issue) => issue.code == UyavaGraphIntegrityCode.edgesMissingTarget,
      );
      expect(missingSource.level, UyavaDiagnosticLevel.error);
      expect(missingTarget.level, UyavaDiagnosticLevel.error);
    });

    test('drops edges referencing unknown nodes and self-loops', () {
      final controller = GraphController();
      controller.replaceGraph({
        'nodes': [
          {'id': 'a'},
        ],
        'edges': [
          {'id': 'dangling', 'source': 'a', 'target': 'missing'},
          {'id': 'loop', 'source': 'a', 'target': 'a'},
        ],
      }, const Size2D(200, 200));

      expect(controller.edges, isEmpty);
      final codes = controller.integrity.issues
          .map((issue) => issue.code)
          .toSet();
      expect(
        codes.contains(UyavaGraphIntegrityCode.edgesDanglingTarget),
        isTrue,
      );
      expect(codes.contains(UyavaGraphIntegrityCode.edgesSelfLoop), isTrue);
      final dangling = controller.integrity.issues.singleWhere(
        (issue) => issue.code == UyavaGraphIntegrityCode.edgesDanglingTarget,
      );
      final loop = controller.integrity.issues.singleWhere(
        (issue) => issue.code == UyavaGraphIntegrityCode.edgesSelfLoop,
      );
      expect(dangling.level, UyavaDiagnosticLevel.error);
      expect(loop.level, UyavaDiagnosticLevel.error);
    });

    test('deduplicates edges and records duplicate diagnostics', () {
      final controller = GraphController();
      controller.replaceGraph({
        'nodes': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'edges': [
          {'id': 'e1', 'source': 'a', 'target': 'b'},
          {'id': 'e1', 'source': 'a', 'target': 'b'},
        ],
      }, const Size2D(200, 200));

      expect(controller.edges, hasLength(1));
      final duplicateIssue = controller.integrity.issues.singleWhere(
        (issue) => issue.code == UyavaGraphIntegrityCode.edgesDuplicateId,
      );
      expect(duplicateIssue.level, UyavaDiagnosticLevel.warning);
      expect(duplicateIssue.edgeId, 'e1');
    });

    test('_sanitizeGraphData drops malformed entries and reports issues', () {
      final controller = GraphController();
      controller.replaceGraph({
        'nodes': [
          {'id': 'root', 'parentId': 'child'},
          {'id': 'child', 'parentId': 'root'},
          {'label': 'missing-id'},
          'invalid-node',
          {'id': 'root', 'label': 'duplicate root'},
          {'id': 'valid', 'parentId': 'ghost'},
        ],
        'edges': [
          {'id': 'danglingSource', 'target': 'child'},
          {'id': 'danglingTarget', 'source': 'root'},
          'invalid-edge',
          {'id': 'validEdge', 'source': 'root', 'target': 'child'},
          {'id': 'duplicateEdge', 'source': 'root', 'target': 'valid'},
          {'id': 'duplicateEdge', 'source': 'root', 'target': 'child'},
        ],
      }, const Size2D(200, 200));

      expect(controller.nodes.map((n) => n.id), ['child', 'root', 'valid']);
      expect(controller.edges.map((e) => e.id), ['duplicateEdge', 'validEdge']);

      final Set<UyavaGraphIntegrityCode> codes = controller.integrity.issues
          .map((issue) => issue.code)
          .toSet();
      expect(
        codes,
        containsAll(<UyavaGraphIntegrityCode>{
          UyavaGraphIntegrityCode.nodesMissingId,
          UyavaGraphIntegrityCode.edgesMissingId,
          UyavaGraphIntegrityCode.edgesMissingSource,
          UyavaGraphIntegrityCode.edgesMissingTarget,
          UyavaGraphIntegrityCode.nodesDuplicateId,
          UyavaGraphIntegrityCode.edgesDuplicateId,
        }),
      );
    });
  });
}
