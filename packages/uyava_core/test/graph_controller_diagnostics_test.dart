import 'package:test/test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

class _StubEngine implements LayoutEngine {
  Map<String, Vector2> _positions = const {};

  @override
  void initialize({
    required List<UyavaNode> nodes,
    required List<UyavaEdge> edges,
    required Size2D size,
    Map<String, Vector2>? initialPositions,
  }) {
    _positions = {for (final node in nodes) node.id: const Vector2(0, 0)};
  }

  @override
  bool get isConverged => true;

  @override
  Map<String, Vector2> get positions =>
      Map<String, Vector2>.unmodifiable(_positions);

  @override
  void step() {}
}

void main() {
  test('GraphController combines core and app diagnostics', () async {
    var ticks = 0;
    DateTime fakeClock() =>
        DateTime.utc(2024, 1, 1).add(Duration(seconds: ticks++));
    final buffer = GraphDiagnosticsBuffer(clock: fakeClock);
    final controller = GraphController(
      engine: _StubEngine(),
      diagnostics: buffer,
    );

    final emissions = <List<GraphDiagnosticRecord>>[];
    final subscription = controller.diagnosticsStream.listen(emissions.add);

    controller.replaceGraph({
      'nodes': [
        {'id': 'node-1', 'color': '#GGHHII'},
      ],
      'edges': const [],
    }, const Size2D(100, 100));

    await Future<void>.delayed(Duration.zero);

    expect(buffer.records, hasLength(1));
    final core = buffer.records.single;
    expect(core.source, GraphDiagnosticSource.core);
    expect(core.code, UyavaGraphIntegrityCode.nodesInvalidColor.toWireString());
    expect(core.codeEnum, UyavaGraphIntegrityCode.nodesInvalidColor);
    expect(core.subjects, ['node-1']);

    controller.addAppDiagnostic(
      code: 'sdk.custom_warning',
      level: UyavaDiagnosticLevel.warning,
      subjects: const ['edge-3'],
      context: const {'reason': 'dangling'},
    );

    await Future<void>.delayed(Duration.zero);

    expect(buffer.records, hasLength(2));
    final app = buffer.records.last;
    expect(app.source, GraphDiagnosticSource.app);
    expect(app.code, 'sdk.custom_warning');
    expect(app.codeEnum, isNull);
    expect(app.subjects, ['edge-3']);
    expect(app.timestamp, DateTime.utc(2024, 1, 1, 0, 0, 1));

    expect(emissions, hasLength(2));
    expect(emissions.last, hasLength(2));
    await subscription.cancel();
  });

  test('clearDiagnostics removes all records and notifies listeners', () async {
    final events = <List<GraphDiagnosticRecord>>[];
    final controller = GraphController(
      engine: _StubEngine(),
      diagnostics: GraphDiagnosticsBuffer(
        clock: () => DateTime.utc(2024, 1, 1),
      ),
    );

    final sub = controller.diagnosticsStream.listen(events.add);

    controller.addAppDiagnostic(
      code: 'sdk.test_case',
      level: UyavaDiagnosticLevel.info,
      subjects: const ['node-a'],
    );

    await Future<void>.delayed(Duration.zero);
    expect(controller.diagnostics.records, isNotEmpty);

    controller.clearDiagnostics();

    await Future<void>.delayed(Duration.zero);

    expect(controller.diagnostics.records, isEmpty);
    expect(events.last, isEmpty);

    await sub.cancel();
  });

  test('addAppDiagnostic resolves enum from wire code automatically', () async {
    var ticks = 0;
    DateTime fakeClock() =>
        DateTime.utc(2024, 1, 1).add(Duration(seconds: ticks++));
    final buffer = GraphDiagnosticsBuffer(clock: fakeClock);
    final controller = GraphController(
      engine: _StubEngine(),
      diagnostics: buffer,
    );

    controller.addAppDiagnostic(
      code: UyavaGraphIntegrityCode.edgesDuplicateId.toWireString(),
      level: UyavaDiagnosticLevel.warning,
      subjects: const ['edge-42'],
    );

    await Future<void>.delayed(Duration.zero);

    final record = buffer.records.single;
    expect(record.codeEnum, UyavaGraphIntegrityCode.edgesDuplicateId);
    expect(
      record.code,
      UyavaGraphIntegrityCode.edgesDuplicateId.toWireString(),
    );
  });

  test('addAppDiagnosticPayload forwards payload into buffer', () async {
    var ticks = 0;
    DateTime fakeClock() =>
        DateTime.utc(2024, 1, 1).add(Duration(seconds: ticks++));
    final buffer = GraphDiagnosticsBuffer(clock: fakeClock);
    final controller = GraphController(
      engine: _StubEngine(),
      diagnostics: buffer,
    );

    final payload = UyavaGraphDiagnosticPayload(
      code: 'nodes.conflicting_tags',
      codeEnum: UyavaGraphIntegrityCode.nodesConflictingTags,
      level: UyavaDiagnosticLevel.warning,
      nodeId: 'node-x',
      context: const {
        'previous': ['domain'],
        'next': ['Domain'],
      },
    );

    final emissions = <List<GraphDiagnosticRecord>>[];
    final sub = controller.diagnosticsStream.listen(emissions.add);

    controller.addAppDiagnosticPayload(
      payload,
      timestamp: DateTime.utc(2024, 6, 1, 10, 0, 0),
    );

    await Future<void>.delayed(Duration.zero);

    expect(buffer.records, hasLength(1));
    final record = buffer.records.single;
    expect(record.codeEnum, UyavaGraphIntegrityCode.nodesConflictingTags);
    expect(record.code, 'nodes.conflicting_tags');
    expect(record.subjects, ['node-x']);
    expect(record.timestamp, DateTime.utc(2024, 6, 1, 10, 0, 0));
    expect(emissions, isNotEmpty);
    await sub.cancel();
  });
}
