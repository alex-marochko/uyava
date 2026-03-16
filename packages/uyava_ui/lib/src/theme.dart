import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';

/// A simple class to hold styling information for a node.
class NodeStyle {
  final Color color;
  final IconData icon;
  final ShapeBorder shape;

  const NodeStyle({
    required this.color,
    required this.icon,
    this.shape = const CircleBorder(),
  });
}

// A predefined map of styles for each standard node type.
final Map<String, NodeStyle> _standardStyles = {
  // UI Layer
  'widget': const NodeStyle(color: Colors.amber, icon: Icons.widgets),
  'screen': const NodeStyle(color: Colors.amber, icon: Icons.web_asset),

  // State Management
  'bloc': const NodeStyle(color: Colors.deepPurple, icon: Icons.sync_alt),
  'provider': const NodeStyle(color: Colors.deepPurple, icon: Icons.sync_alt),
  'riverpod': const NodeStyle(color: Colors.deepPurple, icon: Icons.sync_alt),
  'state': const NodeStyle(color: Colors.purple, icon: Icons.data_object),

  // Business Logic
  'service': const NodeStyle(
    color: Colors.teal,
    icon: Icons.miscellaneous_services,
  ),
  'repository': const NodeStyle(color: Colors.teal, icon: Icons.inventory_2),
  'usecase': const NodeStyle(color: Colors.cyan, icon: Icons.star_border),
  'manager': const NodeStyle(color: Colors.indigo, icon: Icons.settings),

  // Data Layer
  'database': const NodeStyle(color: Colors.blue, icon: Icons.storage),
  'api': const NodeStyle(color: Colors.lightBlue, icon: Icons.cloud_queue),
  'source': const NodeStyle(color: Colors.lightBlue, icon: Icons.source),
  'model': const NodeStyle(color: Colors.grey, icon: Icons.data_usage),

  // Messaging
  'stream': const NodeStyle(color: Colors.pink, icon: Icons.stream),
  'queue': const NodeStyle(
    color: Colors.pink,
    icon: Icons.format_list_numbered,
  ),
  'event': const NodeStyle(color: Colors.pinkAccent, icon: Icons.flash_on),

  // Generic & Structural
  'group': const NodeStyle(color: Colors.green, icon: Icons.folder),
  'sensor': const NodeStyle(color: Colors.red, icon: Icons.sensors),
  'ai': const NodeStyle(color: Colors.red, icon: Icons.smart_toy_outlined),

  // Default
  'unknown': const NodeStyle(color: Colors.grey, icon: Icons.help_outline),
};

// Materialize palette + catalog order for deterministic highlights.
final List<Color> _priorityPalette = List<Color>.unmodifiable(
  UyavaDataPolicies.priorityColorPalette.map(
    (hex) => _colorFromHex(hex) ?? Colors.transparent,
  ),
);

final List<String> _catalogOrdered = List<String>.unmodifiable(
  UyavaDataPolicies.tagCatalog,
);

final Map<String, int> _catalogIndex = <String, int>{
  for (int i = 0; i < _catalogOrdered.length; i++) _catalogOrdered[i]: i,
};

/// Returns a [NodeStyle] for a given node type string.
///
/// If the type is not found in the standard styles, a default style is returned.
NodeStyle getStyleForType(String type) {
  return _standardStyles[type] ?? _standardStyles['unknown']!;
}

Color? colorForCatalogTag(String tag) {
  if (_priorityPalette.isEmpty) return null;
  final String normalized = tag.trim().toLowerCase();
  final int? order = _catalogIndex[normalized];
  if (order == null) return null;
  final int index = order % _priorityPalette.length;
  return _priorityPalette[index];
}

Color? colorForPriorityPaletteIndex(int index) {
  if (_priorityPalette.isEmpty) return null;
  int resolved = index % _priorityPalette.length;
  if (resolved < 0) {
    resolved += _priorityPalette.length;
  }
  return _priorityPalette[resolved];
}

Color resolveNodeColor(UyavaNode node) {
  final Object? rawPriority = node.data['colorPriorityIndex'];
  if (rawPriority is num) {
    final Color? priority = colorForPriorityPaletteIndex(rawPriority.toInt());
    if (priority != null) {
      return priority;
    }
  }

  final Object? rawColor = node.data['color'];
  if (rawColor is String) {
    final Color? parsed = _colorFromHex(rawColor);
    if (parsed != null) {
      return parsed;
    }
  }

  final Object? rawCatalog = node.data['tagsCatalog'];
  if (rawCatalog is Iterable) {
    for (final Object? entry in rawCatalog) {
      if (entry is! String) continue;
      final Color? tagColor = colorForCatalogTag(entry);
      if (tagColor != null) {
        return tagColor;
      }
    }
  }

  return getStyleForType(node.type).color;
}

