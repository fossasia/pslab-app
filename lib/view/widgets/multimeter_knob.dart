import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/multimeter_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class InnerDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.7;

    final paint = Paint()
      ..color = multimeterBorderBlack
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
      ..color = innerDialFillColor
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

    final pointerAngle = -pi / 2 + (2 * pi * (value / max));

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
      ..color = innerPointerColor
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

class MultimeterKnob extends StatefulWidget {
  const MultimeterKnob({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MultimeterKnobState createState() => _MultimeterKnobState();
}

class _MultimeterKnobState extends State<MultimeterKnob> {
  final double maxValue = 11.0;
  bool isDragging = true;
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late List<String> knobMarker;
  @override
  void initState() {
    super.initState();
    knobMarker = [
      appLocalizations.knobMarkerCh1,
      appLocalizations.knobMarkerCap,
      appLocalizations.knobMarkerVol,
      appLocalizations.knobMarkerRes,
      appLocalizations.knobMarkerCap,
      appLocalizations.knobMarkerLa1,
      appLocalizations.knobMarkerLa2,
      appLocalizations.knobMarkerLa3,
      appLocalizations.knobMarkerLa4,
      appLocalizations.knobMarkerCh3,
      appLocalizations.knobMarkerCh2,
    ];
  }

  @override
  Widget build(BuildContext context) {
    MultimeterStateProvider multimeterStateProvider =
        Provider.of<MultimeterStateProvider>(context, listen: false);

    void updateSelectedIndex(double angle) {
      const startAngle = -pi / 2;
      const totalAngle = 2 * pi;

      final angleNormalized = (angle - startAngle + totalAngle) % totalAngle;

      final numSections = maxValue;
      final anglePerSection = totalAngle / numSections;

      final section = (angleNormalized / anglePerSection).round();

      final clampedSection = section.clamp(0, numSections - 1);

      setState(() {
        multimeterStateProvider.setSelectedIndex(clampedSection.toInt());
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

      setState(() {
        updateSelectedIndex(angle);
      });
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: InnerDialFillPainter(),
          child: SizedBox(
            width: 300.w,
            height: 300.h,
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
              value: multimeterStateProvider.getSelectedIndex().toDouble(),
              max: maxValue,
              color: pointerColor,
            ),
            child: SizedBox(
              width: 360.w,
              height: 360.h,
            ),
          ),
        ),
        IgnorePointer(
          ignoring: true,
          child: CustomPaint(
            painter: InnerDialPainter(),
            child: SizedBox(
              height: 300.h,
              width: 300.w,
            ),
          ),
        ),
        IgnorePointer(
          ignoring: true,
          child: CustomPaint(
            painter: RadialLabelPainter(
              labels: knobMarker,
              labelColors: knobLabelColors,
              radius: 112.r,
            ),
          ),
        )
      ],
    );
  }
}
