import 'package:flutter/animation.dart';

/// Controls visibility and opacity of group "clouds" during transitions.
class CloudVisibilityPolicy {
  final Set<String> collapsedParents;
  final Map<String, double> collapseProgress; // 0..1 raw
  final Curve ease;

  /// Fraction of the expansion tail where clouds fade in.
  final double fadeWindow;

  CloudVisibilityPolicy({
    required this.collapsedParents,
    required this.collapseProgress,
    this.ease = Curves.easeInOut,
    this.fadeWindow = 0.15,
  });

  /// Returns an opacity factor [0..1] for the cloud of [parentId], or null
  /// to indicate it should not be drawn.
  double? cloudOpacity(String parentId) {
    final t = ease.transform(
      (collapseProgress[parentId] ?? 0.0).clamp(0.0, 1.0),
    );

    // Collapsing now -> hide cloud entirely from the very first frame.
    if (collapsedParents.contains(parentId)) {
      return null;
    }

    // When expanding (not in collapsed set), progress goes 1->0.
    // Only show a fade-in near the end to avoid early appearance.
    if (t > fadeWindow) {
      return null; // still far from expanded -> keep hidden
    } else if (t > 0.0) {
      // Fade-in from 0 -> 1 as t falls from fadeWindow -> 0.
      return ((fadeWindow - t) / fadeWindow).clamp(0.0, 1.0);
    } else {
      // Fully expanded -> fully visible.
      return 1.0;
    }
  }
}
