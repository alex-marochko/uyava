import 'package:flutter_test/flutter_test.dart';
import 'package:uyava/uyava.dart';

void main() {
  setUpAll(() {
    Uyava.initialize();
  });
  setUp(() {
    Uyava.postEventObserver = null;
    Uyava.replaceGraph(nodes: const <UyavaNode>[], edges: const <UyavaEdge>[]);
  });

  group('UyavaNode.toJson', () {
    test('normalizes tags, color, and shape', () {
      const node = UyavaNode(
        id: 'n1',
        tags: [' Auth ', 'beta', 'auth'],
        color: '#12ab34',
        shape: 'Hexagon',
      );
      final json = node.toJson();
      expect(json['tags'], ['Auth', 'beta']);
      expect(json['tagsNormalized'], ['auth', 'beta']);
      expect(json['tagsCatalog'], ['auth']);
      expect(json['color'], '#12AB34');
      expect(json['shape'], 'hexagon');
      expect(json.containsKey('colorPriorityIndex'), isFalse);
    });
  });

  group('Uyava.emitNodeEvent', () {
    test('emits normalized tag payload', () {
      final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (type, payload) {
        if (type == UyavaEventTypes.nodeEvent) {
          events.add(Map<String, dynamic>.from(payload));
        }
      };

      Uyava.emitNodeEvent(
        nodeId: 'foo',
        message: 'foo event',
        tags: ['  Auth ', 'auth', ' beta '],
      );

      expect(events, hasLength(1));
      expect(events.single['tags'], ['Auth', 'beta']);
      expect(events.single['message'], 'foo event');
    });
  });

  group('Uyava.addNode', () {
    test('serializes normalized metadata in payload', () {
      final List<Map<String, dynamic>> nodes = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (type, payload) {
        if (type == UyavaEventTypes.addNode) {
          nodes.add(Map<String, dynamic>.from(payload));
        }
      };

      Uyava.addNode(
        const UyavaNode(
          id: 'n1',
          tags: ['Auth', 'auth', 'beta'],
          color: '#00ff00',
          shape: 'Circle',
        ),
      );

      expect(nodes, isNotEmpty);
      final Map<String, dynamic> payload = nodes.last;
      expect(payload['tags'], ['Auth', 'beta']);
      expect(payload['tagsNormalized'], ['auth', 'beta']);
      expect(payload['tagsCatalog'], ['auth']);
      expect(payload['color'], '#00FF00');
      expect(payload['shape'], 'circle');
      expect(payload.containsKey('colorPriorityIndex'), isFalse);
    });
  });

  test('addNode includes priority color index when color is from palette', () {
    final List<Map<String, dynamic>> nodes = <Map<String, dynamic>>[];
    Uyava.postEventObserver = (type, payload) {
      if (type == UyavaEventTypes.addNode) {
        nodes.add(Map<String, dynamic>.from(payload));
      }
    };

    Uyava.addNode(const UyavaNode(id: 'n2', color: '#FF7B72'));

    expect(nodes, isNotEmpty);
    final Map<String, dynamic> payload = nodes.last;
    expect(payload['color'], '#FF7B72');
    expect(payload['colorPriorityIndex'], 4);
  });

  group('Diagnostics emission', () {
    test('addNode emits diagnostic for invalid node color', () {
      final List<Map<String, dynamic>> diagnostics = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (type, payload) {
        if (type == UyavaEventTypes.graphDiagnostics) {
          diagnostics.add(Map<String, dynamic>.from(payload));
        }
      };

      Uyava.addNode(const UyavaNode(id: 'n1', color: 'red'));

      expect(diagnostics, hasLength(1));
      final Map<String, dynamic> diag = diagnostics.single;
      expect(diag['codeEnum'], UyavaGraphIntegrityCode.nodesInvalidColor.name);
      expect(diag['nodeId'], 'n1');
      final Map<String, Object?> context = (diag['context'] as Map)
          .cast<String, Object?>();
      expect(context['value'], 'red');
    });

    test('addNode emits diagnostic for invalid node shape', () {
      final List<Map<String, dynamic>> diagnostics = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (type, payload) {
        if (type == UyavaEventTypes.graphDiagnostics) {
          diagnostics.add(Map<String, dynamic>.from(payload));
        }
      };

      Uyava.addNode(const UyavaNode(id: 'n2', shape: 'Not Valid!'));

      expect(diagnostics, hasLength(1));
      final Map<String, dynamic> diag = diagnostics.single;
      expect(diag['codeEnum'], UyavaGraphIntegrityCode.nodesInvalidShape.name);
      expect(diag['nodeId'], 'n2');
      final Map<String, Object?> context = (diag['context'] as Map)
          .cast<String, Object?>();
      expect(context['value'], 'Not Valid!');
    });
  });
}
