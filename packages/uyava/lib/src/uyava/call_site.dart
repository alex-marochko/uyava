part of 'package:uyava/uyava.dart';

/// Captures the first external Dart frame (package:/file:) outside the Uyava SDK
/// and returns a compact 'uri:line:column' string. Falls back to null on failure.
String? _captureCallSite({int extraSkip = 0}) {
  // Disable in product/release builds to avoid overhead and leaking file paths.
  const bool isProduct = bool.fromEnvironment('dart.vm.product');
  if (isProduct) return null;
  final raw = StackTrace.current.toString();
  final lines = raw.split('\n');
  final pattern = RegExp(r'((?:package|file):[^\s\)]+):(\d+):(\d+)');
  var seenExternal = 0;
  for (final l in lines) {
    final line = l.trim();
    if (line.isEmpty) continue;
    final m = pattern.firstMatch(line);
    if (m != null) {
      final uri = m.group(1) ?? '';
      // Skip frames that belong to this SDK library.
      if (uri.contains('package:uyava/')) continue;
      if (uri.contains('/packages/uyava/lib/')) continue;
      // Honor additional skip across non-Uyava frames (e.g., adapters).
      if (seenExternal < extraSkip) {
        seenExternal++;
        continue;
      }
      final ln = m.group(2);
      final col = m.group(3);
      return '$uri:${ln ?? '?'}:${col ?? '?'}';
    }
  }
  return null;
}
