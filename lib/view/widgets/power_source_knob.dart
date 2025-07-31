import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/power_source_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class InnerDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.75;

    final paint = Paint()
      ..color = powerSourceKnobColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class RadialDialPainter extends CustomPainter {
  final double value;
  final double max;
  final Color color;

  RadialDialPainter({
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.9;

    final paint = Paint()
      ..color = powerSourceKnobColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 4;

    const startAngle = 3 * pi / 4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      6 * pi / 4,
      false,
      paint,
    );

    final progressPaint = Paint()
      ..color = primaryRed
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 9;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      6 * pi / 4 * (value / max),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
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
    final pointerLength = radius + 15;

    final pointerPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 4;

    final pointerStart = Offset(
      center.dx + radius * cos(pointerAngle),
      center.dy + radius * sin(pointerAngle),
    );
    final pointerEnd = Offset(
      center.dx + pointerLength * cos(pointerAngle),
      center.dy + pointerLength * sin(pointerAngle),
    );

    canvas.drawLine(pointerStart, pointerEnd, pointerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PowerSourceKnob extends StatefulWidget {
  const PowerSourceKnob({super.key, required this.maxValue, required this.pin});

  final double maxValue;
  final Pin pin;

  @override
  // ignore: library_private_types_in_public_api
  _PowerSourceKnobState createState() => _PowerSourceKnobState();
}

class _PowerSourceKnobState extends State<PowerSourceKnob> {
  double outerValue = 0.0;
  late final double maxValue = widget.maxValue;

  final double initialAngle = 150 * pi / 180;
  double previousAngle = 0.0;
  bool isDragging = true;

  @override
  void initState() {
    super.initState();
    previousAngle = initialAngle;
  }

  @override
  Widget build(BuildContext context) {
    PowerSourceStateProvider powerSourceStateProvider =
        Provider.of<PowerSourceStateProvider>(context);
    outerValue = powerSourceStateProvider.valueToIndex(
      powerSourceStateProvider.getValue(widget.pin),
      widget.pin,
    );
    void updateOuterValue(double angle) {
      const startAngle = 155 * pi / 180;
      const endAngle = 355 * pi / 180;

      const totalAngle = endAngle - startAngle;

      final numSections = maxValue;

      final anglePerSection = totalAngle / numSections;

      final section = ((angle - startAngle) / anglePerSection).round();

      final clampedSection = section.clamp(0, numSections);

      setState(() async {
        outerValue = clampedSection.toDouble();
        await powerSourceStateProvider.setValue(
            powerSourceStateProvider.indexToValue(
              outerValue,
              widget.pin,
            ),
            widget.pin);
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

      const startAngle = 150 * pi / 180;
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
          painter: RadialDialPainter(
            value: outerValue,
            max: maxValue,
            color: primaryRed,
          ),
          child: SizedBox(
            width: 200,
            height: 200,
          ),
        ),
        CustomPaint(
          painter: InnerDialPainter(),
          child: SizedBox(
            width: 180,
            height: 180,
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
              value: outerValue,
              max: maxValue,
              color: primaryRed,
            ),
            child: SizedBox(
              width: 140,
              height: 140,
            ),
          ),
        ),
      ],
    );
  }
}
