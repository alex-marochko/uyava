import 'package:flutter/material.dart';

/// Tabs exposed by the shared journal UI.
enum GraphJournalTab { events, diagnostics }

/// Handles external tab selection requests for the journal.
class GraphJournalDisplayController extends ChangeNotifier {
  GraphJournalDisplayController({
    GraphJournalTab initialTab = GraphJournalTab.events,
  }) : _activeTab = initialTab;

  GraphJournalTab _activeTab;
  int? _pendingSequence;
  bool _pendingDisableEventsAutoScroll = false;
  bool _pendingDisableDiagnosticsAutoScroll = false;

  GraphJournalTab get activeTab => _activeTab;
  int? get pendingSequence => _pendingSequence;
  bool get pendingDisableEventsAutoScroll => _pendingDisableEventsAutoScroll;
  bool get pendingDisableDiagnosticsAutoScroll =>
      _pendingDisableDiagnosticsAutoScroll;

  /// Requests that the journal switch to [tab]. No-op if already active.
  void setActiveTab(GraphJournalTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  /// Requests that the events list scroll to the entry with [sequence].
  void scrollToSequence(int sequence) {
    _pendingSequence = sequence;
    notifyListeners();
  }

  /// Requests that the journal disable auto-scroll for the given [tab].
  void disableAutoScroll(GraphJournalTab tab) {
    if (tab == GraphJournalTab.events) {
      _pendingDisableEventsAutoScroll = true;
    } else {
      _pendingDisableDiagnosticsAutoScroll = true;
    }
    notifyListeners();
  }

  /// Returns the pending scroll request (if any) and clears it.
  int? takePendingSequence() {
    final int? pending = _pendingSequence;
    _pendingSequence = null;
    return pending;
  }

  /// Clears any pending auto-scroll disable flags and returns which tabs were
  /// requested.
  ({bool events, bool diagnostics}) takePendingAutoScrollDisables() {
    final bool events = _pendingDisableEventsAutoScroll;
    final bool diagnostics = _pendingDisableDiagnosticsAutoScroll;
    _pendingDisableEventsAutoScroll = false;
    _pendingDisableDiagnosticsAutoScroll = false;
    return (events: events, diagnostics: diagnostics);
  }
}

typedef GraphJournalTabViewBuilder =
    Widget Function(
      BuildContext context,
      TabController tabController,
      GraphJournalTab activeTab,
    );

/// Provides a [TabController] wired to a [GraphJournalDisplayController].
class GraphJournalTabHost extends StatefulWidget {
  const GraphJournalTabHost({
    super.key,
    required this.initialTab,
    required this.builder,
    this.displayController,
    this.onTabChanged,
  });

  final GraphJournalTab initialTab;
  final GraphJournalDisplayController? displayController;
  final GraphJournalTabViewBuilder builder;
  final ValueChanged<GraphJournalTab>? onTabChanged;

  @override
  State<GraphJournalTabHost> createState() => _GraphJournalTabHostState();
}

class _GraphJournalTabHostState extends State<GraphJournalTabHost>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  late GraphJournalTab _activeTab;
  GraphJournalDisplayController? _displayController;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.displayController?.activeTab ?? widget.initialTab;
    _controller = TabController(
      length: 2,
      initialIndex: _activeTab.index,
      vsync: this,
    )..addListener(_handleTabChanged);
    _displayController = widget.displayController;
    _displayController?.addListener(_handleDisplayControllerChanged);
  }

  @override
  void didUpdateWidget(covariant GraphJournalTabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayController != oldWidget.displayController) {
      oldWidget.displayController?.removeListener(
        _handleDisplayControllerChanged,
      );
      _displayController = widget.displayController;
      _displayController?.addListener(_handleDisplayControllerChanged);
      final GraphJournalTab desired =
          _displayController?.activeTab ?? _activeTab;
      if (desired.index != _controller.index) {
        _controller.index = desired.index;
        _activeTab = desired;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTabChanged);
    _controller.dispose();
    _displayController?.removeListener(_handleDisplayControllerChanged);
    super.dispose();
  }

  void _handleTabChanged() {
    final GraphJournalTab tab = _tabForIndex(_controller.index);
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
    });
    widget.displayController?.setActiveTab(tab);
    widget.onTabChanged?.call(tab);
  }

  void _handleDisplayControllerChanged() {
    final GraphJournalDisplayController? controller = _displayController;
    if (controller == null) return;
    final int desiredIndex = controller.activeTab.index;
    if (desiredIndex == _controller.index) return;
    _controller.animateTo(desiredIndex);
  }

  GraphJournalTab _tabForIndex(int index) {
    return index == 0 ? GraphJournalTab.events : GraphJournalTab.diagnostics;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller, _activeTab);
  }
}
