/// Severity levels for graph diagnostics emitted by Uyava.
///
/// These map to UI affordances (icons/color) in DevTools/Desktop.
enum UyavaDiagnosticLevel { info, warning, error }

extension UyavaDiagnosticLevelWire on UyavaDiagnosticLevel {
  /// Wire-friendly string representation (lowercase enum name).
  String toWireString() => name;
}

UyavaDiagnosticLevel? uyavaDiagnosticLevelFromWire(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final level in UyavaDiagnosticLevel.values) {
    if (level.name == value) return level;
  }
  return null;
}
