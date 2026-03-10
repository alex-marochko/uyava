part of 'package:uyava/uyava.dart';

UyavaConsoleLogRecord? _consoleRecordFromTransport(UyavaTransportEvent event) {
  if (event.type == UyavaEventTypes.graphDiagnostics) {
    return _consoleRecordFromDiagnosticEvent(event);
  }

  final Map<String, Object?> context = <String, Object?>{
    'scope': event.scope.name,
    if (event.sequenceId != null) 'sequenceId': event.sequenceId,
  };

  if (event.payload.isNotEmpty) {
    context['payload'] = event.payload;
  }

  final UyavaSeverity severity =
      _eventSeverity(event) ?? _severityForScope(event.scope);

  return UyavaConsoleLogRecord(
    timestamp: event.timestamp,
    severity: severity,
    type: event.type,
    subjects: _extractSubjects(event.payload),
    context: context,
  );
}

UyavaConsoleLogRecord _consoleRecordFromDiagnosticEvent(
  UyavaTransportEvent event,
) {
  final Map<String, dynamic> payload = event.payload;
  final UyavaDiagnosticLevel diagnosticLevel =
      uyavaDiagnosticLevelFromWire(payload['level'] as String?) ??
      UyavaDiagnosticLevel.warning;

  final String? codeEnum = payload['codeEnum'] as String?;
  final String? codeWire = payload['code'] as String?;
  final String? resolvedCode = (codeEnum != null && codeEnum.isNotEmpty)
      ? codeEnum
      : codeWire;

  final List<String> subjects = <String>[];
  final String? nodeId = payload['nodeId'] as String?;
  if (nodeId != null && nodeId.isNotEmpty) {
    subjects.add(nodeId);
  }
  final String? edgeId = payload['edgeId'] as String?;
  if (edgeId != null && edgeId.isNotEmpty) {
    subjects.add(edgeId);
  }

  final Map<String, Object?> context = <String, Object?>{
    'scope': event.scope.name,
    if (event.sequenceId != null) 'sequenceId': event.sequenceId,
  };

  final Map<String, dynamic>? rawContext =
      payload['context'] as Map<String, dynamic>?;
  if (rawContext != null && rawContext.isNotEmpty) {
    rawContext.forEach((key, value) {
      context[key] = value;
    });
  }

  return UyavaConsoleLogRecord(
    timestamp: event.timestamp,
    severity: _diagnosticSeverity(diagnosticLevel),
    type: event.type,
    code: resolvedCode,
    subjects: List<String>.unmodifiable(subjects),
    context: context,
  );
}

UyavaSeverity _diagnosticSeverity(UyavaDiagnosticLevel level) {
  switch (level) {
    case UyavaDiagnosticLevel.info:
      return UyavaSeverity.info;
    case UyavaDiagnosticLevel.warning:
      return UyavaSeverity.warn;
    case UyavaDiagnosticLevel.error:
      return UyavaSeverity.error;
  }
}

UyavaSeverity? _eventSeverity(UyavaTransportEvent event) {
  final UyavaSeverity? payloadSeverity = _parseSeverity(
    event.payload['severity'],
  );
  if (payloadSeverity != null) {
    return payloadSeverity;
  }
  return _parseSeverity(event.payload['level']);
}

UyavaSeverity? _parseSeverity(Object? raw) {
  if (raw == null) {
    return null;
  }
  final String normalized = raw.toString().trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  for (final UyavaSeverity candidate in UyavaSeverity.values) {
    if (candidate.name == normalized) {
      return candidate;
    }
  }
  return null;
}

UyavaSeverity _severityForScope(UyavaTransportScope scope) {
  switch (scope) {
    case UyavaTransportScope.realtime:
      return UyavaSeverity.info;
    case UyavaTransportScope.snapshot:
      return UyavaSeverity.debug;
    case UyavaTransportScope.diagnostic:
      return UyavaSeverity.info;
  }
}

List<String> _extractSubjects(Map<String, dynamic> payload) {
  final LinkedHashSet<String> subjects = LinkedHashSet<String>();

  void addSubject(dynamic value) {
    if (value is String && value.isNotEmpty) {
      subjects.add(value);
    } else if (value is Iterable) {
      for (final dynamic item in value) {
        if (item is String && item.isNotEmpty) {
          subjects.add(item);
        }
      }
    }
  }

  addSubject(payload['id']);
  addSubject(payload['nodeId']);
  addSubject(payload['edgeId']);
  addSubject(payload['source']);
  addSubject(payload['target']);
  addSubject(payload['nodes']);
  addSubject(payload['edges']);

  return List<String>.unmodifiable(subjects);
}
