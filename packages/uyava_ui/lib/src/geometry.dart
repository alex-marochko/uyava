import 'dart:ui';

/// Computes a convex hull (Monotone Chain) of the given points.
List<Offset> convexHull(List<Offset> points) {
  if (points.length <= 3) return List.of(points);

  points = List.of(points);
  points.sort((a, b) {
    if (a.dx != b.dx) return a.dx.compareTo(b.dx);
    return a.dy.compareTo(b.dy);
  });

  double cross(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

  List<Offset> upper = [];
  for (var p in points) {
    while (upper.length >= 2 &&
        cross(upper[upper.length - 2], upper.last, p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }

  List<Offset> lower = [];
  for (var p in points.reversed) {
    while (lower.length >= 2 &&
        cross(lower[lower.length - 2], lower.last, p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }

  return [
    ...upper.sublist(0, upper.length - 1),
    ...lower.sublist(0, lower.length - 1),
  ];
}

/// Returns a smoothed path for the boundary, with optional outward padding.
Path createSmoothedPaddedPath(List<Offset> points, double padding) {
  if (points.isEmpty) return Path();

  final List<Offset> paddedPoints;
  if (padding.abs() < 0.0001) {
    paddedPoints = points;
  } else {
    final center =
        points.fold(Offset.zero, (sum, p) => sum + p) /
        points.length.toDouble();
    paddedPoints = points.map((p) {
      final direction = p - center;
      final distance = direction.distance;
      if (distance < 0.001) return p;
      return p + (direction / distance) * padding;
    }).toList();
  }

  final path = Path();
  if (paddedPoints.length < 2) return path;

  path.moveTo(
    (paddedPoints.last.dx + paddedPoints.first.dx) / 2,
    (paddedPoints.last.dy + paddedPoints.first.dy) / 2,
  );

  for (var i = 0; i < paddedPoints.length; i++) {
    final p2 = paddedPoints[(i + 1) % paddedPoints.length];
    final midPoint = (paddedPoints[i] + p2) / 2;
    path.quadraticBezierTo(
      paddedPoints[i].dx,
      paddedPoints[i].dy,
      midPoint.dx,
      midPoint.dy,
    );
  }
  path.close();
  return path;
}
