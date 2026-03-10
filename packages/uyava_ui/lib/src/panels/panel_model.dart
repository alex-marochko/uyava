import 'package:flutter/widgets.dart';

import 'panel_contract.dart';

/// Callback that builds the visual contents of a panel.
typedef UyavaPanelBuilder =
    Widget Function(BuildContext context, UyavaPanelContext panelContext);

/// Rich context passed to every panel builder.
@immutable
class UyavaPanelContext {
  const UyavaPanelContext({
    required this.hasFocus,
    required this.availableSize,
  });

  /// Whether the panel currently owns user focus (e.g. last clicked).
  final bool hasFocus;

  /// The logical size allocated to the panel inside the layout.
  final Size availableSize;
}

/// Static metadata describing a panel that can be placed in the shell.
@immutable
class UyavaPanelDefinition {
  const UyavaPanelDefinition({
    required this.id,
    required this.title,
    required this.builder,
    this.minimumSize = const Size(320, 240),
    this.supportsResize = true,
    this.defaultVisibility = UyavaPanelVisibility.visible,
    this.metadata = const <String, Object?>{},
    this.fillAvailableSpace = true,
  });

  final UyavaPanelId id;
  final String title;
  final UyavaPanelBuilder builder;

  /// Smallest logical size that keeps the panel usable.
  final Size minimumSize;

  /// Whether the panel can participate in user-driven resizing.
  final bool supportsResize;

  /// Whether the panel surface should expand to fill allocated space.
  final bool fillAvailableSpace;

  /// Default visibility when no persisted layout is available.
  final UyavaPanelVisibility defaultVisibility;

  /// Optional metadata that hosts can reuse for labels, badges, etc.
  final Map<String, Object?> metadata;

  /// Converts the definition into a controller registry entry.
  UyavaPanelRegistryEntry toRegistryEntry() {
    return UyavaPanelRegistryEntry(
      id: id,
      title: title,
      defaultVisibility: defaultVisibility,
      supportsResize: supportsResize,
      minimumSize: UyavaPanelSize(
        width: minimumSize.width,
        height: minimumSize.height,
      ),
      metadata: metadata,
    );
  }
}
