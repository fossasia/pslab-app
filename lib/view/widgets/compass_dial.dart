import 'dart:math';
import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class CompassDial extends StatelessWidget {
  final double rotationRadians;
  final double headingDegrees;
  final String selectedAxis;

  final double size;

  const CompassDial({
    super.key,
    required this.rotationRadians,
    required this.headingDegrees,
    this.selectedAxis = 'X',
    this.size = 320,
  });

  String _getCardinalDirection(double degree) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degree + 22.5) % 360 ~/ 45);
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    final normalizedDegree = (headingDegrees % 360 + 360) % 360;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CompassCanvasPainter(
            rotationRadians: rotationRadians,
            headingText: '${normalizedDegree.toStringAsFixed(1)}°',
            cardinalText: _getCardinalDirection(normalizedDegree),
            axisText: '$selectedAxis-Axis',
            accentRed: primaryRed,
          ),
        ),
      ),
    );
  }
}

class _CompassCanvasPainter extends CustomPainter {
  final double rotationRadians;
  final String headingText;
  final String cardinalText;
  final String axisText;
  final Color accentRed;

  _CompassCanvasPainter({
    required this.rotationRadians,
    required this.headingText,
    required this.cardinalText,
    required this.axisText,
    required this.accentRed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    _drawOuterBezel(canvas, center, radius);
    _drawFixedLubberLine(canvas, center, radius);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationRadians);

    _drawTicksAndDegrees(canvas, radius);
    _drawCardinalLabels(canvas, radius);
    _drawCrosshairAndRings(canvas, radius);
    _drawMagneticNeedle(canvas, radius);

    canvas.restore();

    _drawCenterHub(canvas, center, radius);
  }

