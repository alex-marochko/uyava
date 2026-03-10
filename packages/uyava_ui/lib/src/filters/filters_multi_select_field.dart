import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FiltersMultiSelectField<T> extends StatefulWidget {
  const FiltersMultiSelectField({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    required this.hintText,
    required this.searchHintText,
    required this.emptyLabel,
    this.leadingIcon,
    this.selectionSummaryBuilder,
    this.cascadeChildren,
    this.menuWidth,
  });

  final List<FiltersMultiSelectOption<T>> options;
  final List<T> selectedValues;
  final ValueChanged<List<T>> onChanged;
  final String hintText;
  final String searchHintText;
  final String emptyLabel;
  final Widget? leadingIcon;
  final String Function(
    List<T> selection,
    Map<T, FiltersMultiSelectOption<T>> lookup,
  )?
  selectionSummaryBuilder;
  final Map<T, List<T>>? cascadeChildren;
  final double? menuWidth;

  @override
  State<FiltersMultiSelectField<T>> createState() =>
      _FiltersMultiSelectFieldState<T>();
}

class _FiltersMultiSelectFieldState<T>
    extends State<FiltersMultiSelectField<T>> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<T> _selection = <T>[];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selection = List<T>.from(widget.selectedValues);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant FiltersMultiSelectField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.selectedValues, _selection)) {
      _selection = List<T>.from(widget.selectedValues);
    }
    if (!identical(widget.options, oldWidget.options)) {
      _scheduleOverlayRebuild();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _removeOverlay(immediate: true);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _scheduleOverlayRebuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_overlayEntry != null) {
        _overlayEntry!.markNeedsBuild();
      }
    });
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final OverlayState overlay = Overlay.of(context);
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Size fieldSize = box?.size ?? const Size(320, 48);
    final double overlayWidth = widget.menuWidth ?? fieldSize.width;
    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _removeOverlay,
                  ),
                ),
                CompositedTransformFollower(
                  link: _layerLink,
                  offset: Offset(0, fieldSize.height + 4),
                  showWhenUnlinked: false,
                  child: _FiltersMultiSelectMenu<T>(
                    width: overlayWidth,
                    options: widget.options,
                    selectedValues: _selection,
                    query: _query,
                    searchHintText: widget.searchHintText,
                    emptyLabel: widget.emptyLabel,
                    onQueryChanged: (String value) {
                      setState(() {
                        _query = value;
                      });
                      _overlayEntry?.markNeedsBuild();
                    },
                    onToggle: (T value, bool selected) {
                      final List<T> next = List<T>.from(_selection);
                      final Map<T, List<T>>? cascades = widget.cascadeChildren;
                      final Iterable<T>? cascadeSource = cascades?[value];
                      final List<T> cascadeList = cascadeSource == null
                          ? List<T>.empty(growable: false)
                          : List<T>.from(cascadeSource);
                      final Set<T> cascadeSet = cascadeList.isEmpty
                          ? <T>{}
                          : cascadeList.toSet();
                      if (selected) {
                        void addValue(T entry) {
                          if (!next.contains(entry)) {
                            next.add(entry);
                          }
                        }

                        addValue(value);
                        if (cascadeList.isNotEmpty) {
                          for (final T child in cascadeList) {
                            addValue(child);
                          }
                        }
                      } else {
                        next.removeWhere((T element) {
                          if (element == value) return true;
                          if (cascadeSet.isEmpty) return false;
                          return cascadeSet.contains(element);
                        });
                      }
                      _selection = next;
                      widget.onChanged(next);
                      _overlayEntry?.markNeedsBuild();
                    },
                    onClose: _removeOverlay,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay({bool immediate = false}) {
    if (_overlayEntry == null) return;
    _overlayEntry!.remove();
    _overlayEntry = null;
    if (immediate) return;
    setState(() {
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEmpty = _selection.isEmpty;
    final Map<T, FiltersMultiSelectOption<T>> optionLookup =
        <T, FiltersMultiSelectOption<T>>{
          for (final FiltersMultiSelectOption<T> option in widget.options)
            option.value: option,
        };
    String? summaryText;
    if (!isEmpty && widget.selectionSummaryBuilder != null) {
      summaryText = widget.selectionSummaryBuilder!(
        List<T>.unmodifiable(_selection),
        optionLookup,
      );
    }
    final TextStyle valueStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final TextStyle hintStyle = valueStyle.copyWith(color: theme.hintColor);

    final Widget? leading = widget.leadingIcon == null
        ? null
        : IconTheme(
            data: IconThemeData(
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: widget.leadingIcon!,
          );
    final Widget suffixIcon = Icon(
      _overlayEntry == null
          ? Icons.keyboard_arrow_down
          : Icons.keyboard_arrow_up,
      size: 18,
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (summaryText != null && summaryText.isEmpty) {
      summaryText = null;
    }

    late final Widget display;
    if (isEmpty) {
      display = Text(
        widget.hintText,
        style: hintStyle,
        overflow: TextOverflow.ellipsis,
      );
    } else if (summaryText != null) {
      display = Text(
        summaryText,
        style: valueStyle,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      display = Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final T value in _selection) _buildChip(value, theme)],
      );
    }

    final Widget baseField = Focus(
      focusNode: _focusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _removeOverlay();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _toggleOverlay();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
            _toggleOverlay();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: (_focusNode.hasFocus || _overlayEntry != null)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: (_focusNode.hasFocus || _overlayEntry != null) ? 2 : 1,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[leading, const SizedBox(width: 6)],
                Flexible(child: display),
                const SizedBox(width: 6),
                suffixIcon,
              ],
            ),
          ),
        ),
      ),
    );

    return baseField;
  }

  Widget _buildChip(T value, ThemeData theme) {
    FiltersMultiSelectOption<T>? option;
    for (final FiltersMultiSelectOption<T> candidate in widget.options) {
      if (candidate.value == value) {
        option = candidate;
        break;
      }
    }
    final String label = option?.chipLabel ?? value.toString();
    return InputChip(
      label: Text(label),
      onDeleted: () {
        final List<T> next = List<T>.from(_selection)..remove(value);
        setState(() {
          _selection = next;
        });
        widget.onChanged(next);
        _overlayEntry?.markNeedsBuild();
      },
    );
  }
}

