import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:uyava/uyava.dart';

void main() {
  group('UyavaConsoleLogger', () {
    test('skips records below minLevel', () async {
      final _RecordingSink sink = _RecordingSink();
      final UyavaConsoleLogger logger = UyavaConsoleLogger(
        config: UyavaConsoleLoggerConfig(
          minLevel: UyavaSeverity.warn,
          bufferCapacity: 0,
          colorMode: UyavaConsoleColorMode.never,
          sink: sink.sink,
        ),
      );

      logger.log(
        _record(
          severity: UyavaSeverity.info,
          type: 'diagnostic',
          message: 'ignore',
        ),
      );
      logger.log(
        _record(
          severity: UyavaSeverity.warn,
          type: 'diagnostic',
          message: 'emit-me',
        ),
      );

      await logger.dispose();
      await _drainSink(sink);

      expect(sink.lines, hasLength(1));
      expect(sink.lines.single, contains('WARN '));
      expect(sink.lines.single, contains('emit-me'));
    });

    test('honours include and exclude filters', () async {
      final _RecordingSink sink = _RecordingSink();
      final UyavaConsoleLogger logger = UyavaConsoleLogger(
        config: UyavaConsoleLoggerConfig(
          minLevel: UyavaSeverity.trace,
          includeTypes: <String>{'allowed'},
          excludeTypes: <String>{'blocked'},
          bufferCapacity: 0,
          colorMode: UyavaConsoleColorMode.never,
          sink: sink.sink,
        ),
      );

      logger.log(
        _record(
          severity: UyavaSeverity.info,
          type: 'other',
          message: 'drop-by-include',
        ),
      );
      logger.log(
        _record(
          severity: UyavaSeverity.info,
          type: 'blocked',
          message: 'drop-by-exclude',
        ),
      );
      logger.log(
        _record(severity: UyavaSeverity.info, type: 'allowed', message: 'keep'),
      );

      await logger.dispose();
      await _drainSink(sink);

      expect(sink.lines, hasLength(1));
      expect(sink.lines.single, isNot(contains('drop')));
      expect(sink.lines.single, contains('allowed'));
      expect(sink.lines.single, contains('keep'));
    });

    test('drops oldest records when buffer capacity exceeded', () async {
      final _RecordingSink sink = _RecordingSink();
      final UyavaConsoleLogger logger = UyavaConsoleLogger(
        config: UyavaConsoleLoggerConfig(
          bufferCapacity: 2,
          flushInterval: const Duration(hours: 1),
          colorMode: UyavaConsoleColorMode.never,
          sink: sink.sink,
        ),
      );

      logger.log(
        _record(severity: UyavaSeverity.info, type: 'buffer', message: 'first'),
      );
      logger.log(
        _record(
          severity: UyavaSeverity.info,
          type: 'buffer',
          message: 'second',
        ),
      );
      logger.log(
        _record(severity: UyavaSeverity.info, type: 'buffer', message: 'third'),
      );

      expect(logger.droppedRecordCount, 1);

      await logger.dispose();
      await _drainSink(sink);

      final List<String> lines = sink.lines;
      expect(lines, hasLength(2));
      expect(lines.first, contains('second'));
      expect(lines.last, contains('third'));
    });

    test('flushes buffered records on dispose', () async {
      final _RecordingSink sink = _RecordingSink();
      final UyavaConsoleLogger logger = UyavaConsoleLogger(
        config: UyavaConsoleLoggerConfig(
          bufferCapacity: 4,
          flushInterval: const Duration(seconds: 5),
          colorMode: UyavaConsoleColorMode.never,
          sink: sink.sink,
        ),
      );

      logger.log(
        _record(
          severity: UyavaSeverity.info,
          type: 'pending',
          message: 'await flush',
        ),
      );

      expect(sink.lines, isEmpty);

      await logger.dispose();
      await _drainSink(sink);

      expect(sink.lines, hasLength(1));
      expect(sink.lines.single, contains('await flush'));
    });

    test('uses transport event severity when present', () async {
      final _RecordingSink sink = _RecordingSink();
      Uyava.enableConsoleLogging(
        config: UyavaConsoleLoggerConfig(
          bufferCapacity: 0,
          colorMode: UyavaConsoleColorMode.never,
          sink: sink.sink,
        ),
      );
      addTearDown(() async {
        await Uyava.disableConsoleLogging();
      });

      Uyava.emitEdgeEvent(
        edge: 'edge-1',
        message: 'fatal transport event',
        severity: UyavaSeverity.fatal,
      );

      await Uyava.disableConsoleLogging();
      await _drainSink(sink);

      final List<String> lines = sink.lines;
      expect(lines, hasLength(1));
      expect(lines.single, contains('FATAL'));
    });

    test('routes diagnostic map payloads into console output', () async {
      final _RecordingSink sink = _RecordingSink();
      final UyavaConsoleLogger logger = UyavaConsoleLogger(
        config: UyavaConsoleLoggerConfig(
          bufferCapacity: 0,
          colorMode: UyavaConsoleColorMode.never,
          sink: sink.sink,
        ),
      );
      final StreamController<dynamic> controller = StreamController<dynamic>();
      logger.attachDiagnosticsStream(controller.stream);

      final DateTime timestamp = DateTime.utc(2024, 3, 10, 12, 1, 2, 345);
      controller.add(<String, Object?>{
        'level': UyavaDiagnosticLevel.warning,
        'code': 'nodes.invalid_color',
        'codeEnum': UyavaGraphIntegrityCode.nodesInvalidColor,
        'subjects': <Object?>['node-42', ''],
        'context': <String, Object?>{'batch': 2},
        'timestamp': timestamp,
        'source': _DiagnosticSource.core,
      });

      await _pumpEventQueue();
      await logger.dispose();
      await _drainSink(sink);
      await controller.close();

      final List<String> lines = sink.lines;
      expect(lines, hasLength(1));
      final String line = lines.single;
      expect(line, contains('graphDiagnostics nodesInvalidColor [node-42]'));
      expect(line, contains('WARN '));
      expect(line, contains('source=core'));
      expect(line, contains('batch=2'));
      expect(line, contains('12:01:02.345'));
    });

    test('routes diagnostic object payloads into console output', () async {
      final _RecordingSink sink = _RecordingSink();
      final UyavaConsoleLogger logger = UyavaConsoleLogger(
        config: UyavaConsoleLoggerConfig(
          bufferCapacity: 0,
          colorMode: UyavaConsoleColorMode.never,
          sink: sink.sink,
        ),
      );
      final StreamController<dynamic> controller = StreamController<dynamic>();
      logger.attachDiagnosticsStream(controller.stream);

      final _DiagnosticEnvelope envelope = _DiagnosticEnvelope(
        level: UyavaDiagnosticLevel.error,
        code: 'edges.missing_target',
        codeEnum: UyavaGraphIntegrityCode.edgesMissingTarget,
        subjects: <String>['edge-7'],
        context: <String, Object?>{'target': 'node-B'},
        timestamp: DateTime.utc(2024, 6, 1, 18, 30, 40, 987),
        source: _DiagnosticSource.core,
      );
      controller.add(envelope);

      await _pumpEventQueue();

      await logger.dispose();
      await _drainSink(sink);
      await controller.close();

      final List<String> lines = sink.lines;
      expect(lines, hasLength(1));
      final String line = lines.single;
      expect(line, contains('graphDiagnostics edgesMissingTarget [edge-7]'));
      expect(line, contains('ERROR'));
      expect(line, contains('source=core'));
      expect(line, contains('target=node-B'));
      expect(line, contains('18:30:40.987'));
    });
  });

  group('UyavaConsoleFormatter', () {
    test('produces compact line without colors', () {
      final DateTime timestamp = DateTime(2024, 1, 2, 3, 4, 5, 6);
      final LinkedHashMap<String, Object?> context =
          LinkedHashMap<String, Object?>()
            ..['foo'] = 'bar'
            ..['count'] = 1;
      final UyavaConsoleLogRecord record = UyavaConsoleLogRecord(
        timestamp: timestamp,
        severity: UyavaSeverity.info,
        type: 'sample',
        code: 'diag',
        subjects: <String>['node-a', 'node-b'],
        message: 'hello world',
        context: context,
      );

      final String line = UyavaConsoleFormatter.format(
        record,
        colorEnabled: false,
      );

      expect(
        line,
        equals(
          '03:04:05.006 INFO  sample diag [node-a,node-b] - hello world '
          'foo=bar count=1',
        ),
      );
    });

    test('applies ANSI colors when enabled', () {
      final UyavaConsoleLogRecord record = UyavaConsoleLogRecord(
        timestamp: DateTime(2024, 4, 5, 6, 7, 8, 90),
        severity: UyavaSeverity.error,
        type: 'sample',
      );

      final String line = UyavaConsoleFormatter.format(
        record,
        colorEnabled: true,
      );

      expect(line, contains('\x1B[31mERROR\x1B[0m'));
    });
  });
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
}

