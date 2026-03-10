import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Describes an individual child inside a [UyavaSplitView].
class UyavaSplitChild {
  const UyavaSplitChild({
    required this.child,
    this.minimumSize = 0,
    this.canResize = true,
    this.key,
  }) : assert(minimumSize >= 0, 'minimumSize must be >= 0');

  final Widget child;
  final double minimumSize;
  final bool canResize;
  final Key? key;
}

/// Shared resizable split view used by Uyava hosts to lay out persistent panes.
class UyavaSplitView extends StatefulWidget {
  const UyavaSplitView({
    super.key,
    required this.axis,
    required this.children,
    this.initialFractions,
    this.onFractionsChanged,
    this.handleThickness = 8,
    this.handleExtent = 48,
    this.keyboardStep = 0.04,
    this.handleColor,
    this.resetOnDoubleTap = true,
  }) : assert(children.length >= 2, 'SplitView requires at least two panes.'),
       assert(
         initialFractions == null || initialFractions.length == children.length,
         'initialFractions length must match children length.',
       );

  /// Axis along which the split occurs.
  final Axis axis;

  /// Panels rendered by the split view.
  final List<UyavaSplitChild> children;

  /// Optional starting fractions for every child. Values are normalized so
  /// their sum equals 1. When omitted, panes are sized evenly.
  final List<double>? initialFractions;

  /// Invoked whenever the user resizes panes (via drag or keyboard).
  final ValueChanged<List<double>>? onFractionsChanged;

  /// Thickness of the draggable handle separating adjacent panes.
  final double handleThickness;

  /// Visual extent of the handle along the cross axis.
  final double handleExtent;

  /// Fractional step applied when using keyboard arrow keys to resize.
  final double keyboardStep;

  /// Optional override for the handle color. Defaults to on-surface variants.
  final Color? handleColor;

  /// Whether double-tapping a handle resets the layout to the initial fractions.
  final bool resetOnDoubleTap;

  @override
  State<UyavaSplitView> createState() => _UyavaSplitViewState();
}

class _UyavaSplitViewState extends State<UyavaSplitView> {
  static const _fractionsComparer = ListEquality<double>();

  late List<double> _fractions;
  late List<double> _initialFractions;
  late List<FocusNode> _handleFocusNodes;
  double _layoutExtent = 0;

  @override
  void initState() {
    super.initState();
    _fractions = _normalizeFractions(
      widget.initialFractions ?? _evenFractions(widget.children.length),
    );
    _initialFractions = List<double>.of(_fractions);
    _handleFocusNodes = List.generate(
      widget.children.length - 1,
      (_) => FocusNode(debugLabel: 'SplitHandle'),
    );
  }

  @override
  void didUpdateWidget(covariant UyavaSplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _fractions = _normalizeFractions(
        widget.initialFractions ?? _evenFractions(widget.children.length),
      );
      _initialFractions = List<double>.of(_fractions);
      for (final node in _handleFocusNodes) {
        node.dispose();
      }
      _handleFocusNodes = List.generate(
        widget.children.length - 1,
        (_) => FocusNode(debugLabel: 'SplitHandle'),
      );
    } else if (widget.initialFractions != null &&
        (oldWidget.initialFractions == null ||
            !_fractionsComparer.equals(
              widget.initialFractions!,
              oldWidget.initialFractions!,
            ))) {
      _fractions = _normalizeFractions(widget.initialFractions!);
      _initialFractions = List<double>.of(_fractions);
    }
  }

  @override
  void dispose() {
    for (final node in _handleFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        _layoutExtent = _mainAxisExtent(constraints);
        final children = <Widget>[];
        for (var i = 0; i < widget.children.length; i++) {
          children.add(_buildChild(widget.children[i], i));
          if (i < widget.children.length - 1) {
            children.add(
              _SplitHandle(
                key: ValueKey('uyavaSplitHandle-$i'),
                axis: widget.axis,
                focusNode: _handleFocusNodes[i],
                enabled:
                    widget.children[i].canResize &&
                    widget.children[i + 1].canResize,
                thickness: widget.handleThickness,
                extent: widget.handleExtent,
                color: widget.handleColor ?? scheme.outlineVariant,
                hoverColor: scheme.primary.withValues(alpha: 0.28),
                onDragUpdate: (delta) => _updateFractions(i, delta),
                onArrowStep: (direction) =>
                    _updateFractions(i, direction * _keyboardDelta()),
                onDoubleTap: widget.resetOnDoubleTap ? _resetFractions : null,
              ),
            );
          }
        }
        return Flex(
          direction: widget.axis,
          clipBehavior: Clip.hardEdge,
          children: children,
        );
      },
    );
  }

  Widget _buildChild(UyavaSplitChild child, int index) {
    final flex = math.max(1, (_fractions[index] * 1000).round());
    return Flexible(
      flex: flex,
      child: KeyedSubtree(key: child.key, child: child.child),
    );
  }

  void _updateFractions(int handleIndex, double delta) {
    if (_layoutExtent <= 0 ||
        _layoutExtent.isInfinite ||
        delta == 0 ||
        handleIndex < 0 ||
        handleIndex >= _fractions.length - 1) {
      return;
    }
    final double fractionDelta = delta / _layoutExtent;
    if (fractionDelta == 0) return;

    final leftIndex = handleIndex;
    final rightIndex = handleIndex + 1;
    final minLeft = _minimumFractionFor(leftIndex);
    final minRight = _minimumFractionFor(rightIndex);
    final otherSum =
        _fractions.fold<double>(0, (sum, value) => sum + value) -
        _fractions[leftIndex] -
        _fractions[rightIndex];

    var proposedLeft = (_fractions[leftIndex] + fractionDelta).clamp(
      minLeft,
      1 - (otherSum + minRight),
    );
    var proposedRight = 1 - otherSum - proposedLeft;

    if (proposedRight < minRight) {
      proposedRight = minRight;
      proposedLeft = (1 - otherSum - proposedRight).clamp(minLeft, 1);
    }

    if (proposedLeft < minLeft ||
        proposedRight < minRight ||
        (proposedLeft - _fractions[leftIndex]).abs() < 1e-6) {
      return;
    }
    setState(() {
      _fractions[leftIndex] = proposedLeft;
      _fractions[rightIndex] = proposedRight;
    });
    widget.onFractionsChanged?.call(List<double>.of(_fractions));
  }

  void _resetFractions() {
    setState(() {
      _fractions = List<double>.of(_initialFractions);
    });
    widget.onFractionsChanged?.call(List<double>.of(_fractions));
  }

  double _keyboardDelta() {
    if (_layoutExtent <= 0 || _layoutExtent.isInfinite) {
      return 0;
    }
    return widget.keyboardStep * _layoutExtent;
  }

  double _minimumFractionFor(int index) {
    if (_layoutExtent <= 0 || _layoutExtent.isInfinite) {
      return 0;
    }
    final minSize = widget.children[index].minimumSize;
    if (minSize <= 0) return 0;
    final fraction = minSize / _layoutExtent;
    return fraction.clamp(0.0, 1.0);
  }

  static List<double> _normalizeFractions(List<double> input) {
    final positive = input.where((value) => value > 0).toList();
    if (positive.isEmpty) {
      return _evenFractions(input.length);
    }
    final sum = positive.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) {
      return _evenFractions(input.length);
    }
    return [for (final value in input) value <= 0 ? 0 : value / sum];
  }

  static List<double> _evenFractions(int count) {
    if (count <= 0) {
      return const [];
    }
    final fraction = 1 / count;
    return List<double>.filled(count, fraction);
  }

  double _mainAxisExtent(BoxConstraints constraints) {
    double extent = widget.axis == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    if (extent.isFinite) {
      return extent;
    }
    extent = widget.axis == Axis.horizontal
        ? constraints.biggest.width
        : constraints.biggest.height;
    if (extent.isFinite) {
      return extent;
    }
    return 0;
  }
}

