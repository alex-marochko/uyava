import 'package:flutter_test/flutter_test.dart';
import 'package:uyava/uyava.dart';

void main() {
  setUpAll(() {
    Uyava.initialize();
  });

  setUp(() {
    Uyava.resetStateForTesting();
    Uyava.postEventObserver = null;
  });

  tearDown(() {
    Uyava.resetStateForTesting();
    Uyava.postEventObserver = null;
  });

  group('Uyava.defineMetric', () {
    test('emits sanitized payload with normalized tags and aggregators', () {
      final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        events.add(<String, dynamic>{
          'type': type,
          'payload': Map<String, dynamic>.from(payload),
        });
      };

      Uyava.defineMetric(
        id: 'latency',
        label: 'Latency (ms)',
        description: 'Request latency over the current session',
        unit: 'ms',
        tags: <String>[' perf ', 'Telemetry', 'perf'],
        aggregators: <UyavaMetricAggregator>[
          UyavaMetricAggregator.last,
          UyavaMetricAggregator.max,
          UyavaMetricAggregator.min,
        ],
      );

      expect(events, hasLength(1));
      final Map<String, dynamic> event = events.single;
      expect(event['type'], UyavaEventTypes.defineMetric);
      final Map<String, dynamic> payload =
          event['payload'] as Map<String, dynamic>;
      expect(payload['id'], 'latency');
      expect(payload['label'], 'Latency (ms)');
      expect(payload['unit'], 'ms');
      expect(payload['tags'], <String>['perf', 'Telemetry']);
      expect(payload['tagsNormalized'], <String>['perf', 'telemetry']);
      expect(payload['aggregators'], <String>['last', 'max', 'min']);
    });

    test('emits diagnostic and throws when metric id is missing', () {
      final List<Map<String, dynamic>> diagnostics = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        if (type == UyavaEventTypes.graphDiagnostics) {
          diagnostics.add(Map<String, dynamic>.from(payload));
        }
      };

      expect(() => Uyava.defineMetric(id: '  '), throwsStateError);

      expect(diagnostics, hasLength(1));
      final Map<String, dynamic> diagnostic = diagnostics.single;
      expect(
        diagnostic['codeEnum'],
        UyavaGraphIntegrityCode.metricsMissingId.name,
      );
    });
  });

  group('Uyava.defineEventChain', () {
    test('emits sanitized payload including trimmed identifiers', () {
      final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        events.add(<String, dynamic>{
          'type': type,
          'payload': Map<String, dynamic>.from(payload),
        });
      };

      Uyava.defineEventChain(
        id: ' login_flow ',
        tags: const [' Chain:Login ', 'Auth', 'auth', ''],
        label: 'Login Flow',
        description: 'Guided happy path for logging in',
        steps: const <UyavaEventChainStep>[
          UyavaEventChainStep(stepId: 'start', nodeId: 'ui_login'),
          UyavaEventChainStep(
            stepId: 'submit',
            nodeId: 'ui_login',
            edgeId: 'edge_auth',
            expectedSeverity: UyavaSeverity.warn,
          ),
        ],
      );

      expect(events, hasLength(1));
      final Map<String, dynamic> event = events.single;
      expect(event['type'], UyavaEventTypes.defineEventChain);
      final Map<String, dynamic> payload =
          event['payload'] as Map<String, dynamic>;
      expect(payload['id'], 'login_flow');
      expect(payload['tags'], ['Chain:Login', 'Auth']);
      expect(payload['tagsNormalized'], ['chain:login', 'auth']);
      expect(payload['tag'], 'Chain:Login');
      expect(payload['label'], 'Login Flow');
      expect(payload['description'], 'Guided happy path for logging in');
      final List<dynamic> steps = payload['steps'] as List<dynamic>;
      expect(steps, hasLength(2));
      final Map<String, dynamic> submitStep = steps[1] as Map<String, dynamic>;
      expect(submitStep['stepId'], 'submit');
      expect(submitStep['nodeId'], 'ui_login');
      expect(submitStep['edgeId'], 'edge_auth');
      expect(submitStep['expectedSeverity'], 'warn');
    });

    test('emits diagnostic and throws when steps are missing', () {
      final List<Map<String, dynamic>> diagnostics = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        if (type == UyavaEventTypes.graphDiagnostics) {
          diagnostics.add(Map<String, dynamic>.from(payload));
        }
      };

      expect(
        () => Uyava.defineEventChain(
          id: 'empty',
          tag: 'chain:empty',
          steps: const <UyavaEventChainStep>[],
        ),
        throwsStateError,
      );

      expect(diagnostics, hasLength(1));
      final Map<String, dynamic> diagnostic = diagnostics.single;
      expect(
        diagnostic['codeEnum'],
        UyavaGraphIntegrityCode.chainsInvalidStep.name,
      );
    });

    test('accepts legacy tag parameter for backwards compatibility', () {
      final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        events.add(<String, dynamic>{
          'type': type,
          'payload': Map<String, dynamic>.from(payload),
        });
      };

      Uyava.defineEventChain(
        id: 'legacy',
        tag: 'legacy-flow',
        steps: const <UyavaEventChainStep>[
          UyavaEventChainStep(stepId: 'start', nodeId: 'ui_legacy'),
        ],
      );

      expect(events, hasLength(1));
      final Map<String, dynamic> payload =
          events.single['payload'] as Map<String, dynamic>;
      expect(payload['tags'], ['legacy-flow']);
      expect(payload['tagsNormalized'], ['legacy-flow']);
      expect(payload['tag'], 'legacy-flow');
    });
  });

  group('Uyava.emitNodeEvent metric payloads', () {
    test('normalizes metric samples before emission', () {
      final List<Map<String, dynamic>> nodeEvents = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        if (type == UyavaEventTypes.nodeEvent) {
          nodeEvents.add(Map<String, dynamic>.from(payload));
        }
      };

      Uyava.emitNodeEvent(
        nodeId: 'auth_bloc',
        message: 'auth_bloc latency sample',
        payload: <String, dynamic>{
          'metric': <String, dynamic>{
            'id': 'latency',
            'value': 12,
            'timestamp': '2024-01-02T03:04:05.678Z',
          },
          'extra': 'keep-me',
        },
      );

      expect(nodeEvents, hasLength(1));
      final Map<String, dynamic> payload =
          nodeEvents.single['payload'] as Map<String, dynamic>;
      final Map<String, dynamic> metric =
          payload['metric'] as Map<String, dynamic>;
      expect(metric['id'], 'latency');
      expect(metric['value'], 12.0);
      expect(metric['timestamp'], '2024-01-02T03:04:05.678Z');
      expect(payload['extra'], 'keep-me');
    });

    test('drops invalid metric payloads and surfaces diagnostics', () {
      final List<Map<String, dynamic>> diagnostics = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> nodeEvents = <Map<String, dynamic>>[];
      Uyava.postEventObserver = (String type, Map<String, dynamic> payload) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(payload);
        if (type == UyavaEventTypes.graphDiagnostics) {
          diagnostics.add(copy);
        } else if (type == UyavaEventTypes.nodeEvent) {
          nodeEvents.add(copy);
        }
      };

      Uyava.emitNodeEvent(
        nodeId: 'auth_bloc',
        message: 'auth_bloc invalid metric sample',
        payload: <String, dynamic>{
          'metric': <String, dynamic>{'id': 'latency', 'value': 'nan'},
        },
      );

      expect(diagnostics, hasLength(1));
      final Map<String, dynamic> diagnostic = diagnostics.single;
      expect(
        diagnostic['codeEnum'],
        UyavaGraphIntegrityCode.metricsInvalidValue.name,
      );
      expect(nodeEvents, hasLength(1));
      final Map<String, dynamic> payload =
          nodeEvents.single['payload'] as Map<String, dynamic>;
      expect(payload.containsKey('metric'), isFalse);
    });
  });
}
