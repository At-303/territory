import 'package:flutter/material.dart';

import '../theme.dart';

/// Outline symbol for a region style:
/// 0 square, 1 circle, 2 triangle, 3 heart, 4 sparkle.
class ShapePainter extends CustomPainter {
  const ShapePainter(this.style, {this.strokeWidth = 1.6});

  final int style;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.ink;
    final w = size.width;
    final h = size.height;

    switch (style) {
      case 0:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h),
            Radius.circular(w * 0.2),
          ),
          p,
        );
      case 1:
        canvas.drawCircle(Offset(w / 2, h / 2), w / 2, p);
      case 2:
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, 0)
            ..lineTo(w, h)
            ..lineTo(0, h)
            ..close(),
          p,
        );
      case 3:
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, h * 0.95)
            ..cubicTo(-w * 0.2, h * 0.45, w * 0.15, -h * 0.1, w / 2, h * 0.28)
            ..cubicTo(w * 0.85, -h * 0.1, w * 1.2, h * 0.45, w / 2, h * 0.95),
          p,
        );
      default:
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, 0)
            ..quadraticBezierTo(w / 2, h / 2, w, h / 2)
            ..quadraticBezierTo(w / 2, h / 2, w / 2, h)
            ..quadraticBezierTo(w / 2, h / 2, 0, h / 2)
            ..quadraticBezierTo(w / 2, h / 2, w / 2, 0),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(ShapePainter old) =>
      old.style != style || old.strokeWidth != strokeWidth;
}

class ShapeIcon extends StatelessWidget {
  const ShapeIcon({super.key, required this.style, required this.size});

  final int style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: ShapePainter(style)),
    );
  }
}
