import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

void main() {
  group('EdgeVisibilityPolicy', () {
    test('returns 1.0 when warm-up gating disabled', () {
      final policy = EdgeVisibilityPolicy(
        const RenderConfig(hideEdgesDuringWarmup: false),
      );
      final alpha = policy.update(const {}, 0.016);
      expect(alpha, 1.0);
    });

    test('fades in to 1.0 when stable (low speed)', () {
      final cfg = const RenderConfig(
        hideEdgesDuringWarmup: true,
        edgeStableSpeedThreshold: 50.0, // px/sec
        edgeStabilityEmaFactor: 1.0, // instantaneous EMA for deterministic test
        edgeWarmupFadeIn: Duration(milliseconds: 100),
        edgeWarmupFadeOut: Duration(milliseconds: 100),
        edgeMinAlphaDuringWarmup: 0.0,
      );
      final policy = EdgeVisibilityPolicy(cfg);

      // Two nodes barely moving (below threshold)
      final p0 = <String, Vector2>{
        'a': const Vector2(0, 0),
        'b': const Vector2(10, 0),
      };
      final p1 = <String, Vector2>{
        'a': const Vector2(0.1, 0), // 1 px/sec if dt=0.1s
        'b': const Vector2(10.1, 0),
      };

      // First update with low speed stabilizes and reaches alpha=1.0
      double alpha = policy.update(p0, 0.1);
      expect(alpha, closeTo(1.0, 1e-9));

      // Subsequent low-speed updates keep it at 1.0
      alpha = policy.update(p1, 0.1);
      expect(alpha, closeTo(1.0, 1e-9));
    });

    test('fades out toward min when unstable (high speed) with hysteresis', () {
      final cfg = const RenderConfig(
        hideEdgesDuringWarmup: true,
        edgeStableSpeedThreshold: 20.0,
        edgeUnstableHysteresisMultiplier: 2.0, // high threshold 40 px/sec
        edgeStabilityEmaFactor: 1.0, // instantaneous for test
        edgeWarmupFadeIn: Duration(milliseconds: 50),
        edgeWarmupFadeOut: Duration(milliseconds: 50),
        edgeMinAlphaDuringWarmup: 0.2,
      );
      final policy = EdgeVisibilityPolicy(cfg);

      // Prime with a stable step to set _prevPositions and reach alpha=1.0
      var pos0 = <String, Vector2>{'a': const Vector2(0, 0)};
      double alpha = policy.update(pos0, 0.1);
      expect(alpha, closeTo(1.0, 1e-6));

      // Now simulate a spike above high threshold to become unstable
      // Move 10 px over 0.1s => 100 px/sec > 40
      final pos1 = <String, Vector2>{'a': const Vector2(10, 0)};
      alpha = policy.update(pos1, 0.1);
      // Should immediately drop to min due to large rate and clamp
      expect(alpha, closeTo(cfg.edgeMinAlphaDuringWarmup, 1e-6));
    });
  });
}
