import 'package:flutter/material.dart';
import 'package:girix_code_gauge/girix_code_gauge.dart';
import 'package:pslab/theme/colors.dart';

class InstrumentGauge extends StatelessWidget {
  final double currentValue;
  final double minValue;
  final double maxValue;
  final int interval; 
  final String unit;
  final double size;
  final int decimalPlaces;

  const InstrumentGauge({
    super.key,
    required this.currentValue,
    required this.maxValue,
    required this.unit,
    required this.size,
    this.minValue = 0.0,
    this.interval = 20,
    this.decimalPlaces = 1,
  });

  @override
  Widget build(BuildContext context) {
    double clampedValue = currentValue.clamp(minValue, maxValue);

    return Stack(
      alignment: Alignment.center,
      children: [
        GxRadialGauge(
          value: GaugeValue(
              value: clampedValue.toDouble(),
              min: minValue.toDouble(),
              max: maxValue.toDouble()),
          size: Size(size.toDouble(), size.toDouble()),
          startAngleInDegree: 140.0,
          sweepAngleInDegree: 260.0,
          showValueAtCenter: false,
          showMajorTicks: true,
          showLabels: true,
          interval: interval,
          labelTickStyle: const RadialTickLabelStyle(
            padding: 22,
            position: RadialElementPosition.outside,
            style: TextStyle(
              fontSize: 8,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          majorTickStyle: RadialTickStyle(
            color: Colors.blueGrey.shade300,
            thickness: 2,
            length: 12,
            position: RadialElementPosition.outside,
            alignment: RadialElementAlignment.start,
          ),
          style: const RadialGaugeStyle(
            color: Color(0xFFEEEEEE),
            thickness: 15,
            gradient: LinearGradient(
              colors: [
                gaugeGradientStart,
                gaugeGradientCenter,
                gaugeGradientEnd
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          showNeedle: true,
          needle: const RadialNeedle(
            color: Color(0xFF424242),
            shape: RadialNeedleShape.tapperedLine,
            thickness: 8,
            alignment: RadialElementAlignment.end,
            circle: NeedleCircle(
              radius: 8,
              innerColor: Colors.black87,
              paintingStyle: PaintingStyle.fill,
            ),
          ),
        ),
        Positioned(
          bottom: size * 0.12,
          child: Column(
            children: [
              Text(
                clampedValue.toStringAsFixed(decimalPlaces),
                style: TextStyle(
                  fontSize: (size * 0.08).clamp(12.0, 24.0),
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unit.toUpperCase(),
                  style: TextStyle(
                    fontSize: (size * 0.045).clamp(8.0, 12.0),
                    fontWeight: FontWeight.w800,
                    color: Colors.blueGrey,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
