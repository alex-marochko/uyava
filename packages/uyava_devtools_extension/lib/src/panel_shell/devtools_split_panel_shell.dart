import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:devtools_app_shared/ui.dart' as devtools_ui;
import 'package:flutter/material.dart';
import 'package:uyava_ui/uyava_ui.dart';

/// Panel shell implementation for the DevTools host that renders controller
/// state using the shared DevTools [SplitPane] widget.
///
/// Persistence is delegated to the surrounding
/// [UyavaPanelShellController]; this widget focuses on translating snapshot
/// updates into the DevTools UI and forwarding user interactions (focus,
/// resize) back to the controller.
class DevToolsSplitPanelShell extends StatefulWidget {
  const DevToolsSplitPanelShell({
    super.key,
    required this.controller,
    required this.definitions,
  });

  final UyavaPanelShellController controller;
  final List<UyavaPanelDefinition> definitions;

  @override
  State<DevToolsSplitPanelShell> createState() =>
      _DevToolsSplitPanelShellState();
}

class _DevToolsSplitPanelShellState extends State<DevToolsSplitPanelShell> {
  late Map<UyavaPanelId, UyavaPanelDefinition> _definitionsById;
  late UyavaPanelShellSnapshot _snapshot;
  int _snapshotVersion = 0;

  @override
  void initState() {
    super.initState();
    _definitionsById = _buildDefinitionMap(widget.definitions);
    _snapshot = widget.controller.snapshot;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant DevToolsSplitPanelShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _snapshot = widget.controller.snapshot;
      _snapshotVersion++;
    }
    if (!identical(oldWidget.definitions, widget.definitions)) {
      _definitionsById = _buildDefinitionMap(widget.definitions);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    setState(() {
      _snapshot = widget.controller.snapshot;
      _snapshotVersion++;
    });
  }

  Map<UyavaPanelId, UyavaPanelDefinition> _buildDefinitionMap(
    List<UyavaPanelDefinition> definitions,
  ) {
    return {for (final definition in definitions) definition.id: definition};
  }

  UyavaPanelDefinition? _definitionFor(UyavaPanelId id) => _definitionsById[id];

  @override
  Widget build(BuildContext context) {
    return _buildSlot(context, _snapshot.spec.root);
  }

  Widget _buildSlot(BuildContext context, UyavaPanelSlot slot) {
    return slot.map(
      leaf: (leaf) => _buildLeaf(context, leaf),
      split: (split) => _buildSplit(context, split),
    );
  }

  Widget _buildLeaf(BuildContext context, UyavaPanelLeaf leaf) {
    final definition = _definitionFor(leaf.id);
    if (definition == null) {
      return const SizedBox.shrink();
    }
    final visibility = widget.controller.visibilityFor(leaf.id);
    if (visibility == UyavaPanelVisibility.hidden) {
      return const SizedBox.shrink();
    }
    return _PanelLeaf(
      controller: widget.controller,
      snapshot: _snapshot,
      definition: definition,
      id: leaf.id,
    );
  }

