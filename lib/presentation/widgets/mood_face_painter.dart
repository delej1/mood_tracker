import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/enums/mood_type.dart';

/// Draws a mood face using only Flutter canvas primitives.
///
/// No images, emoji, or icon fonts — every pixel is produced by:
///   [Canvas.drawCircle]  → face outline and eyes
///   [Canvas.drawArc]     → mouth curves and eyebrow arcs
///   [Canvas.drawPath]    → angled eyebrows for sad/happy
///
/// [pulseScale] is driven by the parent [AnimationController] — at 1.0 the face
/// is its natural size; at 1.08 it is subtly enlarged to create the tap-bounce.
class MoodFacePainter extends CustomPainter {
  const MoodFacePainter({
    required this.mood,
    required this.color,
    this.pulseScale = 1.0,
    this.strokeWidth,
  });

  final MoodType mood;
  final Color color;

  /// Scale factor driven by the pulse animation. 1.0 = normal, 1.08 = peak.
  final double pulseScale;

  /// Override stroke width — defaults to a value proportional to face size.
  final double? strokeWidth;

  // ---------------------------------------------------------------------------
  // Paint objects — created lazily per paint call to respect color changes.
  // ---------------------------------------------------------------------------

  Paint _outlinePaint(double sw) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = sw
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _fillPaint() => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  Paint _featurePaint(double sw) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = sw * 0.85
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ---------------------------------------------------------------------------
  // Main paint
  // ---------------------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Base face radius, scaled by pulseScale for the bounce animation.
    final r = (size.width * 0.42) * pulseScale;
    final sw = strokeWidth ?? (r * 0.1).clamp(1.5, 4.0);

    // Save/restore so the pulse scale transform is isolated.
    canvas.save();
    // Scale from the centre of the canvas.
    canvas.translate(cx, cy);
    canvas.scale(pulseScale);
    canvas.translate(-cx, -cy);

    // 1. Face outline circle.
    canvas.drawCircle(Offset(cx, cy), r, _outlinePaint(sw));

    // 2. Eyes — small filled circles.
    _drawEyes(canvas, cx, cy, r);

    // 3. Mood-specific eyebrows.
    _drawEyebrows(canvas, cx, cy, r, sw);

    // 4. Mood-specific mouth.
    _drawMouth(canvas, cx, cy, r, sw);

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Eyes
  // ---------------------------------------------------------------------------

  void _drawEyes(Canvas canvas, double cx, double cy, double r) {
    final eyeRadius = r * 0.09;
    final eyeOffsetX = r * 0.30;
    final eyeOffsetY = r * 0.18;

    canvas.drawCircle(
      Offset(cx - eyeOffsetX, cy - eyeOffsetY),
      eyeRadius,
      _fillPaint(),
    );
    canvas.drawCircle(
      Offset(cx + eyeOffsetX, cy - eyeOffsetY),
      eyeRadius,
      _fillPaint(),
    );
  }

  // ---------------------------------------------------------------------------
  // Eyebrows — differ per mood
  // ---------------------------------------------------------------------------

  void _drawEyebrows(Canvas canvas, double cx, double cy, double r, double sw) {
    switch (mood) {
      case MoodType.happy:
        _drawHappyEyebrows(canvas, cx, cy, r, sw);
      case MoodType.neutral:
        _drawNeutralEyebrows(canvas, cx, cy, r, sw);
      case MoodType.sad:
        _drawSadEyebrows(canvas, cx, cy, r, sw);
    }
  }

  /// Happy eyebrows: gentle upward arcs — relaxed and open.
  void _drawHappyEyebrows(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double sw,
  ) {
    final paint = _featurePaint(sw);
    final browY = cy - r * 0.42;
    final browHalfWidth = r * 0.22;
    final lift = r * 0.07;

    for (final sign in [-1.0, 1.0]) {
      final bx = cx + sign * r * 0.30;
      final rect = Rect.fromCenter(
        center: Offset(bx, browY + lift),
        width: browHalfWidth * 2,
        height: lift * 2.5,
      );
      // Upward arc: start at left end, sweep half-pi upward.
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
    }
  }

