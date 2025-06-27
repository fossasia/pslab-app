import 'package:flutter/material.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/theme/colors.dart';

class Instrumentstats extends StatelessWidget {
  final String unit;
  final double titleFontSize;
  final double statFontSize;
  final double minValue;
  final double maxValue;
  final double avgValue;

  const Instrumentstats(
      {super.key,
      required this.unit,
      required this.titleFontSize,
      required this.avgValue,
      required this.maxValue,
      required this.minValue,
      required this.statFontSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Text(
            builtIn,
            style: TextStyle(
              color: blackTextColor,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatItem(
                    label: '$maxLabel ($unit)',
                    value: maxValue,
                    fontSize: statFontSize),
                StatItem(
                    label: '$minLabel ($unit)',
                    value: minValue,
                    fontSize: statFontSize),
                StatItem(
                    label: '$avgLabel ($unit)',
                    value: avgValue,
                    fontSize: statFontSize),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final double value;
  final double fontSize;

  const StatItem(
      {super.key,
      required this.label,
      required this.fontSize,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 400 ? 15.0 : 20.0;
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              label,
              style: TextStyle(
                color: cardContentColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: instrumentStatBoxColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: cardContentColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