class _FiltersMultiSelectMenu<T> extends StatefulWidget {
  const _FiltersMultiSelectMenu({
    required this.width,
    required this.options,
    required this.selectedValues,
    required this.query,
    required this.searchHintText,
    required this.emptyLabel,
    required this.onQueryChanged,
    required this.onToggle,
    required this.onClose,
  });

  final double width;
  final List<FiltersMultiSelectOption<T>> options;
  final List<T> selectedValues;
  final String query;
  final String searchHintText;
  final String emptyLabel;
  final ValueChanged<String> onQueryChanged;
  final void Function(T value, bool selected) onToggle;
  final VoidCallback onClose;

  @override
  State<_FiltersMultiSelectMenu<T>> createState() =>
      _FiltersMultiSelectMenuState<T>();
}

class _FiltersMultiSelectMenuState<T>
    extends State<_FiltersMultiSelectMenu<T>> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
    _searchController.addListener(() {
      widget.onQueryChanged(_searchController.text);
    });
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _FiltersMultiSelectMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _searchController.text) {
      _searchController
        ..text = widget.query
        ..selection = TextSelection.collapsed(offset: widget.query.length);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String queryLower = widget.query.toLowerCase();
    final List<FiltersMultiSelectOption<T>> filtered = queryLower.isEmpty
        ? widget.options
        : widget.options
              .where((option) {
                return option.searchText.contains(queryLower);
              })
              .toList(growable: false);
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surface,
      child: SizedBox(
        width: widget.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHintText,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 24,
                      ),
                      child: Center(
                        child: Text(
                          widget.emptyLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (BuildContext context, int index) {
                        final FiltersMultiSelectOption<T> option =
                            filtered[index];
                        final bool selected = widget.selectedValues.contains(
                          option.value,
                        );
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (bool? next) {
                            widget.onToggle(option.value, !selected);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          title: Text(option.label),
                          subtitle: option.subtitle == null
                              ? null
                              : Text(option.subtitle!),
                          contentPadding: EdgeInsets.only(
                            left: 16.0 + option.depth * 12.0,
                            right: 12,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class FiltersMultiSelectOption<T> {
  FiltersMultiSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    String? searchText,
    this.depth = 0,
  }) : searchText = searchText ?? _defaultSearchText(label, subtitle);

  final T value;
  final String label;
  final String? subtitle;
  final String searchText;
  final int depth;

  String get chipLabel => label;

  static String _defaultSearchText(String label, String? subtitle) {
    final StringBuffer buffer = StringBuffer(label.toLowerCase());
    if (subtitle != null && subtitle.isNotEmpty) {
      buffer.write(' ');
      buffer.write(subtitle.toLowerCase());
    }
    return buffer.toString();
  }
}
