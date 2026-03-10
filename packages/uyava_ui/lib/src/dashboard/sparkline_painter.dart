import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lightweight sparkline painter used by the metrics dashboard.
class SparklinePainter extends CustomPainter {
  SparklinePainter({
    required List<double> values,
    required this.color,
    this.strokeWidth = 2.0,
  }) : assert(strokeWidth > 0),
       _values = List<double>.from(values, growable: false);

  final List<double> _values;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (_values.length < 2) {
      return;
    }

    final double minValue = _values.reduce(math.min);
    final double maxValue = _values.reduce(math.max);
    final double range = maxValue - minValue;
    final double safeRange = range <= 0 ? 1 : range;
    final Path path = Path();
    final int pointCount = _values.length;
    final double dx = pointCount == 1 ? 0 : size.width / (pointCount - 1);

    for (var i = 0; i < pointCount; i++) {
      final double value = _values[i];
      final double normalized = (value - minValue) / safeRange;
      final double x = dx * i;
      final double y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, strokePaint);

    final double lastValue = _values.last;
    final double lastNormalized = (lastValue - minValue) / safeRange;
    final Offset lastPoint = Offset(
      dx * (pointCount - 1),
      size.height - (lastNormalized * size.height),
    );

    final Paint highlightPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(lastPoint, strokeWidth * 1.2, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return !listEquals(_values, oldDelegate._values) ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
