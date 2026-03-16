part of '../file_logger.dart';

Map<String, Object?> buildRuntimeErrorPayload({
  required String source,
  required Object error,
  required StackTrace stackTrace,
  bool isFatal = true,
  String? level,
  String? message,
  String? zoneDescription,
  Map<String, Object?>? context,
}) {
  return <String, Object?>{
    'level': level ?? (isFatal ? 'fatal' : 'error'),
    'errorType': error.runtimeType.toString(),
    'message': message ?? error.toString(),
    'stackTrace': stackTrace.toString(),
    'isFatal': isFatal,
    'source': source,
    if (zoneDescription != null && zoneDescription.isNotEmpty)
      'zone': zoneDescription,
    'platform': Platform.operatingSystem,
    'pid': pid,
    'isolate': Isolate.current.debugName ?? Isolate.current.hashCode,
    if (context != null && context.isNotEmpty) 'context': context,
  };
}