Color? _colorFromHex(String raw) {
  String hex = raw.trim();
  if (hex.isEmpty) return null;
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) return null;
  final int? value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(value);
}

/// Maps severity string to a color used for event/pulse visualization.
/// Unknown or null values map to a sensible default (info blue).
Color colorForSeverity(UyavaSeverity? severity) {
  switch (severity) {
    case UyavaSeverity.trace:
      return Colors.grey;
    case UyavaSeverity.debug:
      return Colors.blueGrey;
    case UyavaSeverity.info:
      return Colors.blue;
    case UyavaSeverity.warn:
      return Colors.amber;
    case UyavaSeverity.error:
      return Colors.redAccent;
    case UyavaSeverity.fatal:
      return Colors.red;
    default:
      return Colors.blue; // default to info-style
  }
}

/// Returns an ordinal rank for a severity string to enable comparisons.
/// Lower numbers are less severe. Unknown/null maps to 'info'.
int severityRank(UyavaSeverity? severity) {
  return severity?.index ?? UyavaSeverity.info.index;
}

/// Returns true if [sev] is at least [minLevel] by rank.
bool severityMeets(UyavaSeverity? sev, UyavaSeverity minLevel) {
  return severityRank(sev) >= severityRank(minLevel);
}

/// Compact legend that visualizes catalogued tags using the shared palette.
class TagLegend extends StatefulWidget {
  const TagLegend({
    super.key,
    required this.tagCounts,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.spacing = 8,
    this.runSpacing = 8,
    this.title,
    this.expanded,
    this.initiallyExpanded = true,
    this.onExpandedChanged,
  });

  final Map<String, int> tagCounts;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double runSpacing;
  final String? title;
  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<TagLegend> createState() => _TagLegendState();
}

class _TagLegendState extends State<TagLegend> {
  late bool _expanded;

  bool get _isControlled => widget.expanded != null;

  @override
  void initState() {
    super.initState();
    _expanded = widget.expanded ?? widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant TagLegend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isControlled) {
      _expanded = widget.expanded!;
    } else if (oldWidget.expanded != null && !_isControlled) {
      _expanded = oldWidget.expanded!;
    }
  }

  bool get _effectiveExpanded => widget.expanded ?? _expanded;

  void _toggleExpanded() {
    final bool next = !_effectiveExpanded;
    if (!_isControlled) {
      setState(() {
        _expanded = next;
      });
    }
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = widget.tagCounts;
    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = counts.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false);
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    entries.sort((a, b) {
      final int orderA = _catalogIndex[a.key] ?? 1 << 20;
      final int orderB = _catalogIndex[b.key] ?? 1 << 20;
      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }
      return a.key.compareTo(b.key);
    });

    final theme = Theme.of(context);
    final TextStyle labelStyle =
        theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    final TextStyle countStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final Color fallback = theme.colorScheme.outlineVariant;
    final bool expanded = _effectiveExpanded;
    final double gap = widget.spacing != 8 ? widget.spacing : widget.runSpacing;
    final String headerTitle = widget.title ?? 'Tags';
    final String toggleTooltip = expanded
        ? 'Collapse tag highlights'
        : 'Expand tag highlights';

    final List<Widget> children = <Widget>[
      InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  headerTitle,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Tooltip(
                message: toggleTooltip,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: _toggleExpanded,
                  icon: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    if (expanded) {
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final Color color = colorForCatalogTag(entry.key) ?? fallback;
        children.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 6 : gap),
            child: _TagLegendRow(
              tag: entry.key,
              count: entry.value,
              color: color,
              labelStyle: labelStyle,
              countStyle: countStyle,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TagLegendRow extends StatelessWidget {
  const _TagLegendRow({
    required this.tag,
    required this.count,
    required this.color,
    required this.labelStyle,
    required this.countStyle,
  });

  final String tag;
  final int count;
  final Color color;
  final TextStyle labelStyle;
  final TextStyle countStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tag $tag, $count nodes',
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: labelStyle,
                children: [
                  TextSpan(text: tag.toUpperCase()),
                  const TextSpan(text: ' '),
                  TextSpan(text: '($count)', style: countStyle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