Future<void> _drainSink(_RecordingSink sink) async {
  await sink.sink.flush();
  await _pumpEventQueue();
}

UyavaConsoleLogRecord _record({
  required UyavaSeverity severity,
  required String type,
  String? message,
}) {
  return UyavaConsoleLogRecord(
    timestamp: DateTime.utc(2024, 1, 1, 0, 0, 0, 1),
    severity: severity,
    type: type,
    message: message,
  );
}

class _RecordingSink {
  _RecordingSink() {
    sink = IOSink(_RecordingConsumer(_controller), encoding: utf8);
    _controller.stream
        .transform(utf8.decoder)
        .listen(_output.write, onDone: () => _outputDone.complete());
  }

  final StreamController<List<int>> _controller = StreamController<List<int>>();
  final StringBuffer _output = StringBuffer();
  final Completer<void> _outputDone = Completer<void>();

  late final IOSink sink;

  List<String> get lines {
    final String text = _output.toString();
    if (text.isEmpty) {
      return const <String>[];
    }
    return text
        .split('\n')
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> close() async {
    await sink.flush();
    await sink.close();
    await _outputDone.future;
  }
}

class _RecordingConsumer implements StreamConsumer<List<int>> {
  _RecordingConsumer(this._controller);

  final StreamController<List<int>> _controller;

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    return _controller.addStream(stream);
  }

  @override
  Future<void> close() {
    return _controller.close();
  }
}

class _DiagnosticEnvelope {
  _DiagnosticEnvelope({
    required this.level,
    required this.code,
    required this.codeEnum,
    required this.subjects,
    required this.context,
    required this.timestamp,
    required this.source,
  });

  final UyavaDiagnosticLevel level;
  final String code;
  final UyavaGraphIntegrityCode codeEnum;
  final List<String> subjects;
  final Map<String, Object?> context;
  final DateTime timestamp;
  final _DiagnosticSource source;
}

enum _DiagnosticSource { core }
