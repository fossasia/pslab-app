import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'dart:math';
import 'package:pslab/constants.dart';

class GaugeWidget extends StatelessWidget {
  final double gaugeSize;
  final double currentValue;
  final double currentValueFontSize;
  final double minValue;
  final double maxValue;
  final String unit;
  const GaugeWidget(
      {super.key,
      required this.gaugeSize,
      required this.currentValue,
      required this.maxValue,
      required this.minValue,
      required this.unit,
      required this.currentValueFontSize});
  @override
  Widget build(BuildContext context) {
    double range = maxValue - minValue;
    double normalizedValue = (currentValue - minValue) / range;
    double gaugeValue = normalizedValue * 100;
    gaugeValue = gaugeValue.clamp(0.0, 100.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Container(
                  width: gaugeSize,
                  height: gaugeSize,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.5,
                    maxHeight: MediaQuery.of(context).size.width * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent[400],
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gaugeSize * 0.06, 0,
                        gaugeSize * 0.06, gaugeSize * 0.13),
                    child: AnimatedRadialGauge(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      radius: gaugeSize * 0.45,
                      value: gaugeValue,
                      axis: GaugeAxis(
                        min: 0,
                        max: 100,
                        degrees: 270,
                        style: GaugeAxisStyle(
                          thickness: gaugeSize * 0.05,
                          background: Colors.cyanAccent[100],
                          segmentSpacing: 2,
                        ),
                        progressBar: const GaugeProgressBar.basic(
                          color: Colors.white,
                        ),
                        pointer: GaugePointer.needle(
                          width: gaugeSize * 0.09,
                          height: gaugeSize * 0.35,
                          borderRadius: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: gaugeSize * 0.6,
                height: gaugeSize * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${currentValue.toStringAsFixed(1)} $unit',
                      style: TextStyle(
                        fontSize: currentValueFontSize * 1.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (currentValue > maxValue)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          maxScaleError,
                          style: TextStyle(
                            fontSize: currentValueFontSize * 0.4,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ...List.generate(8, (index) {
                final angle = (index * 45.0 - 135) * (3.14159 / 180);
                final tickRadius = gaugeSize * 0.35;
                final tickLength = gaugeSize * 0.04;
                return Positioned(
                  left: gaugeSize / 2 + (tickRadius * cos(angle)) - 1,
                  top: gaugeSize / 2 +
                      (tickRadius * sin(angle)) -
                      tickLength / 2,
                  child: Transform.rotate(
                    angle: angle + (3.14159 / 2),
                    child: Container(
                      width: 3,
                      height: tickLength,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(250),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
