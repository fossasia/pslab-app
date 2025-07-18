import 'dart:math';
import 'package:flutter/material.dart';

class ServoSlider extends StatefulWidget {
  final double progress;
  final double maxProgress;
  final double startAngle;
  final double sweepAngle;
  final double trackWidth;
  final double thumbRadius;
  final double size;
  final bool clockwise;
  final ValueChanged<double> onChanged;
  final Color trackColor;
  final Color progressColor;
  final Color thumbColor;

  const ServoSlider({
    super.key,
    required this.progress,
    required this.maxProgress,
    required this.onChanged,
    this.startAngle = 270,
    this.sweepAngle = 360,
    this.trackWidth = 10,
    this.thumbRadius = 12,
    this.size = 200,
    this.clockwise = true,
    this.trackColor = Colors.grey,
    this.progressColor = Colors.red,
    this.thumbColor = Colors.cyan,
  });

  @override
  State<ServoSlider> createState() => _ServoSliderState();
}

class _ServoSliderState extends State<ServoSlider> {
  late double _angle;
  @override
  void initState() {
    super.initState();
    _angle = _valueToAngle(widget.progress.clamp(0, widget.maxProgress));
  }

  @override
  void didUpdateWidget(covariant ServoSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      setState(() {
        _angle = _valueToAngle(widget.progress.clamp(0, widget.maxProgress));
      });
    }
  }

  double _valueToAngle(double value) {
    return (value / widget.maxProgress) * widget.sweepAngle;
  }

  double _angleToValue(double angle) {
    return (angle / widget.sweepAngle) * widget.maxProgress;
  }

  void _onPanUpdate(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final vector = localPosition - center;
    double radians = atan2(vector.dy, vector.dx);
    double degrees = radians * 180 / pi;

    degrees = degrees < 0 ? 360 + degrees : degrees;

    double angleFromStart = (degrees - widget.startAngle) % 360;
    if (!widget.clockwise) {
      angleFromStart = widget.sweepAngle - angleFromStart;
    }

    if (angleFromStart < 0 || angleFromStart > widget.sweepAngle) return;

    setState(() {
      _angle = angleFromStart;
    });

    widget.onChanged(_angleToValue(_angle));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanUpdate: (details) => _onPanUpdate(details.localPosition),
        child: CustomPaint(
          painter: _ServoSliderPainter(
            angle: _angle,
            startAngle: widget.startAngle,
            sweepAngle: widget.sweepAngle,
            trackWidth: widget.trackWidth,
            thumbRadius: widget.thumbRadius,
            trackColor: widget.trackColor,
            progressColor: widget.progressColor,
            thumbColor: widget.thumbColor,
            clockwise: widget.clockwise,
          ),
        ),
      ),
    );
  }
}

class _ServoSliderPainter extends CustomPainter {
  final double angle;
  final double startAngle;
  final double sweepAngle;
  final double trackWidth;
  final double thumbRadius;
  final bool clockwise;
  final Color trackColor;
  final Color progressColor;
  final Color thumbColor;

  _ServoSliderPainter({
    required this.angle,
    required this.startAngle,
    required this.sweepAngle,
    required this.trackWidth,
    required this.thumbRadius,
    required this.trackColor,
    required this.progressColor,
    required this.thumbColor,
    required this.clockwise,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - thumbRadius;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startRadian = radians(startAngle);
    final sweepRadian = radians(sweepAngle);
    final progressRadian = radians(angle);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..color = trackColor
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..color = progressColor
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startRadian, sweepRadian * (clockwise ? 1 : -1), false,
        trackPaint);

    canvas.drawArc(rect, startRadian, progressRadian * (clockwise ? 1 : -1),
        false, progressPaint);

    final thumbAngle = radians(startAngle + (clockwise ? angle : -angle));
    final thumbOffset = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );

    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(thumbOffset, thumbRadius, thumbPaint);
  }

  double radians(double degrees) => degrees * pi / 180;

  @override
  bool shouldRepaint(covariant _ServoSliderPainter oldDelegate) {
    return angle != oldDelegate.angle;
  }
}
