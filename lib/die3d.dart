import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

/// A 3D vector.
typedef Vec3 = (double, double, double);

/// A 3x3 rotation matrix, row-major.
@immutable
class Rotation {
  const Rotation._(this._m);

  static const identity = Rotation._([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  final List<double> _m;

  /// Turns by [a] radians around the x axis (right). A positive angle tips
  /// the top towards the viewer.
  factory Rotation.x(double a) {
    final c = cos(a), s = sin(a);
    return Rotation._([1, 0, 0, 0, c, -s, 0, s, c]);
  }

  /// Turns by [a] radians around the y axis (up).
  factory Rotation.y(double a) {
    final c = cos(a), s = sin(a);
    return Rotation._([c, 0, s, 0, 1, 0, -s, 0, c]);
  }

  /// Turns by [a] radians around [axis], which need not be unit length.
  factory Rotation.axisAngle(Vec3 axis, double a) {
    final (ax, ay, az) = axis;
    final len = sqrt(ax * ax + ay * ay + az * az);
    if (len == 0) return identity;
    final x = ax / len, y = ay / len, z = az / len;
    final c = cos(a), s = sin(a), t = 1 - c;
    return Rotation._([
      t * x * x + c, t * x * y - s * z, t * x * z + s * y, //
      t * x * y + s * z, t * y * y + c, t * y * z - s * x, //
      t * x * z - s * y, t * y * z + s * x, t * z * z + c, //
    ]);
  }

  /// This rotation applied after [o].
  Rotation operator *(Rotation o) {
    final r = List<double>.filled(9, 0);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        var sum = 0.0;
        for (var k = 0; k < 3; k++) {
          sum += _m[i * 3 + k] * o._m[k * 3 + j];
        }
        r[i * 3 + j] = sum;
      }
    }
    return Rotation._(r);
  }

  Rotation get inverse => Rotation._([
    _m[0], _m[3], _m[6], //
    _m[1], _m[4], _m[7], //
    _m[2], _m[5], _m[8], //
  ]);

  Vec3 apply(Vec3 v) {
    final (x, y, z) = v;
    return (
      _m[0] * x + _m[1] * y + _m[2] * z,
      _m[3] * x + _m[4] * y + _m[5] * z,
      _m[6] * x + _m[7] * y + _m[8] * z,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Rotation && listEquals(other._m, _m);

  @override
  int get hashCode => Object.hashAll(_m);
}

/// One face of the cube: its corner, two edges (face coordinates 0..1 run
/// along them) and its outward normal. The cube spans -1..1 on each axis;
/// x points right, y up and z towards the viewer.
class CubeFace {
  const CubeFace(this.value, this.origin, this.u, this.v, this.normal);
  final int value;
  final Vec3 origin, u, v, normal;
}

/// The die's geometry and the poses that show each face.
abstract final class Cube {
  /// The turn that brings face [value] to the front, upright. Opposite
  /// faces add up to 7, like a real die (1 front, 2 top, 3 right).
  static Rotation faceToFront(int value) => switch (value) {
    1 => Rotation.identity,
    2 => Rotation.x(pi / 2),
    3 => Rotation.y(-pi / 2),
    4 => Rotation.y(pi / 2),
    5 => Rotation.x(-pi / 2),
    6 => Rotation.y(pi),
    _ => throw ArgumentError.value(value, 'value'),
  };

  /// The resting tilt: a bit of the top and right faces show, like the app
  /// icon, while the result faces the viewer.
  static final Rotation tilt = Rotation.x(0.42) * Rotation.y(-0.52);

  /// The pose of a die at rest showing [value].
  static Rotation rest(int value) => tilt * faceToFront(value);

  static final List<CubeFace> faces = [
    for (var value = 1; value <= 6; value++)
      () {
        // The front face's frame, turned back to where face [value] sits.
        final back = faceToFront(value).inverse;
        return CubeFace(
          value,
          back.apply((-1, 1, 1)),
          back.apply((2, 0, 0)),
          back.apply((0, -2, 0)),
          back.apply((0, 0, 1)),
        );
      }(),
  ];

  /// The face that points most towards the viewer in [pose].
  static int frontValue(Rotation pose) {
    var best = 1;
    var bestZ = double.negativeInfinity;
    for (final f in faces) {
      final z = pose.apply(f.normal).$3;
      if (z > bestZ) {
        bestZ = z;
        best = f.value;
      }
    }
    return best;
  }

  /// Pip positions on a face, in face coordinates (column, row).
  static const Map<int, List<(double, double)>> pips = {
    1: [(0.5, 0.5)],
    2: [(0.25, 0.25), (0.75, 0.75)],
    3: [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)],
    4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
    5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
    6: [
      (0.25, 0.25),
      (0.75, 0.25),
      (0.25, 0.5),
      (0.75, 0.5),
      (0.25, 0.75),
      (0.75, 0.75),
    ],
  };
}

/// A die drawn as a semi-transparent blue cube, in the style of the app
/// icon. [pose] turns it; [Cube.rest] gives the resting pose for a value.
/// It always fits inside its square box, whatever the pose.
class Die3D extends StatelessWidget {
  const Die3D({super.key, required this.pose});

  final Rotation pose;

