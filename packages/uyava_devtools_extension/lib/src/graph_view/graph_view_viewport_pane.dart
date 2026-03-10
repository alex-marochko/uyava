part of '../../graph_view_page.dart';

typedef GraphViewportBuilder =
    Widget Function(BuildContext context, UyavaPanelContext panelContext);

class GraphViewportPane extends StatelessWidget {
  const GraphViewportPane({
    super.key,
    required this.builder,
    required this.panelContext,
  });

  final GraphViewportBuilder builder;
  final UyavaPanelContext panelContext;

  @override
  Widget build(BuildContext context) {
    return builder(context, panelContext);
  }
}