  Widget _buildSplit(BuildContext context, UyavaPanelSplit split) {
    final children = <_SplitChild>[];
    final axis = split.axis == UyavaPanelSplitAxis.horizontal
        ? Axis.horizontal
        : Axis.vertical;
    for (final child in split.children) {
      if (!_slotHasVisiblePanels(child)) {
        continue;
      }
      children.add(
        _SplitChild(
          slot: child,
          child: _buildSlot(context, child),
          supportsResize: _slotSupportsResize(child),
          minimumWidth: _minimumExtent(child, axis: Axis.horizontal),
          minimumHeight: _minimumExtent(child, axis: Axis.vertical),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    if (children.length == 1) {
      return children.single.child;
    }

    return _SplitPane(
      controller: widget.controller,
      children: children,
      axis: axis,
      snapshotVersion: _snapshotVersion,
    );
  }

  bool _slotHasVisiblePanels(UyavaPanelSlot slot) {
    return slot.map(
      leaf: (leaf) {
        final definition = _definitionFor(leaf.id);
        if (definition == null) {
          return false;
        }
        return widget.controller.visibilityFor(leaf.id) ==
            UyavaPanelVisibility.visible;
      },
      split: (split) {
        for (final child in split.children) {
          if (_slotHasVisiblePanels(child)) {
            return true;
          }
        }
        return false;
      },
    );
  }

  bool _slotSupportsResize(UyavaPanelSlot slot) {
    return slot.map(
      leaf: (leaf) {
        final registry = widget.controller.registryFor(leaf.id);
        if (registry != null) {
          return registry.supportsResize;
        }
        return _definitionFor(leaf.id)?.supportsResize ?? false;
      },
      split: (split) {
        var hasVisible = false;
        for (final child in split.children) {
          if (!_slotHasVisiblePanels(child)) {
            continue;
          }
          hasVisible = true;
          if (!_slotSupportsResize(child)) {
            return false;
          }
        }
        return hasVisible;
      },
    );
  }

  double _minimumExtent(UyavaPanelSlot slot, {required Axis axis}) {
    return slot.map(
      leaf: (leaf) {
        final registry = widget.controller.registryFor(leaf.id);
        if (registry != null) {
          final size = registry.minimumSize;
          return axis == Axis.horizontal ? size.width : size.height;
        }
        final definition = _definitionFor(leaf.id);
        if (definition == null) {
          return 0;
        }
        return axis == Axis.horizontal
            ? definition.minimumSize.width
            : definition.minimumSize.height;
      },
      split: (split) {
        final extents = <double>[];
        for (final child in split.children) {
          if (!_slotHasVisiblePanels(child)) {
            continue;
          }
          extents.add(_minimumExtent(child, axis: axis));
        }
        if (extents.isEmpty) {
          return 0;
        }
        return extents.reduce(math.max);
      },
    );
  }
}

class _PanelLeaf extends StatelessWidget {
  const _PanelLeaf({
    required this.controller,
    required this.snapshot,
    required this.definition,
    required this.id,
  });

  final UyavaPanelShellController controller;
  final UyavaPanelShellSnapshot snapshot;
  final UyavaPanelDefinition definition;
  final UyavaPanelId id;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : definition.minimumSize.width,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : definition.minimumSize.height,
        );
        final panelContext = UyavaPanelContext(
          hasFocus: snapshot.state.focusedPanel == id,
          availableSize: size,
        );
        final child = definition.builder(context, panelContext);
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final bool hasFocus = panelContext.hasFocus;
        final Color borderColor = hasFocus
            ? colorScheme.primary.withValues(alpha: 0.6)
            : colorScheme.outline.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.45 : 0.25,
              );
        final Color backgroundColor = colorScheme.surfaceContainerHighest
            .withValues(
              alpha: theme.brightness == Brightness.dark ? 0.18 : 0.6,
            );
        final BorderRadius borderRadius = BorderRadius.circular(12);
        final bool fillAvailableSpace = definition.fillAvailableSpace;
        final BoxConstraints panelConstraints = fillAvailableSpace
            ? const BoxConstraints.expand()
            : BoxConstraints(
                minWidth: size.width,
                maxWidth: size.width,
                minHeight: 0,
                maxHeight: size.height.isFinite ? size.height : double.infinity,
              );
        return Listener(
          onPointerDown: (_) => controller.setFocusedPanel(id),
          behavior: HitTestBehavior.deferToChild,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.fastOutSlowIn,
            constraints: panelConstraints,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _SplitChild {
  _SplitChild({
    required this.slot,
    required this.child,
    required this.supportsResize,
    required this.minimumWidth,
    required this.minimumHeight,
  });

  final UyavaPanelSlot slot;
  final Widget child;
  final bool supportsResize;
  final double minimumWidth;
  final double minimumHeight;

  double minimumExtentFor(Axis axis) =>
      axis == Axis.horizontal ? minimumWidth : minimumHeight;
}

class _SplitPane extends StatefulWidget {
  const _SplitPane({
    required this.controller,
    required this.children,
    required this.axis,
    required this.snapshotVersion,
  });

  final UyavaPanelShellController controller;
  final List<_SplitChild> children;
  final Axis axis;
  final int snapshotVersion;

  @override
  State<_SplitPane> createState() => _SplitPaneState();
}

class _SplitPaneState extends State<_SplitPane> {
  static const double _kMinFraction = 0.05;

  final ListEquality<double> _doubleListEquality = const ListEquality();
  final ListEquality<bool> _boolListEquality = const ListEquality();
  GlobalKey<State<devtools_ui.SplitPane>> _splitKey =
      GlobalKey<State<devtools_ui.SplitPane>>();
  Object? _structureSignature;

  List<double> _fractions = const <double>[];
  List<double> _minSizes = const <double>[];
  List<bool> _handleEnabled = const <bool>[];

  @override
  void initState() {
    super.initState();
    _updateInputs(scheduleSetState: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyFractionsToSplitPane();
    });
  }

  @override
  void didUpdateWidget(covariant _SplitPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateInputs(scheduleSetState: true);
  }

  void _updateInputs({required bool scheduleSetState}) {
    final normalized = _normalizedFractions(widget.controller, widget.children);
    final minSizes = [
      for (final child in widget.children)
        child.minimumExtentFor(widget.axis).clamp(0.0, double.infinity),
    ];
    final handles = _computeHandleMask(widget.children);
    final Object newStructureSignature = _structureSignatureFor(
      widget.axis,
      widget.children,
    );

    final bool fractionsChanged = !_doubleListEquality.equals(
      _fractions,
      normalized,
    );
    final bool minChanged = !_doubleListEquality.equals(_minSizes, minSizes);
    final bool handlesChanged = !_boolListEquality.equals(
      _handleEnabled,
      handles,
    );
    final bool structureChanged = newStructureSignature != _structureSignature;

    if (!fractionsChanged &&
        !minChanged &&
        !handlesChanged &&
        !structureChanged) {
      return;
    }

    void assign() {
      _structureSignature = newStructureSignature;
      _fractions = normalized;
      _minSizes = minSizes;
      _handleEnabled = handles;
      if (structureChanged) {
        _splitKey = GlobalKey<State<devtools_ui.SplitPane>>();
      }
    }

    if (scheduleSetState) {
      setState(assign);
      if (fractionsChanged && !structureChanged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _applyFractionsToSplitPane();
        });
      }
    } else {
      assign();
    }
  }