  /// The value the die shows: the face most towards the viewer.
  int get value => Cube.frontValue(pose);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Die showing $value',
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(painter: _CubePainter(pose)),
      ),
    );
  }
}

class _CubePainter extends CustomPainter {
  _CubePainter(this.pose);

  final Rotation pose;

  // Icon colors.
  static const _light = Color(0xFF9AD4FF);
  static const _dark = Color(0xFF123F8C);
  static const _edge = Color(0xFFE3F2FF);

  /// Light from the top left, in front.
  static const Vec3 _lightDir = (-0.42, 0.72, 0.55);

  /// Camera distance, in half cube sides: a mild perspective.
  static const double _eye = 7;

  static const _corners = <Vec3>[
    (-1, -1, -1), (1, -1, -1), (-1, 1, -1), (1, 1, -1), //
    (-1, -1, 1), (1, -1, 1), (-1, 1, 1), (1, 1, 1), //
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final side = min(size.width, size.height);
    if (side <= 0) return;

    // Project, then scale and center so the whole cube fills 92% of the box.
    Offset raw(Vec3 p) {
      final (x, y, z) = pose.apply(p);
      final f = _eye / (_eye - z);
      return Offset(x * f, -y * f);
    }

    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final c in _corners) {
      final o = raw(c);
      minX = min(minX, o.dx);
      maxX = max(maxX, o.dx);
      minY = min(minY, o.dy);
      maxY = max(maxY, o.dy);
    }
    final k = 0.92 * side / max(maxX - minX, maxY - minY);
    final mid = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    final center = size.center(Offset.zero);
    Offset project(Vec3 p) => (raw(p) - mid) * k + center;

    Vec3 at(CubeFace f, double s, double t) => (
      f.origin.$1 + s * f.u.$1 + t * f.v.$1,
      f.origin.$2 + s * f.u.$2 + t * f.v.$2,
      f.origin.$3 + s * f.u.$3 + t * f.v.$3,
    );

    Path facePath(CubeFace f) => Path()
      ..addPolygon([
        project(at(f, 0, 0)),
        project(at(f, 1, 0)),
        project(at(f, 1, 1)),
        project(at(f, 0, 1)),
      ], true);

    // Faces from back to front. A face is in front when its normal points
    // towards the eye, seen from its center.
    final faces = [
      for (final f in Cube.faces)
        (
          f,
          () {
            final n = pose.apply(f.normal);
            final c = pose.apply(at(f, 0.5, 0.5));
            // Dot product of the normal with the direction to the eye.
            return -(n.$1 * c.$1 + n.$2 * c.$2 + n.$3 * (c.$3 - _eye));
          }(),
          pose.apply(f.normal),
        ),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    // Soft shadow under the cube.
    final shadow = Path();
    for (final (f, facing, _) in faces) {
      if (facing > 0) shadow.addPath(facePath(f), Offset.zero);
    }
    canvas.drawPath(
      shadow.shift(Offset(0, side * 0.035)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.03),
    );

    final (lx, ly, lz) = _lightDir;
    final lLen = sqrt(lx * lx + ly * ly + lz * lz);
    for (final (f, facing, n) in faces) {
      final path = facePath(f);
      final front = facing > 0;
      final lit = max(0.0, (n.$1 * lx + n.$2 * ly + n.$3 * lz) / lLen);
      final a = project(at(f, 0, 0));
      final b = project(at(f, 1, 1));
      if (!front) {
        // Seen through the glass: faint, with dashed edges like the icon.
        canvas.drawPath(path, Paint()..color = _dark.withValues(alpha: 0.18));
        _dashed(
          canvas,
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = side * 0.009,
          side * 0.035,
        );
        continue;
      }
      final base = Color.lerp(_dark, _light, 0.15 + 0.85 * lit)!;
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(a, b, [
            Color.lerp(base, _light, 0.25)!.withValues(alpha: 0.9),
            Color.lerp(base, _dark, 0.2)!.withValues(alpha: 0.8),
          ]),
      );
      // A glassy sheen from the top-left corner.
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(a, Offset.lerp(a, b, 0.55)!, [
            Colors.white.withValues(alpha: 0.10 + 0.18 * lit),
            Colors.white.withValues(alpha: 0),
          ]),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = _edge.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * 0.016
          ..strokeJoin = StrokeJoin.round,
      );
      // Pips, fading out as the face turns edge-on.
      final edgeOn = (n.$3 * 4).clamp(0.0, 1.0);
      if (edgeOn == 0) continue;
      final pipPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95 * edgeOn);
      final pipList = Cube.pips[f.value]!;
      final r = pipList.length == 1 ? 0.13 : 0.095;
      for (final (s, t) in pipList) {
        canvas.drawPath(
          Path()..addPolygon([
            for (var i = 0; i < 20; i++)
              project(
                at(f, s + r * cos(i * pi / 10), t + r * sin(i * pi / 10)),
              ),
          ], true),
          pipPaint,
        );
      }
    }
  }

  static void _dashed(Canvas canvas, Path path, Paint paint, double dash) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash * 2) {
        canvas.drawPath(
          metric.extractPath(d, min(d + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CubePainter old) => old.pose != pose;
}
