part of '../../graph_view_page.dart';

class HoverOverlay extends StatelessWidget {
  const HoverOverlay({
    super.key,
    required this.details,
    required this.viewportSize,
    required this.anchorViewportPosition,
    this.anchorOffset = const Offset(20, -24),
  });

  final GraphHoverDetails details;
  final Size viewportSize;
  final Offset? anchorViewportPosition;
  final Offset anchorOffset;

  @override
  Widget build(BuildContext context) {
    return GraphHoverOverlay(
      details: details,
      viewportSize: viewportSize,
      anchorViewportPosition: anchorViewportPosition,
      anchorOffset: anchorOffset,
    );
  }
}
