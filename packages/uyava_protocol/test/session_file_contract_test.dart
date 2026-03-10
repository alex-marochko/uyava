import 'package:test/test.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

void main() {
  group('Uyava session file contract', () {
    test('round trips header with metadata and redaction', () {
      final DateTime startedAt = DateTime.utc(2024, 1, 1, 12, 0, 0);
      final UyavaSessionHeader header = UyavaSessionHeader(
        sessionId: 'sess-123',
        startedAt: startedAt,
        appName: 'ExampleApp',
        appVersion: '1.2.3',
        buildNumber: '100',
        platform: 'macos',
        platformVersion: '14.5',
        timezone: 'Europe/Kyiv',
        reason: 'repro crash',
        compression: UyavaSessionCompression.zstd,
        redaction: const UyavaSessionRedactionSummary(
          redactionApplied: true,
          allowRawData: false,
          maskFields: <String>['payload.secret'],
          dropFields: <String>['rawData'],
          tagsAllowList: <String>['foo'],
          tagsDenyList: <String>['bar'],
        ),
        hostMetadata: const <String, Object?>{'cpu': 'arm64'},
        recorderMetadata: const <String, Object?>{'recorder': 'desktop'},
      );

      final Map<String, Object?> json = header.toJson();
      expect(json['type'], 'sessionHeader');
      expect(json['formatVersion'], kUyavaSessionFormatVersion);
      expect(json['schemaVersion'], kUyavaSessionFormatVersion);
      expect(json['compression'], 'zstd');

      final UyavaSessionHeader parsed = UyavaSessionHeader.fromJson(
        Map<String, dynamic>.from(json),
      );
      expect(parsed.sessionId, header.sessionId);
      expect(parsed.startedAt.toIso8601String(), startedAt.toIso8601String());
      expect(parsed.appName, 'ExampleApp');
      expect(parsed.appVersion, '1.2.3');
      expect(parsed.buildNumber, '100');
      expect(parsed.platform, 'macos');
      expect(parsed.platformVersion, '14.5');
      expect(parsed.timezone, 'Europe/Kyiv');
      expect(parsed.reason, 'repro crash');
      expect(parsed.compression, UyavaSessionCompression.zstd);
      expect(parsed.redaction?.redactionApplied, isTrue);
      expect(parsed.redaction?.maskFields, contains('payload.secret'));
      expect(parsed.redaction?.dropFields, contains('rawData'));
      expect(parsed.hostMetadata['cpu'], 'arm64');
      expect(parsed.recorderMetadata['recorder'], 'desktop');
    });

    test('rejects future format versions', () {
      final UyavaSessionFormatAdapter adapter = UyavaSessionFormatAdapter(
        maxSupportedFormatVersion: 1,
      );
      expect(
        () => adapter.parseHeader(<String, dynamic>{
          'type': 'sessionHeader',
          'formatVersion': 9,
          'sessionId': 'sess',
          'startedAt': '2024-01-01T00:00:00Z',
        }),
        throwsFormatException,
      );
    });

    test('parses event and marker records with adapters', () {
      final UyavaSessionEventRecord event = UyavaSessionEventRecord(
        type: 'snapshot.replaceGraph',
        timestamp: DateTime.utc(2024, 2, 1, 10, 0, 0),
        monotonicMicros: 1234,
        payload: const <String, Object?>{'nodes': 1},
        scope: 'snapshot',
        sequenceId: 'snapshot-1',
        redactedKeys: const <String>['rawData'],
        hostMetadata: const <String, Object?>{'tz': 'UTC'},
      );
      final UyavaSessionMarkerRecord marker = UyavaSessionMarkerRecord(
        id: 'm1',
        label: 'Error marker',
        timestamp: DateTime.utc(2024, 2, 1, 10, 0, 1),
        offsetMicros: 1,
        kind: 'error',
        level: 'error',
        meta: const <String, Object?>{'code': 'E001'},
      );

      final UyavaSessionFormatAdapter adapter = UyavaSessionFormatAdapter();

      final ParsedUyavaSessionRecord parsedEvent = adapter.parseRecord(
        Map<String, dynamic>.from(event.toJson()),
      );
      expect(parsedEvent.kind, UyavaSessionRecordKind.event);
      expect(parsedEvent.event?.type, 'snapshot.replaceGraph');
      expect(parsedEvent.event?.monotonicMicros, 1234);
      expect(parsedEvent.event?.payload['nodes'], 1);
      expect(parsedEvent.event?.redactedKeys, contains('rawData'));
      expect(parsedEvent.event?.hostMetadata['tz'], 'UTC');

      final ParsedUyavaSessionRecord parsedMarker = adapter.parseRecord(
        Map<String, dynamic>.from(marker.toJson()),
      );
      expect(parsedMarker.kind, UyavaSessionRecordKind.marker);
      expect(parsedMarker.marker?.label, 'Error marker');
      expect(parsedMarker.marker?.kind, 'error');
      expect(parsedMarker.marker?.meta['code'], 'E001');
    });
  });
}
