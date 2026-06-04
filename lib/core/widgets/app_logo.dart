import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Lacto Sync brand mark — milk drop with sync arc.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final primaryFaint =
        isDark ? AppColors.darkPrimaryFaint : AppColors.primaryFaint;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryFaint,
            primary.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: CustomPaint(
        painter: _LactoSyncLogoPainter(color: primary),
        size: Size.square(size),
      ),
    );
  }
}

class _LactoSyncLogoPainter extends CustomPainter {
  _LactoSyncLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dropPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.5;
    final cy = size.height * 0.54;

    final drop = Path()
      ..moveTo(cx, size.height * 0.18)
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.32,
        size.width * 0.78,
        size.height * 0.58,
        cx,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.58,
        size.width * 0.22,
        size.height * 0.32,
        cx,
        size.height * 0.18,
      )
      ..close();

    canvas.drawPath(drop, dropPaint);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.28),
      -0.4,
      2.2,
      false,
      arcPaint,
    );

    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(size.width * 0.38, size.height * 0.36),
      size.width * 0.06,
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _LactoSyncLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