  void _applyFractionsToSplitPane() {
    final State<StatefulWidget>? state = _splitKey.currentState;
    if (state == null) {
      return;
    }
    // Access the private SplitPane state to update its fractions in place.
    final dynamic splitPaneState = state;
    final List<double>? currentFractions =
        (splitPaneState.fractions as List<double>?);
    if (currentFractions == null ||
        currentFractions.length != _fractions.length) {
      splitPaneState.setState(() {
        splitPaneState.fractions = List<double>.from(_fractions);
      });
      return;
    }
    splitPaneState.setState(() {
      currentFractions
        ..clear()
        ..addAll(_fractions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = [for (final child in widget.children) child.child];
    final splitters = _buildSplitters();
    final Object structureKey =
        _structureSignature ??
        _structureSignatureFor(widget.axis, widget.children);

    return Listener(
      onPointerUp: (_) => _flushFractionsToController(),
      onPointerCancel: (_) => _flushFractionsToController(),
      child: KeyedSubtree(
        key: ValueKey<Object>(structureKey),
        child: devtools_ui.SplitPane(
          key: _splitKey,
          axis: widget.axis,
          initialFractions: _fractions,
          // Skip passing minSizes to avoid SplitPane assertions when the host
          // surface is smaller than the combined minimums (can happen in tests
          // with all panels visible by default).
          minSizes: null,
          splitters: splitters,
          children: children,
        ),
      ),
    );
  }

  void _flushFractionsToController() {
    final state = _splitKey.currentState;
    final fractionsDynamic =
        (state as dynamic)?.fractions as List<double>? ?? _fractions;
    final normalized = _normalizeList(fractionsDynamic);
    const epsilon = 1e-4;

    for (var index = 0; index < widget.children.length; index++) {
      final slot = widget.children[index].slot;
      final current = widget.controller.splitFractionForSlot(
        slot,
        widget.children.length,
      );
      final next = normalized[index].clamp(_kMinFraction, 1.0);
      if ((current - next).abs() >= epsilon) {
        widget.controller.setSlotFraction(slot, next);
      }
    }
  }

  List<PreferredSizeWidget>? _buildSplitters() {
    if (widget.children.length <= 1) {
      return null;
    }
    final splitters = <PreferredSizeWidget>[];
    for (var index = 0; index < widget.children.length - 1; index++) {
      final enabled = _handleEnabled[index];
      splitters.add(_SplitHandle(axis: widget.axis, enabled: enabled));
    }
    return splitters;
  }

  static List<double> _normalizedFractions(
    UyavaPanelShellController controller,
    List<_SplitChild> children,
  ) {
    final count = children.length;
    if (count == 0) return const [];
    final raw = <double>[];
    for (final child in children) {
      final fraction = controller.splitFractionForSlot(child.slot, count);
      raw.add(fraction <= 0 ? 1.0 : fraction);
    }
    final total = raw.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return List<double>.filled(count, 1 / count);
    }
    return raw.map((value) => value / total).toList(growable: false);
  }

  static List<double> _normalizeList(List<double> fractions) {
    final total = fractions.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return List<double>.filled(fractions.length, 1 / fractions.length);
    }
    return fractions.map((value) => value / total).toList(growable: false);
  }

  static List<bool> _computeHandleMask(List<_SplitChild> children) {
    if (children.length <= 1) return const [];
    final mask = <bool>[];
    for (var i = 0; i < children.length - 1; i++) {
      final a = children[i];
      final b = children[i + 1];
      mask.add(a.supportsResize && b.supportsResize);
    }
    return mask;
  }

  static Object _structureSignatureFor(Axis axis, List<_SplitChild> children) {
    return Object.hashAll(<Object?>[
      axis,
      children.length,
      for (final child in children) child.slot,
    ]);
  }
}

class _SplitHandle extends StatelessWidget implements PreferredSizeWidget {
  const _SplitHandle({required this.axis, required this.enabled});

  final Axis axis;
  final bool enabled;

  @override
  Size get preferredSize => axis == Axis.horizontal
      ? const Size(devtools_ui.DefaultSplitter.splitterWidth, double.infinity)
      : const Size(double.infinity, devtools_ui.DefaultSplitter.splitterWidth);

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      final double width = axis == Axis.horizontal
          ? devtools_ui.DefaultSplitter.splitterWidth
          : double.infinity;
      final double height = axis == Axis.vertical
          ? devtools_ui.DefaultSplitter.splitterWidth
          : double.infinity;
      return SizedBox(width: width, height: height);
    }
    return devtools_ui.DefaultSplitter(isHorizontal: axis == Axis.horizontal);
  }
}