class _SplitHandle extends StatefulWidget {
  const _SplitHandle({
    super.key,
    required this.axis,
    required this.focusNode,
    required this.enabled,
    required this.thickness,
    required this.extent,
    required this.color,
    required this.hoverColor,
    required this.onDragUpdate,
    required this.onArrowStep,
    this.onDoubleTap,
  });

  final Axis axis;
  final FocusNode focusNode;
  final bool enabled;
  final double thickness;
  final double extent;
  final Color color;
  final Color hoverColor;
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onArrowStep;
  final VoidCallback? onDoubleTap;

  @override
  State<_SplitHandle> createState() => _SplitHandleState();
}

class _SplitHandleState extends State<_SplitHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cursor = widget.axis == Axis.horizontal
        ? SystemMouseCursors.resizeLeftRight
        : SystemMouseCursors.resizeUpDown;
    final size = widget.axis == Axis.horizontal
        ? Size(widget.thickness, widget.extent)
        : Size(widget.extent, widget.thickness);
    final handle = Container(
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.axis == Axis.horizontal ? 2 : size.width * 0.6,
        height: widget.axis == Axis.horizontal ? size.height * 0.6 : 2,
        decoration: BoxDecoration(
          color: widget.enabled
              ? (_hovered ? widget.hoverColor : widget.color)
              : widget.color.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.all(Radius.circular(999)),
        ),
      ),
    );
    return MouseRegion(
      cursor: widget.enabled ? cursor : SystemMouseCursors.basic,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: Focus(
        focusNode: widget.focusNode,
        canRequestFocus: widget.enabled,
        onKeyEvent: (node, event) {
          if (!widget.enabled || event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          final isHorizontal = widget.axis == Axis.horizontal;
          if (isHorizontal &&
              (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                  event.logicalKey == LogicalKeyboardKey.arrowRight)) {
            final direction = event.logicalKey == LogicalKeyboardKey.arrowLeft
                ? -1
                : 1;
            widget.onArrowStep(direction.toDouble());
            return KeyEventResult.handled;
          }
          if (!isHorizontal &&
              (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                  event.logicalKey == LogicalKeyboardKey.arrowDown)) {
            final direction = event.logicalKey == LogicalKeyboardKey.arrowUp
                ? -1
                : 1;
            widget.onArrowStep(direction.toDouble());
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) {
            if (widget.enabled) {
              widget.focusNode.requestFocus();
            }
          },
          onHorizontalDragStart:
              widget.axis == Axis.horizontal && widget.enabled
              ? (_) => widget.focusNode.requestFocus()
              : null,
          onVerticalDragStart: widget.axis == Axis.vertical && widget.enabled
              ? (_) => widget.focusNode.requestFocus()
              : null,
          onDoubleTap: widget.onDoubleTap,
          onHorizontalDragUpdate:
              widget.axis == Axis.horizontal && widget.enabled
              ? (details) => widget.onDragUpdate(details.primaryDelta ?? 0)
              : null,
          onVerticalDragUpdate: widget.axis == Axis.vertical && widget.enabled
              ? (details) => widget.onDragUpdate(details.primaryDelta ?? 0)
              : null,
          child: Semantics(
            label: 'Resize panels',
            enabled: widget.enabled,
            child: SizedBox.fromSize(size: size, child: handle),
          ),
        ),
      ),
    );
  }

  void _setHover(bool value) {
    if (_hovered == value) return;
    setState(() {
      _hovered = value;
    });
  }
}
