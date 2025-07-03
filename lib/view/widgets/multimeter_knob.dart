import 'dart:math';

import 'package:flutter/material.dart';

class InnerDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.7;

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class InnerDialFillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.7;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class InnerPointerPainter extends CustomPainter {
  final double value;
  final double max;
  final Color color;

  InnerPointerPainter({
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.5;

    final pointerAngle = 3 * pi / 4 + 6 * pi / 4 * (value / max);

    final pointerPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 30;

    final pointerStart = Offset(
      center.dx - radius * cos(pointerAngle),
      center.dy - radius * sin(pointerAngle),
    );
    final pointerEnd = Offset(
      center.dx + radius * cos(pointerAngle),
      center.dy + radius * sin(pointerAngle),
    );

    final pointerPaintInner = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 10;
    final pointerStartInner = Offset(
      center.dx + radius * 1.1 * cos(pointerAngle),
      center.dy + radius * 1.1 * sin(pointerAngle),
    );
    final pointerEndInner = Offset(
      center.dx + radius * 0.9 * cos(pointerAngle),
      center.dy + radius * 0.9 * sin(pointerAngle),
    );
    canvas.drawLine(pointerStart, pointerEnd, pointerPaint);
    canvas.drawLine(pointerStartInner, pointerEndInner, pointerPaintInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class RadialLabelPainter extends CustomPainter {
  final List<String> labels;
  final List<Color> labelColors;
  final double radius;
  final TextStyle baseTextStyle;
  final double arcRadiusOffset;
  final double arcLength;
  final double arcStrokeWidth;

  RadialLabelPainter({
    required this.labels,
    required this.labelColors,
    required this.radius,
    this.baseTextStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
    this.arcRadiusOffset = 0,
    this.arcLength = pi / 18,
    this.arcStrokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleIncrement = 2 * pi / labels.length;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < labels.length; i++) {
      final angle = i * angleIncrement - pi / 2;
      final color = labelColors[i];

      final textOffset = Offset(
        center.dx + (radius + 20) * cos(angle),
        center.dy + (radius + 20) * sin(angle),
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: baseTextStyle.copyWith(color: color),
      );
      textPainter.layout();

      final offsetCentered = Offset(
        textOffset.dx - textPainter.width / 2,
        textOffset.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offsetCentered);

      final arcPaint = Paint()
        ..color = color
        ..strokeWidth = arcStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final arcRadius = radius + arcRadiusOffset;
      final arcStartAngle = angle - arcLength / 2;
      final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
      canvas.drawArc(arcRect, arcStartAngle, arcLength, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RadialDial extends StatefulWidget {
  const RadialDial({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RadialDialState createState() => _RadialDialState();
}

class _RadialDialState extends State<RadialDial> {
  double outerValue = 1.0;
  final double maxValue = 11.0;

  final double initialAngle = 155 * pi / 180;
  double previousAngle = 0.0;
  bool isDragging = true;

  @override
  void initState() {
    super.initState();
    previousAngle = initialAngle;
  }

  @override
  Widget build(BuildContext context) {
    void updateOuterValue(double angle) {
      const startAngle = 155 * pi / 270;
      const endAngle = 360 * pi / 180;

      const totalAngle = endAngle - startAngle;

      final numSections = maxValue;

      final anglePerSection = totalAngle / numSections;

      final section = ((angle - startAngle) / anglePerSection).round();

      final clampedSection = section.clamp(1, numSections);

      setState(() {
        outerValue = clampedSection.toDouble();
      });
    }

    void updateAngle(Offset position, Size size) {
      if (!isDragging) return;

      final center = Offset(size.width / 2, size.height / 2);
      final dx = position.dx - center.dx;
      final dy = position.dy - center.dy;
      final distanceFromCenter = sqrt(dx * dx + dy * dy);

      if (distanceFromCenter > size.width / 2) return;

      var angle = atan2(dy, dx);

      if (angle < 0) {
        angle += 2 * pi;
      }

      const startAngle = 155 * pi / 270;
      const endAngle = 360 * pi / 180;

      if (angle >= startAngle && angle <= endAngle) {
        if ((angle >= previousAngle && angle <= endAngle) ||
            (angle < startAngle && previousAngle < startAngle) ||
            (angle - previousAngle).abs() < pi) {
          setState(() {
            updateOuterValue(angle);
          });
        }
        previousAngle = angle;
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: InnerDialFillPainter(),
          child: Container(
            color: Colors.transparent,
            width: 300,
          ),
        ),
        GestureDetector(
          onPanUpdate: (details) {
            if (isDragging) {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              Offset localPosition =
                  renderBox.globalToLocal(details.globalPosition);
              updateAngle(localPosition, renderBox.size);
            }
          },
          child: CustomPaint(
            painter: InnerPointerPainter(
              value: 5.0,
              max: maxValue,
              color: const Color(0xFFD32F2F),
            ),
            child: SizedBox(
              width: 430,
              height: 450,
            ),
          ),
        ),
        CustomPaint(
          painter: InnerDialPainter(),
          child: Container(
            color: Colors.transparent,
            width: 300,
          ),
        ),
        CustomPaint(
          painter: RadialLabelPainter(
            labels: [
              'CH1',
              'CAP',
              'VOL',
              'RES',
              'CAP',
              'LA1',
              'LA2',
              'LA3',
              'LA4',
              'CH3',
              'CH2'
            ],
            labelColors: [
              Color(0xFFD32F2F), // CH1
              Color(0xFFD32F2F), // CAP
              Color(0xFFD32F2F), // AN8
              Colors.black, // RES
              Colors.black, // CAP
              Colors.black, // ID1
              Colors.black, // ID2
              Colors.black, // ID3
              Colors.black, // ID4
              Color(0xFFD32F2F), // CH3
              Color(0xFFD32F2F), // CH2
            ],
            radius: 112,
          ),
          child: SizedBox(
            width: 430,
            height: 450,
          ),
        )
      ],
    );
  }
}