  void _drawOuterBezel(Canvas canvas, Offset center, double radius) {
    final bezelRect = Rect.fromCircle(center: center, radius: radius * 0.96);
    final bezelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF0F2F5),
          Color(0xFFE2E6EA),
        ],
      ).createShader(bezelRect);
    canvas.drawCircle(center, radius * 0.96, bezelPaint);

    canvas.drawCircle(
      center,
      radius * 0.96,
      Paint()
        ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final faceRect = Rect.fromCircle(center: center, radius: radius * 0.90);
    final facePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.15),
        radius: 0.95,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFBFBFD),
          Color(0xFFEEF1F5),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(faceRect);
    canvas.drawCircle(center, radius * 0.90, facePaint);

    final rimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.90, rimPaint);
  }

  void _drawFixedLubberLine(Canvas canvas, Offset center, double radius) {
    final path = Path();
    final topY = center.dy - radius * 0.95;
    path.moveTo(center.dx, topY + radius * 0.09);
    path.lineTo(center.dx - radius * 0.045, topY);
    path.lineTo(center.dx + radius * 0.045, topY);
    path.close();

    final paint = Paint()
      ..color = accentRed
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _drawTicksAndDegrees(Canvas canvas, double radius) {
    final tickOuterRadius = radius * 0.85;

    final majorTickPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final mediumTickPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 0.8;

    final northTickPaint = Paint()
      ..color = accentRed
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int deg = 0; deg < 360; deg += 2) {
      final angle = (deg - 90) * pi / 180;
      final isMajor = deg % 30 == 0;
      final isMedium = deg % 10 == 0;

      double tickLength;
      Paint currentPaint;

      if (deg == 0) {
        tickLength = radius * 0.09;
        currentPaint = northTickPaint;
      } else if (isMajor) {
        tickLength = radius * 0.075;
        currentPaint = majorTickPaint;
      } else if (isMedium) {
        tickLength = radius * 0.05;
        currentPaint = mediumTickPaint;
      } else {
        tickLength = radius * 0.028;
        currentPaint = minorTickPaint;
      }

      final cosA = cos(angle);
      final sinA = sin(angle);

      final p1 = Offset(cosA * tickOuterRadius, sinA * tickOuterRadius);
      final p2 = Offset(
        cosA * (tickOuterRadius - tickLength),
        sinA * (tickOuterRadius - tickLength),
      );

      canvas.drawLine(p1, p2, currentPaint);
      if (isMajor) {
        canvas.save();
        final textRadius = radius * 0.71;
        final textPos = Offset(cosA * textRadius, sinA * textRadius);
        canvas.translate(textPos.dx, textPos.dy);
        canvas.rotate(angle + pi / 2);

        tp.text = TextSpan(
          text: '$deg',
          style: TextStyle(
            color: deg == 0 ? accentRed : const Color(0xFF212121),
            fontSize: radius * 0.065,
            fontWeight: deg == 0 ? FontWeight.bold : FontWeight.w600,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  void _drawCardinalLabels(Canvas canvas, double radius) {
    const cardinals = {
      0: 'N',
      45: 'NE',
      90: 'E',
      135: 'SE',
      180: 'S',
      225: 'SW',
      270: 'W',
      315: 'NW',
    };

    final tp = TextPainter(textDirection: TextDirection.ltr);

    cardinals.forEach((deg, label) {
      final isPrimary = deg % 90 == 0;
      final angle = (deg - 90) * pi / 180;
      final labelRadius = isPrimary ? radius * 0.54 : radius * 0.56;

      canvas.save();
      final pos = Offset(cos(angle) * labelRadius, sin(angle) * labelRadius);
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + pi / 2);

      tp.text = TextSpan(
        text: label,
        style: TextStyle(
          color: deg == 0
              ? accentRed
              : isPrimary
                  ? const Color(0xFF141414)
                  : Colors.black.withValues(alpha: 0.45),
          fontSize: isPrimary ? radius * 0.115 : radius * 0.065,
          fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: 1.0,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    });
  }

  void _drawCrosshairAndRings(Canvas canvas, double radius) {
    final ringPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset.zero, radius * 0.63, ringPaint);
    canvas.drawCircle(Offset.zero, radius * 0.42, ringPaint);

    final crosshairPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(-radius * 0.42, 0),
      Offset(radius * 0.42, 0),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(0, -radius * 0.42),
      Offset(0, radius * 0.42),
      crosshairPaint,
    );
  }

  void _drawMagneticNeedle(Canvas canvas, double radius) {
    final needleLength = radius * 0.62;
    final needleWidth = radius * 0.075;

    final darkerRed = Color.lerp(accentRed, Colors.black, 0.22)!;
    final northLeftPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(-needleWidth, 0)
      ..lineTo(0, 0)
      ..close();

    final northRightPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(needleWidth, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(northLeftPath, Paint()..color = accentRed);
    canvas.drawPath(northRightPath, Paint()..color = darkerRed);
    final southLeftPath = Path()
      ..moveTo(0, needleLength)
      ..lineTo(-needleWidth, 0)
      ..lineTo(0, 0)
      ..close();

    final southRightPath = Path()
      ..moveTo(0, needleLength)
      ..lineTo(needleWidth, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(southLeftPath, Paint()..color = const Color(0xFF333333));
    canvas.drawPath(southRightPath, Paint()..color = const Color(0xFF141414));
  }

  void _drawCenterHub(Canvas canvas, Offset center, double radius) {
    final hubRadius = radius * 0.25;
    canvas.drawCircle(
      center,
      hubRadius * 1.07,
      Paint()..color = const Color(0xFF1E1E1E),
    );
    final hubPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF2F4F7)],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius));
    canvas.drawCircle(center, hubRadius, hubPaint);

    canvas.drawCircle(
      center,
      hubRadius * 0.94,
      Paint()
        ..color = accentRed.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final cardinalPainter = TextPainter(
      text: TextSpan(
        text: cardinalText,
        style: TextStyle(
          color: accentRed,
          fontSize: radius * 0.085,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    cardinalPainter.paint(
      canvas,
      Offset(
          center.dx - cardinalPainter.width / 2, center.dy - hubRadius * 0.68),
    );
    final degreePainter = TextPainter(
      text: TextSpan(
        text: headingText,
        style: TextStyle(
          color: const Color(0xFF141414),
          fontSize: radius * 0.095,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    degreePainter.paint(
      canvas,
      Offset(center.dx - degreePainter.width / 2,
          center.dy - degreePainter.height / 2 + 2),
    );
    final axisPainter = TextPainter(
      text: TextSpan(
        text: axisText,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.55),
          fontSize: radius * 0.055,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    axisPainter.paint(
      canvas,
      Offset(center.dx - axisPainter.width / 2, center.dy + hubRadius * 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassCanvasPainter oldDelegate) {
    return oldDelegate.rotationRadians != rotationRadians ||
        oldDelegate.headingText != headingText ||
        oldDelegate.axisText != axisText ||
        oldDelegate.accentRed != accentRed;
  }
}
