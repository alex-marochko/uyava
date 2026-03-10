import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:uyava_core/uyava_core.dart';

const String kDefaultPanelLayoutSchemaId = 'uyava.panels.layout.v1';
const String kDefaultFiltersSchemaId = GraphFilterStateCodec.schemaId;

/// Orientation of a split section within the panel shell.
enum UyavaPanelSplitAxis { horizontal, vertical }

/// Base class for a slot entry inside the panel shell specification.
sealed class UyavaPanelSlot {
  const UyavaPanelSlot();

  /// Visits the slot using the provided callbacks.
  T map<T>({
    required T Function(UyavaPanelLeaf leaf) leaf,
    required T Function(UyavaPanelSplit split) split,
  });
}

/// A slot occupied by a concrete panel.
class UyavaPanelLeaf extends UyavaPanelSlot {
  const UyavaPanelLeaf(this.id);

  final UyavaPanelId id;

  @override
  T map<T>({
    required T Function(UyavaPanelLeaf leaf) leaf,
    required T Function(UyavaPanelSplit split) split,
  }) {
    return leaf(this);
  }
}

/// A split section that nests other slots.
class UyavaPanelSplit extends UyavaPanelSlot {
  UyavaPanelSplit({
    required this.key,
    required this.axis,
    required this.children,
  }) : assert(children.length >= 2, 'Split requires at least two children.'),
       assert(key.isNotEmpty, 'Split key must not be empty.');

  final String key;
  final UyavaPanelSplitAxis axis;
  final List<UyavaPanelSlot> children;

  @override
  T map<T>({
    required T Function(UyavaPanelLeaf leaf) leaf,
    required T Function(UyavaPanelSplit split) split,
  }) {
    return split(this);
  }
}

/// Immutable specification describing default panel arrangement.
@immutable
class UyavaPanelShellSpec {
  const UyavaPanelShellSpec({required this.root});

  final UyavaPanelSlot root;
}

/// Identifies a panel within the shared shell layout.
@immutable
class UyavaPanelId {
  const UyavaPanelId(this.value);

  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UyavaPanelId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Visibility state understood by the shared layout engine.
enum UyavaPanelVisibility { visible, hidden }

/// Persisted information about a single panel instance in the layout.
@immutable
class UyavaPanelLayoutEntry {
  UyavaPanelLayoutEntry({
    required this.id,
    this.visibility,
    this.order,
    this.splitFraction,
    Map<String, Object?>? extraState,
  }) : extraState = extraState == null ? null : Map.unmodifiable(extraState);

  final UyavaPanelId id;
  final UyavaPanelVisibility? visibility;

  /// Ordering hint (lower values appear earlier). Null falls back to defaults.
  final int? order;

  /// Fractional size along the parent split (0-1). Null uses shell defaults.
  final double? splitFraction;

  /// Optional bag for panel-specific persisted state.
  final Map<String, Object?>? extraState;

  static final _equality = MapEquality<String, Object?>();

  UyavaPanelLayoutEntry copyWith({
    UyavaPanelVisibility? visibility,
    int? order,
    double? splitFraction,
    Map<String, Object?>? extraState,
  }) {
    return UyavaPanelLayoutEntry(
      id: id,
      visibility: visibility ?? this.visibility,
      order: order ?? this.order,
      splitFraction: splitFraction ?? this.splitFraction,
      extraState: extraState ?? this.extraState,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UyavaPanelLayoutEntry) return false;
    return id == other.id &&
        visibility == other.visibility &&
        order == other.order &&
        splitFraction == other.splitFraction &&
        _equality.equals(extraState, other.extraState);
  }

