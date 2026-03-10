import 'package:test/test.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('UyavaMetricDefinitionPayload', () {
    test('sanitize normalizes tags and aggregators', () {
      final result = UyavaMetricDefinitionPayload.sanitize({
        'id': 'metric.login',
        'label': ' Login Attempts ',
        'description': null,
        'tags': ['Auth', ' auth ', '', 123],
        'aggregators': ['sum', 'max', 'sum'],
      });

      expect(result.isValid, isTrue);
      expect(result.diagnostics, isEmpty);

      final UyavaMetricDefinitionPayload payload = result.payload!;
      expect(payload.id, 'metric.login');
      expect(payload.label, 'Login Attempts');
      expect(payload.tags, ['Auth']);
      expect(payload.tagsNormalized, ['auth']);
      expect(payload.aggregators, [
        UyavaMetricAggregator.sum,
        UyavaMetricAggregator.max,
      ]);
    });

    test('invalid aggregators emit diagnostics and fallback to default', () {
      final result = UyavaMetricDefinitionPayload.sanitize({
        'id': 'metric.error_rate',
        'aggregators': ['unknown'],
      });

      expect(
        result.isValid,
        isTrue,
        reason: 'payload remains usable despite invalid aggregators',
      );
      expect(
        result.diagnostics
            .map((d) => d.codeEnum)
            .whereType<UyavaGraphIntegrityCode>()
            .single,
        UyavaGraphIntegrityCode.metricsInvalidAggregator,
      );

      final UyavaMetricDefinitionPayload payload = result.payload!;
      expect(payload.aggregators, [UyavaMetricAggregator.last]);
    });

    test('missing id returns invalid result', () {
      final result = UyavaMetricDefinitionPayload.sanitize({
        'label': 'Broken metric',
      });

      expect(result.isValid, isFalse);
      expect(result.payload, isNull);
      expect(
        result.diagnostics
            .map((d) => d.codeEnum)
            .whereType<UyavaGraphIntegrityCode>()
            .single,
        UyavaGraphIntegrityCode.metricsMissingId,
      );
    });
  });

  group('UyavaMetricSamplePayload', () {
    test('accepts numeric values and optional timestamp', () {
      final result = UyavaMetricSamplePayload.sanitize({
        'id': 'metric.login',
        'value': '42.5',
        'timestamp': '2025-01-12T12:00:00Z',
      });

      expect(result.isValid, isTrue);
      expect(result.diagnostics, isEmpty);
      final UyavaMetricSamplePayload payload = result.payload!;
      expect(payload.id, 'metric.login');
      expect(payload.value, closeTo(42.5, 1e-6));
      expect(payload.timestamp?.toIso8601String(), '2025-01-12T12:00:00.000Z');
    });

    test('invalid value yields diagnostic and null payload', () {
      final result = UyavaMetricSamplePayload.sanitize({
        'id': 'metric.login',
        'value': 'not-a-number',
      });

      expect(result.isValid, isFalse);
      expect(result.payload, isNull);
      expect(
        result.diagnostics
            .map((d) => d.codeEnum)
            .whereType<UyavaGraphIntegrityCode>()
            .single,
        UyavaGraphIntegrityCode.metricsInvalidValue,
      );
    });
  });

  group('UyavaEventChainDefinitionPayload', () {
    test('sanitize produces ordered steps and trims metadata', () {
      final result = UyavaEventChainDefinitionPayload.sanitize({
        'id': 'login_flow',
        'tags': [' Chain:Login ', 'auth', 'AUTH', '', 99],
        'label': ' Login Flow ',
        'description': 'Auth happy path',
        'steps': [
          {'stepId': 'start', 'nodeId': 'ui_login '},
          {
            'stepId': 'submit',
            'nodeId': 'service_auth',
            'edgeId': 'edge_submit',
            'expectedSeverity': 'error',
          },
        ],
      });

      expect(result.isValid, isTrue);
      expect(
        result.diagnostics
            .map((d) => d.codeEnum)
            .whereType<UyavaGraphIntegrityCode>(),
        isEmpty,
      );

      final UyavaEventChainDefinitionPayload payload = result.payload!;
      expect(payload.id, 'login_flow');
      expect(payload.tags, ['Chain:Login', 'auth']);
      expect(payload.tagsNormalized, ['chain:login', 'auth']);
      expect(payload.tagsCatalog, ['auth']);
      // ignore: deprecated_member_use_from_same_package
      expect(payload.tag, 'Chain:Login');
      expect(payload.label, 'Login Flow');
      expect(payload.steps, hasLength(2));
      expect(payload.steps.first.stepId, 'start');
      expect(payload.steps.first.nodeId, 'ui_login');
      expect(payload.steps.last.expectedSeverity, UyavaSeverity.error);
    });

    test('legacy tag field is normalized into tags array', () {
      final result = UyavaEventChainDefinitionPayload.sanitize({
        'id': 'legacy_flow',
        'tag': ' flow:legacy ',
        'steps': [
          {'stepId': 'start', 'nodeId': 'ui_legacy'},
        ],
      });

      expect(result.isValid, isTrue);
      expect(result.diagnostics, isEmpty);

      final UyavaEventChainDefinitionPayload payload = result.payload!;
      expect(payload.tags, ['flow:legacy']);
      expect(payload.tagsNormalized, ['flow:legacy']);
      // ignore: deprecated_member_use_from_same_package
      expect(payload.tag, 'flow:legacy');
    });

    test('invalid steps surface diagnostics and invalidate payload', () {
      final result = UyavaEventChainDefinitionPayload.sanitize({
        'id': 'login_flow',
        'tags': ['chain:login'],
        'steps': [
          {'stepId': 'start', 'nodeId': 'ui_login'},
          {'stepId': 'start', 'nodeId': 'ui_login_secondary'},
          {'stepId': 'finish'},
        ],
      });

      expect(
        result.isValid,
        isFalse,
        reason: 'missing nodeId and duplicate step should invalidate',
      );
      expect(
        result.diagnostics
            .map((d) => d.codeEnum)
            .whereType<UyavaGraphIntegrityCode>(),
        containsAll(<UyavaGraphIntegrityCode>{
          UyavaGraphIntegrityCode.chainsInvalidStep,
          UyavaGraphIntegrityCode.chainsConflictingStep,
        }),
      );
    });

    test('missing tags emit chains.missing_tag diagnostic', () {
      final result = UyavaEventChainDefinitionPayload.sanitize({
        'id': 'broken_flow',
        'tags': [],
        'steps': [
          {'stepId': 'start', 'nodeId': 'ui_login'},
        ],
      });

      expect(result.isValid, isFalse);
      expect(result.payload, isNull);
      expect(
        result.diagnostics
            .map((d) => d.codeEnum)
            .whereType<UyavaGraphIntegrityCode>()
            .single,
        UyavaGraphIntegrityCode.chainsMissingTag,
      );
    });
  });

  group('UyavaGraphFilterCommandPayload', () {
    test('sanitize trims inputs and parses modes', () {
      final result = UyavaGraphFilterCommandPayload.sanitize({
        'search': {'mode': 'regex', 'pattern': r'auth.*', 'flags': 'imx'},
        'tags': {
          'mode': 'include',
          'values': [' Auth ', 'core', '', 42],
        },
        'nodes': {
          'include': ['nodeA', ' nodeB '],
          'exclude': ['legacy_*', 'legacy_*'],
        },
        'edges': {
          'include': [],
          'exclude': ['edgeOld'],
        },
        'parent': {'rootId': ' group_root ', 'depth': '2'},
        'grouping': {'mode': 'level', 'levelDepth': 1},
      });

      expect(result.isValid, isTrue);
      expect(result.diagnostics, isEmpty);

      final UyavaGraphFilterCommandPayload payload = result.payload;
      final search = payload.search!;
      expect(search.mode, UyavaFilterSearchMode.regex);
      expect(search.pattern, r'auth.*');
      expect(
        search.caseSensitive,
        isFalse,
        reason: 'flag i forces case-insensitive matching',
      );
      expect(search.flags, 'im', reason: 'unknown flags are dropped');

      final tags = payload.tags!;
      expect(tags.values, ['Auth', 'core']);
      expect(tags.valuesNormalized, ['auth', 'core']);
      expect(tags.logic, UyavaFilterTagLogic.any);

      final nodes = payload.nodes!;
      expect(nodes.include, ['nodeA', 'nodeB']);
      expect(nodes.exclude, ['legacy_*']);

      final parent = payload.parent!;
      expect(parent.rootId, 'group_root');
      expect(parent.depth, 2);

      final grouping = payload.grouping!;
      expect(grouping.mode, UyavaFilterGroupingMode.level);
      expect(grouping.levelDepth, 1);
    });

    test('sanitize round-trips severity payload', () {
      final result = UyavaGraphFilterCommandPayload.sanitize({
        'severity': {'operator': 'atMost', 'level': 'fatal'},
      });

      expect(result.isValid, isTrue);
      expect(result.diagnostics, isEmpty);

      final UyavaGraphFilterCommandPayload payload = result.payload;
      final severity = payload.severity!;
      expect(severity.operator, UyavaFilterSeverityOperator.atMost);
      expect(severity.level, UyavaSeverity.fatal);

      final Map<String, dynamic> encoded = payload.toJson();
      expect(encoded['severity'], {'operator': 'atMost', 'level': 'fatal'});
      final restored = UyavaGraphFilterCommandPayload.fromJson(encoded);
      expect(restored.severity?.operator, UyavaFilterSeverityOperator.atMost);
      expect(restored.severity?.level, UyavaSeverity.fatal);
    });

    test('invalid severity operator emits filters.invalid_mode diagnostic', () {
      final result = UyavaGraphFilterCommandPayload.sanitize({
        'severity': {'operator': 'greaterThan', 'level': 'warn'},
      });

      final codes = result.diagnostics
          .map((d) => d.codeEnum)
          .whereType<UyavaGraphIntegrityCode>()
          .toSet();
      expect(codes, contains(UyavaGraphIntegrityCode.filtersInvalidMode));
      expect(result.isValid, isFalse);
      expect(result.payload.severity, isNull);
    });

    test('parses tag logic and falls back to any on invalid input', () {
      final result = UyavaGraphFilterCommandPayload.sanitize({
        'tags': {
          'mode': 'include',
          'values': ['auth'],
          'logic': 'all',
        },
      });

      expect(result.isValid, isTrue);
      final tags = result.payload.tags!;
      expect(tags.logic, UyavaFilterTagLogic.all);

      final invalid = UyavaGraphFilterCommandPayload.sanitize({
        'tags': {
          'mode': 'exclude',
          'values': ['beta'],
          'logic': 'unknown',
        },
      });

      expect(
        invalid.isValid,
        isFalse,
        reason: 'invalid logic should prevent the command from applying',
      );
      final invalidTags = invalid.payload.tags!;
      expect(invalidTags.logic, UyavaFilterTagLogic.any);
      expect(
        invalid.diagnostics
            .map((d) => d.codeEnum)
            .whereType<UyavaGraphIntegrityCode>(),
        contains(UyavaGraphIntegrityCode.filtersInvalidMode),
      );
    });

    test('invalid regex produces diagnostic and disables section', () {
      final result = UyavaGraphFilterCommandPayload.sanitize({
        'search': {'mode': 'regex', 'pattern': '['},
      });

      expect(result.isValid, isFalse);
      expect(
        result.payload.search,
        isNull,
        reason: 'invalid regex should be discarded',
      );
      expect(
        result.diagnostics
            .map((d) => d.codeEnum)
            .whereType<UyavaGraphIntegrityCode>()
            .single,
        UyavaGraphIntegrityCode.filtersInvalidPattern,
      );
    });
  });
}
