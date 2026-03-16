import 'package:uyava/uyava.dart';

UyavaLogArchive buildArchive({
  String fileName = 'uyava_001.uyava',
  int sizeBytes = 1024,
  DateTime? startedAt,
  DateTime? completedAt,
  String? path,
  String? sourcePath,
}) {
  final DateTime now = DateTime.now();
  return UyavaLogArchive(
    path: path ?? '/tmp/$fileName',
    fileName: fileName,
    sizeBytes: sizeBytes,
    startedAt: startedAt ?? now.subtract(const Duration(minutes: 1)),
    completedAt: completedAt ?? now,
    sourcePath: sourcePath,
  );
}

UyavaLogArchiveEvent buildArchiveEvent({
  UyavaLogArchiveEventKind kind = UyavaLogArchiveEventKind.rotation,
  UyavaLogArchive? archive,
}) {
  return UyavaLogArchiveEvent(kind: kind, archive: archive ?? buildArchive());
}

UyavaDiscardStats buildDiscardStats({
  int total = 3,
  String? lastReason,
  DateTime? updatedAt,
  Map<String, int>? reasons,
}) {
  return UyavaDiscardStats(
    totalCount: total,
    lastReason: lastReason,
    updatedAt: updatedAt ?? DateTime.now(),
    reasonCounts: reasons ?? const {'realtime_sampling': 2, 'max_rate': 1},
  );
}
