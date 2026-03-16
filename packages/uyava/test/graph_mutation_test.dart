import 'package:flutter_test/flutter_test.dart';
import 'package:uyava/uyava.dart';

void main() {
  final List<Map<String, dynamic>> captured = <Map<String, dynamic>>[];

  setUpAll(() {
    Uyava.initialize();
  });

  setUp(() {
    captured.clear();
    Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
      captured.add(<String, dynamic>{
        'type': type,
        'payload': Map<String, dynamic>.from(payload),
      });
    };
    Uyava.replaceGraph(nodes: const <UyavaNode>[], edges: const <UyavaEdge>[]);
    captured.clear();
  });

  tearDown(() {
    Uyava.replaceGraph(nodes: const <UyavaNode>[], edges: const <UyavaEdge>[]);
    captured.clear();
    Uyava.postEventObserver = null;
  });

  test('removeNode cascades connected edges and emits payload once', () {
    Uyava.addNode(const UyavaNode(id: 'A'));
    Uyava.addNode(const UyavaNode(id: 'B'));
    Uyava.addEdge(const UyavaEdge(id: 'edge_ab', from: 'A', to: 'B'));
    captured.clear();

    Uyava.removeNode('A');

    expect(captured, hasLength(1));
    final Map<String, dynamic> event = captured.single;
    expect(event['type'], UyavaEventTypes.removeNode);
    final Map<String, dynamic> payload =
        event['payload'] as Map<String, dynamic>;
    expect(payload['id'], 'A');
    expect(payload['cascadeEdgeIds'], ['edge_ab']);
  });

  test('removeEdge emits event when edge exists', () {
    Uyava.addNode(const UyavaNode(id: 'A'));
    Uyava.addNode(const UyavaNode(id: 'B'));
    Uyava.addEdge(const UyavaEdge(id: 'edge_ab', from: 'A', to: 'B'));
    captured.clear();

    Uyava.removeEdge('edge_ab');

    expect(captured, hasLength(1));
    final Map<String, dynamic> event = captured.single;
    expect(event['type'], UyavaEventTypes.removeEdge);
    final Map<String, dynamic> payload =
        event['payload'] as Map<String, dynamic>;
    expect(payload['id'], 'edge_ab');
  });

  test('patchNode replaces provided fields and keeps lifecycle', () {
    Uyava.addNode(
      const UyavaNode(
        id: 'svc',
        type: 'service',
        label: 'Legacy',
        tags: <String>['Auth'],
      ),
    );
    captured.clear();

    Uyava.patchNode('svc', <String, Object?>{
      'label': 'Gateway',
      'tags': <String>['gateway', 'Gateway'],
      'color': '#FF0088',
    });

    expect(captured, hasLength(1));
    final Map<String, dynamic> event = captured.single;
    expect(event['type'], UyavaEventTypes.patchNode);
    final Map<String, dynamic> payload =
        event['payload'] as Map<String, dynamic>;
    expect(payload['id'], 'svc');
    final Map<String, dynamic> node = payload['node'] as Map<String, dynamic>;
    expect(node['label'], 'Gateway');
    expect(node['color'], '#FF0088');
    expect(node['tags'], ['gateway']);
    expect(node['tagsNormalized'], ['gateway']);
    expect(node['lifecycle'], UyavaLifecycleState.unknown.name);
    final List<dynamic>? changed = payload['changedKeys'] as List<dynamic>?;
    expect(changed, isNotNull);
    expect(
      changed,
      containsAll(<String>['label', 'tags', 'tagsNormalized', 'color']),
    );
  });

  test('patchEdge updates label without disturbing nodes', () {
    Uyava.addNode(const UyavaNode(id: 'A'));
    Uyava.addNode(const UyavaNode(id: 'B'));
    Uyava.addEdge(
      const UyavaEdge(id: 'edge_ab', from: 'A', to: 'B', label: 'legacy'),
    );
    captured.clear();

    Uyava.patchEdge('edge_ab', <String, Object?>{'label': 'modern'});

    expect(captured, hasLength(1));
    final Map<String, dynamic> event = captured.single;
    expect(event['type'], UyavaEventTypes.patchEdge);
    final Map<String, dynamic> payload =
        event['payload'] as Map<String, dynamic>;
    expect(payload['id'], 'edge_ab');
    final Map<String, dynamic> edge = payload['edge'] as Map<String, dynamic>;
    expect(edge['label'], 'modern');
    expect(edge['source'], 'A');
    expect(edge['target'], 'B');
    final List<dynamic>? changed = payload['changedKeys'] as List<dynamic>?;
    expect(changed, contains('label'));
  });

  test('patchEdge emits diagnostic when linking to unknown node', () {
    Uyava.addNode(const UyavaNode(id: 'A'));
    Uyava.addNode(const UyavaNode(id: 'B'));
    Uyava.addEdge(const UyavaEdge(id: 'edge_ab', from: 'A', to: 'B'));
    captured.clear();

    Uyava.patchEdge('edge_ab', <String, Object?>{'target': 'missing'});

    expect(captured, hasLength(1));
    final Map<String, dynamic> event = captured.single;
    expect(event['type'], UyavaEventTypes.graphDiagnostics);
    final Map<String, dynamic> payload =
        event['payload'] as Map<String, dynamic>;
    expect(
      payload['codeEnum'],
      UyavaGraphIntegrityCode.edgesDanglingTarget.name,
    );
  });
}