  @override
  int get hashCode {
    final extra = extraState;
    final extraHash = extra == null ? null : _equality.hash(extra);
    return Object.hash(id, visibility, order, splitFraction, extraHash);
  }
}

/// Collection of persisted entries alongside focus metadata.
@immutable
class UyavaPanelLayoutState {
  UyavaPanelLayoutState({
    required List<UyavaPanelLayoutEntry> entries,
    Map<String, double>? splitFractions,
    this.focusedPanel,
    this.configurationId,
    this.layoutSchemaId = kDefaultPanelLayoutSchemaId,
    this.filtersSchemaId = kDefaultFiltersSchemaId,
  }) : entries = List.unmodifiable(entries),
       splitFractions = splitFractions == null
           ? const {}
           : Map.unmodifiable(splitFractions);

  final List<UyavaPanelLayoutEntry> entries;
  final Map<String, double> splitFractions;
  final UyavaPanelId? focusedPanel;
  final String? configurationId;
  final String layoutSchemaId;
  final String filtersSchemaId;

  static final _listEquality = ListEquality<UyavaPanelLayoutEntry>();
  static final _mapEquality = MapEquality<String, double>();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UyavaPanelLayoutState) return false;
    return focusedPanel == other.focusedPanel &&
        configurationId == other.configurationId &&
        layoutSchemaId == other.layoutSchemaId &&
        filtersSchemaId == other.filtersSchemaId &&
        _listEquality.equals(entries, other.entries) &&
        _mapEquality.equals(splitFractions, other.splitFractions);
  }

  @override
  int get hashCode => Object.hash(
    focusedPanel,
    configurationId,
    layoutSchemaId,
    filtersSchemaId,
    _listEquality.hash(entries),
    _mapEquality.hash(splitFractions),
  );
}

/// Logical size used by hosts that need minimum panel constraints.
@immutable
class UyavaPanelSize {
  const UyavaPanelSize({required this.width, required this.height})
    : assert(width >= 0),
      assert(height >= 0);

  final double width;
  final double height;

  static const zero = UyavaPanelSize(width: 0, height: 0);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UyavaPanelSize) return false;
    return width == other.width && height == other.height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

/// Immutable registry entry describing a panel from the controller perspective.
@immutable
class UyavaPanelRegistryEntry {
  UyavaPanelRegistryEntry({
    required this.id,
    required this.title,
    this.defaultVisibility = UyavaPanelVisibility.visible,
    this.supportsResize = true,
    this.minimumSize = const UyavaPanelSize(width: 320, height: 240),
    Map<String, Object?>? metadata,
  }) : metadata = Map.unmodifiable(metadata ?? const <String, Object?>{});

  final UyavaPanelId id;
  final String title;
  final UyavaPanelVisibility defaultVisibility;
  final bool supportsResize;
  final UyavaPanelSize minimumSize;
  final Map<String, Object?> metadata;

  static final _mapEquality = MapEquality<String, Object?>();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UyavaPanelRegistryEntry) return false;
    return id == other.id &&
        title == other.title &&
        defaultVisibility == other.defaultVisibility &&
        supportsResize == other.supportsResize &&
        minimumSize == other.minimumSize &&
        _mapEquality.equals(metadata, other.metadata);
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    defaultVisibility,
    supportsResize,
    minimumSize,
    _mapEquality.hash(metadata),
  );
}

/// Snapshot that bundles structural spec and layout state.
@immutable
class UyavaPanelShellSnapshot {
  const UyavaPanelShellSnapshot({required this.spec, required this.state});

  final UyavaPanelShellSpec spec;
  final UyavaPanelLayoutState state;
}

/// Adapter that renders controller updates into a concrete panel shell view.
abstract class UyavaPanelShellViewAdapter {
  /// Called whenever the controller applies a new [snapshot]. Hosts should
  /// render or propagate the layout in response.
  void didUpdateSnapshot(UyavaPanelShellSnapshot snapshot);

  /// Called after the controller persists layout state. Default implementation
  /// does nothing; hosts can override to perform storage or analytics.
  void handlePersistedState(UyavaPanelLayoutState state) {}

  /// Called when the controller disposes and the adapter should release
  /// associated resources. Default implementation is a no-op.
  void handleControllerDisposed() {}
}
