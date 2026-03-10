import 'package:uyava_core/uyava_core.dart';

import '../config.dart';

/// Tracks layout motion and computes a global edge opacity based on stability.
///
/// This is a purely visual policy and does not change the layout algorithm.
class EdgeVisibilityPolicy {
  final RenderConfig config;

  Map<String, Vector2>? _prevPositions;
  double _emaSpeed = 0.0; // px/sec EMA
  double _alpha = 1.0;
  bool _stable = false;

  EdgeVisibilityPolicy(this.config) {
    _alpha = config.hideEdgesDuringWarmup
        ? config.edgeMinAlphaDuringWarmup
        : 1.0;
    _stable = !config.hideEdgesDuringWarmup;
  }

  void reset() {
    _prevPositions = null;
    _emaSpeed = 0.0;
    _alpha = config.hideEdgesDuringWarmup
        ? config.edgeMinAlphaDuringWarmup
        : 1.0;
    _stable = !config.hideEdgesDuringWarmup;
  }

  /// Update with the latest positions and dt (seconds), returns global alpha [0..1].
  double update(Map<String, Vector2> positions, double dtSeconds) {
    if (!config.hideEdgesDuringWarmup) return 1.0; // disabled -> always visible
    if (dtSeconds <= 0) return _alpha;

    double maxSpeed = 0.0;
    if (_prevPositions != null) {
      final prev = _prevPositions!;
      for (final entry in positions.entries) {
        final id = entry.key;
        final curr = entry.value;
        final p = prev[id];
        if (p == null) continue;
        final dist = (curr - p).distance;
        final speed = dist / dtSeconds; // px/sec
        if (speed > maxSpeed) maxSpeed = speed;
      }
    }

    _prevPositions = Map.of(positions);

    // Initialize EMA on first measurement
    if (_emaSpeed == 0.0) {
      _emaSpeed = maxSpeed;
    } else {
      final k = config.edgeStabilityEmaFactor.clamp(0.0, 1.0);
      _emaSpeed = _emaSpeed * (1 - k) + maxSpeed * k;
    }

    final low = config.edgeStableSpeedThreshold;
    final high =
        config.edgeStableSpeedThreshold *
        config.edgeUnstableHysteresisMultiplier;

    if (_stable) {
      if (_emaSpeed > high) _stable = false;
    } else {
      if (_emaSpeed < low) _stable = true;
    }

    final double targetAlpha = _stable ? 1.0 : config.edgeMinAlphaDuringWarmup;
    final duration = _stable
        ? config.edgeWarmupFadeIn
        : config.edgeWarmupFadeOut;
    final rate = duration.inMilliseconds == 0
        ? 1.0
        : (dtSeconds * 1000.0) / duration.inMilliseconds;

    if (targetAlpha > _alpha) {
      _alpha = (_alpha + rate).clamp(0.0, targetAlpha);
    } else if (targetAlpha < _alpha) {
      _alpha = (_alpha - rate).clamp(targetAlpha, 1.0);
    }

    return _alpha;
  }
}
