import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'panel_contract.dart';
import 'panel_model.dart';
import 'panel_shell_controller.dart';
import 'split_view.dart';

/// Shared panel shell surface that renders [UyavaPanelShellController] state
/// using the reusable [UyavaSplitView] widget.
class UyavaPanelShellView extends StatefulWidget {
  const UyavaPanelShellView({
    super.key,
    required this.controller,
    required this.definitions,
    this.panelPadding = const EdgeInsets.all(8),
    this.onPanelTap,
  });

  final UyavaPanelShellController controller;
  final List<UyavaPanelDefinition> definitions;
  final EdgeInsets panelPadding;

  /// Optional hook invoked whenever a panel leaf is tapped.
  final ValueChanged<UyavaPanelId>? onPanelTap;

  @override
  State<UyavaPanelShellView> createState() => _UyavaPanelShellViewState();
}

class _UyavaPanelShellViewState extends State<UyavaPanelShellView> {
  late UyavaPanelShellSnapshot _snapshot;
  late Map<UyavaPanelId, UyavaPanelDefinition> _definitionsById;

  @override
  void initState() {
    super.initState();
    _definitionsById = _buildDefinitionMap(widget.definitions);
    _snapshot = widget.controller.snapshot;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant UyavaPanelShellView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _snapshot = widget.controller.snapshot;
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

  Map<UyavaPanelId, UyavaPanelDefinition> _buildDefinitionMap(
    List<UyavaPanelDefinition> definitions,
  ) {
    return {for (final definition in definitions) definition.id: definition};
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {
      _snapshot = widget.controller.snapshot;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildSlot(_snapshot.spec.root);
  }

  Widget _buildSlot(UyavaPanelSlot slot) {
    return slot.map(leaf: _buildLeaf, split: _buildSplit);
  }

  Widget _buildLeaf(UyavaPanelLeaf leaf) {
    final definition = _definitionsById[leaf.id];
    if (definition == null) {
      return const SizedBox.shrink();
    }
    if (widget.controller.visibilityFor(leaf.id) ==
        UyavaPanelVisibility.hidden) {
      return const SizedBox.shrink();
    }
    final hasFocus = widget.controller.state.focusedPanel == leaf.id;
    return _PanelSurface(
      id: leaf.id,
      definition: definition,
      controller: widget.controller,
      hasFocus: hasFocus,
      padding: widget.panelPadding,
      onTap: () {
        widget.controller.setFocusedPanel(leaf.id);
        widget.onPanelTap?.call(leaf.id);
      },
    );
  }

  Widget _buildSplit(UyavaPanelSplit split) {
    final visibleChildren = <UyavaPanelSlot>[];
    for (final child in split.children) {
      if (_slotHasVisiblePanels(child)) {
        visibleChildren.add(child);
      }
    }
    if (visibleChildren.isEmpty) {
      return const SizedBox.shrink();
    }
    if (visibleChildren.length == 1) {
      return _buildSlot(visibleChildren.first);
    }

    final axis = split.axis == UyavaPanelSplitAxis.horizontal
        ? Axis.horizontal
        : Axis.vertical;
    final fractions = [
      for (final child in visibleChildren)
        widget.controller.splitFractionForSlot(child, visibleChildren.length),
    ];

    return UyavaSplitView(
      axis: axis,
      initialFractions: fractions,
      onFractionsChanged: (updated) {
        for (var i = 0; i < visibleChildren.length; i++) {
          widget.controller.setSlotFraction(visibleChildren[i], updated[i]);
        }
      },
      children: [
        for (final child in visibleChildren)
          UyavaSplitChild(
            key: ValueKey('panel-slot-${_slotKey(child)}'),
            minimumSize: _minimumExtent(child, axis),
            canResize: _slotSupportsResize(child),
            child: _buildSlot(child),
          ),
      ],
    );
  }

  bool _slotHasVisiblePanels(UyavaPanelSlot slot) {
    return slot.map(
      leaf: (leaf) {
        if (_definitionsById[leaf.id] == null) {
          return false;
        }
        return widget.controller.visibilityFor(leaf.id) ==
            UyavaPanelVisibility.visible;
      },
      split: (split) => split.children.any(_slotHasVisiblePanels),
    );
  }

  bool _slotSupportsResize(UyavaPanelSlot slot) {
    return slot.map(
      leaf: (leaf) {
        final registry = widget.controller.registryFor(leaf.id);
        if (registry != null) {
          return registry.supportsResize;
        }
        return _definitionsById[leaf.id]?.supportsResize ?? true;
      },
      split: (split) {
        final visibleChildren = split.children
            .where(_slotHasVisiblePanels)
            .toList();
        if (visibleChildren.isEmpty) return false;
        for (final child in visibleChildren) {
          if (!_slotSupportsResize(child)) {
            return false;
          }
        }
        return true;
      },
    );
  }

  double _minimumExtent(UyavaPanelSlot slot, Axis axis) {
    return slot.map(
      leaf: (leaf) {
        final registry = widget.controller.registryFor(leaf.id);
        final UyavaPanelSize size =
            registry?.minimumSize ??
            UyavaPanelSize(
              width: _definitionsById[leaf.id]?.minimumSize.width ?? 0,
              height: _definitionsById[leaf.id]?.minimumSize.height ?? 0,
            );
        return axis == Axis.horizontal ? size.width : size.height;
      },
      split: (split) {
        final childAxis = split.axis == UyavaPanelSplitAxis.horizontal
            ? Axis.horizontal
            : Axis.vertical;
        final children = split.children.where(_slotHasVisiblePanels).toList();
        if (children.isEmpty) return 0;
        if (childAxis == axis) {
          var sum = 0.0;
          for (final child in children) {
            sum += _minimumExtent(child, axis);
          }
          return sum;
        }
        var maxExtent = 0.0;
        for (final child in children) {
          maxExtent = math.max(maxExtent, _minimumExtent(child, axis));
        }
        return maxExtent;
      },
    );
  }

  String _slotKey(UyavaPanelSlot slot) {
    return slot.map(
      leaf: (leaf) => 'panel:${leaf.id.value}',
      split: (split) => 'split:${split.key}',
    );
  }
}

class _PanelSurface extends StatelessWidget {
  const _PanelSurface({
    required this.id,
    required this.definition,
    required this.controller,
    required this.hasFocus,
    required this.padding,
    required this.onTap,
  });

  final UyavaPanelId id;
  final UyavaPanelDefinition definition;
  final UyavaPanelShellController controller;
  final bool hasFocus;
  final EdgeInsets padding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color borderColor = hasFocus
        ? scheme.primary
        : scheme.outlineVariant.withValues(alpha: 0.4);
    final borderWidth = hasFocus ? 2.0 : 1.0;
    return Padding(
      padding: padding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Focus(
              canRequestFocus: true,
              onFocusChange: (focused) {
                if (focused) {
                  controller.setFocusedPanel(id);
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final Size available = Size(
                    _finite(constraints.maxWidth),
                    _finite(constraints.maxHeight),
                  );
                  final panelContext = UyavaPanelContext(
                    hasFocus: hasFocus,
                    availableSize: available,
                  );
                  Widget child = definition.builder(context, panelContext);
                  if (definition.fillAvailableSpace) {
                    child = SizedBox.expand(child: child);
                  }
                  return child;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _finite(double value) {
    if (value.isFinite) return value;
    return 0;
  }
}
