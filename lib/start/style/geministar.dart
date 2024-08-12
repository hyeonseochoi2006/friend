import 'package:flutter/material.dart';

class Geministar extends CustomPainter {
  final Gradient gradient;

  Geministar(this.gradient);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();

    double w = size.width;
    double h = size.height;

    path.moveTo(w / 2, 0);
    path.cubicTo(w * 0.75, -h * 0.1, w * 1.1, h * 0.25, w, h / 2);
    path.cubicTo(w * 1.1, h * 0.75, w * 0.75, h * 1.1, w / 2, h);
    path.cubicTo(w * 0.25, h * 1.1, -w * 0.1, h * 0.75, 0, h / 2);
    path.cubicTo(-w * 0.1, h * 0.25, w * 0.25, -h * 0.1, w / 2, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

