import 'package:flutter/material.dart';

/// Simple leaf mark used on the branded splash (matches native vector).
class FoodMark extends StatelessWidget {
  const FoodMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LeafPainter()),
    );
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.50, size.height * 0.12)
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.22,
        size.width * 0.90,
        size.height * 0.52,
        size.width * 0.50,
        size.height * 0.90,
      )
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.52,
        size.width * 0.18,
        size.height * 0.22,
        size.width * 0.50,
        size.height * 0.12,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
