import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomWaves extends StatelessWidget {
  final double height;
  const BottomWaves({super.key, this.height = 240});
  @override
  Widget build(BuildContext context) => SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WP()));
}

class _WP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final o = Paint()..color = AppColors.orange;
    c.drawPath(
        Path()
          ..moveTo(0, h * 0.34)
          ..quadraticBezierTo(w * 0.30, h * 0.12, w * 0.62, h * 0.30)
          ..quadraticBezierTo(w * 0.85, h * 0.43, w, h * 0.24)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        o);
    final b = Paint()..color = AppColors.blue;
    c.drawPath(
        Path()
          ..moveTo(w * 0.45, h * 0.34)
          ..quadraticBezierTo(w * 0.72, h * 0.20, w, h * 0.40)
          ..lineTo(w, h)
          ..lineTo(w * 0.45, h)
          ..close(),
        b);
    final n = Paint()..color = AppColors.navy;
    c.drawPath(
        Path()
          ..moveTo(0, h * 0.48)
          ..quadraticBezierTo(w * 0.28, h * 0.30, w * 0.58, h * 0.46)
          ..quadraticBezierTo(w * 0.82, h * 0.58, w, h * 0.44)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        n);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class DottedGrid extends StatelessWidget {
  final int rows;
  final int cols;
  final Color color;
  const DottedGrid(
      {super.key, this.rows = 5, this.cols = 5, this.color = AppColors.blue});
  @override
  Widget build(BuildContext context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          rows,
          (_) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      cols,
                      (_) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.35),
                              shape: BoxShape.circle)))))));
}