  /// Neutral eyebrows: flat horizontal lines — no emotion.
  void _drawNeutralEyebrows(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double sw,
  ) {
    final paint = _featurePaint(sw);
    final browY = cy - r * 0.40;
    final browHalfWidth = r * 0.22;
    final eyeOffsetX = r * 0.30;

    for (final sign in [-1.0, 1.0]) {
      final bx = cx + sign * eyeOffsetX;
      canvas.drawLine(
        Offset(bx - browHalfWidth, browY),
        Offset(bx + browHalfWidth, browY),
        paint,
      );
    }
  }

  /// Sad eyebrows: inner corners raised, outer corners low — the "worried" V.
  void _drawSadEyebrows(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double sw,
  ) {
    final paint = _featurePaint(sw);
    final browY = cy - r * 0.38;
    final browHalfWidth = r * 0.22;
    final innerLift = r * 0.10; // inner corner lifts up
    final eyeOffsetX = r * 0.30;

    for (final sign in [-1.0, 1.0]) {
      final bx = cx + sign * eyeOffsetX;
      // Inner point (near nose bridge) is higher; outer point is lower.
      final innerX = bx - sign * browHalfWidth;
      final outerX = bx + sign * browHalfWidth;
      canvas.drawLine(
        Offset(innerX, browY - innerLift), // inner (raised)
        Offset(outerX, browY + innerLift * 0.5), // outer (lowered)
        paint,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Mouth — the clearest differentiator between moods
  // ---------------------------------------------------------------------------

  void _drawMouth(Canvas canvas, double cx, double cy, double r, double sw) {
    switch (mood) {
      case MoodType.happy:
        _drawHappyMouth(canvas, cx, cy, r, sw);
      case MoodType.neutral:
        _drawNeutralMouth(canvas, cx, cy, r, sw);
      case MoodType.sad:
        _drawSadMouth(canvas, cx, cy, r, sw);
    }
  }

  /// Happy mouth: a wide upward-curving smile arc.
  ///
  /// The Rect is positioned below the vertical centre so the arc sits on the
  /// lower half of the face. startAngle = 0 (right), sweepAngle = π draws
  /// the bottom half of the ellipse — which reads as a smile.
  void _drawHappyMouth(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double sw,
  ) {
    final mouthWidth = r * 0.60;
    final mouthHeight = r * 0.30;
    final mouthTop = cy + r * 0.15;

    final rect = Rect.fromCenter(
      center: Offset(cx, mouthTop),
      width: mouthWidth * 2,
      height: mouthHeight * 2,
    );

    canvas.drawArc(rect, 0, math.pi, false, _featurePaint(sw));
  }

  /// Neutral mouth: a plain horizontal line — no curve either way.
  void _drawNeutralMouth(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double sw,
  ) {
    final halfWidth = r * 0.28;
    final mouthY = cy + r * 0.28;
    canvas.drawLine(
      Offset(cx - halfWidth, mouthY),
      Offset(cx + halfWidth, mouthY),
      _featurePaint(sw),
    );
  }

  /// Sad mouth: an inverted arc — same geometry as happy but the Rect is moved
  /// upward so that startAngle = π, sweepAngle = π draws the TOP half of the
  /// ellipse, which reads as a frown.
  void _drawSadMouth(Canvas canvas, double cx, double cy, double r, double sw) {
    final mouthWidth = r * 0.52;
    final mouthHeight = r * 0.26;
    // Move rect centre upward so the frown arc appears in the lower face.
    final rectCentreY = cy + r * 0.45;

    final rect = Rect.fromCenter(
      center: Offset(cx, rectCentreY),
      width: mouthWidth * 2,
      height: mouthHeight * 2,
    );

    // π start (left), π sweep → traces the upper half of the ellipse = frown.
    canvas.drawArc(rect, math.pi, math.pi, false, _featurePaint(sw));
  }

  // ---------------------------------------------------------------------------
  // Repaint
  // ---------------------------------------------------------------------------

  @override
  bool shouldRepaint(MoodFacePainter old) =>
      old.mood != mood ||
      old.color != color ||
      old.pulseScale != pulseScale ||
      old.strokeWidth != strokeWidth;
}
