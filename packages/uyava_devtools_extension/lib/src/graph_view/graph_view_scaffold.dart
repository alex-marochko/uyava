part of '../../graph_view_page.dart';

class GraphViewScaffold extends StatelessWidget {
  const GraphViewScaffold({
    super.key,
    required this.filtersVisible,
    required this.filtersPanelBuilder,
    required this.topBarActions,
    required this.panelShell,
    this.actionsSpacing = 8,
    this.actionsPadding = 12,
  });

  final bool filtersVisible;
  final WidgetBuilder filtersPanelBuilder;
  final List<Widget> topBarActions;
  final Widget panelShell;
  final double actionsSpacing;
  final double actionsPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Material(
              color: theme.colorScheme.surface,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: filtersVisible
                          ? Builder(builder: filtersPanelBuilder)
                          : const SizedBox.shrink(),
                    ),
                    SizedBox(width: actionsPadding),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _joinWithSpacing(topBarActions, actionsSpacing),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: panelShell),
          ],
        ),
      ),
    );
  }
}

List<Widget> _joinWithSpacing(List<Widget> children, double spacing) {
  if (children.isEmpty) return const <Widget>[];
  final List<Widget> spaced = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    spaced.add(children[i]);
    final bool isLast = i == children.length - 1;
    if (!isLast) {
      spaced.add(SizedBox(width: spacing));
    }
  }
  return spaced;
}
