import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'dart:math';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

import '../../theme/colors.dart';

class GaugeWidget extends StatelessWidget {
  final AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final double gaugeSize;
  final double currentValue;
  final double currentValueFontSize;
  final double minValue;
  final double maxValue;
  final String unit;

  GaugeWidget({
    super.key,
    required this.gaugeSize,
    required this.currentValue,
    required this.maxValue,
    required this.minValue,
    required this.unit,
    required this.currentValueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = min(constraints.maxWidth, constraints.maxHeight);
        final adaptiveGaugeSize =
            min(gaugeSize, maxSize * 0.9).clamp(80.0, 300.0);

        final adaptiveFontSize = (adaptiveGaugeSize * 0.08).clamp(10.0, 20.0);
        final errorFontSize = (adaptiveFontSize * 0.4).clamp(6.0, 10.0);

        double range = maxValue - minValue;
        double normalizedValue =
            range > 0 ? (currentValue - minValue) / range : 0;
        double gaugeValue = (normalizedValue * 100).clamp(0.0, 100.0);

        return Center(
          child: SizedBox(
            width: adaptiveGaugeSize,
            height: adaptiveGaugeSize,
            child: _buildGauge(
                adaptiveGaugeSize, gaugeValue, adaptiveFontSize, errorFontSize),
          ),
        );
      },
    );
  }

  Widget _buildGauge(
      double size, double gaugeValue, double fontSize, double errorFontSize) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipOval(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: gaugeBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                size * 0.06,
                0,
                size * 0.06,
                size * 0.13,
              ),
              child: _buildAnimatedGauge(size, gaugeValue),
            ),
          ),
        ),
        _buildCenterDisplay(size, fontSize, errorFontSize),
        ..._buildTickMarks(size),
      ],
    );
  }

  Widget _buildAnimatedGauge(double size, double gaugeValue) {
    return AnimatedRadialGauge(
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      radius: size * 0.45,
      value: gaugeValue,
      axis: GaugeAxis(
        min: 0,
        max: 100,
        degrees: 270,
        style: GaugeAxisStyle(
          thickness: (size * 0.05).clamp(3.0, 15.0),
          background: gaugeAxisColor,
          segmentSpacing: 2,
        ),
        progressBar: GaugeProgressBar.basic(
          color: gaugeProgressColor,
        ),
        pointer: GaugePointer.needle(
          width: (size * 0.09).clamp(4.0, 20.0),
          height: (size * 0.35).clamp(15.0, 80.0),
          borderRadius: ((size * 0.09).clamp(4.0, 20.0)) / 2,
          color: gaugeNeedleColor,
        ),
      ),
    );
  }

  Widget _buildCenterDisplay(
      double size, double fontSize, double errorFontSize) {
    return Container(
      width: size * 0.6,
      height: size * 0.6,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${currentValue.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: blackTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (currentValue > maxValue)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    appLocalizations.maxScaleError,
                    style: TextStyle(
                      fontSize: errorFontSize,
                      color: gaugeMaxScaleLimitColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildTickMarks(double size) {
    return List.generate(8, (index) {
      final angle = (index * 45.0 - 135) * (pi / 180);
      final tickRadius = size * 0.35;
      final tickLength = (size * 0.04).clamp(3.0, 12.0);
      final tickWidth = (size * 0.008).clamp(1.5, 4.0);

      return Positioned(
        left: size / 2 + (tickRadius * cos(angle)) - tickWidth / 2,
        top: size / 2 + (tickRadius * sin(angle)) - tickLength / 2,
        child: Transform.rotate(
          angle: angle + (pi / 2),
          child: Container(
            width: tickWidth,
            height: tickLength,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(250),
              borderRadius: BorderRadius.circular(tickWidth / 2),
            ),
          ),
        ),
      );
    });
  }
}
