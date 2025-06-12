import 'package:flutter/material.dart';
import 'package:pslab/constants.dart';

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
              color: Colors.black,
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
                    label: 'Max (Lx)', value: maxValue, fontSize: statFontSize),
                StatItem(
                    label: 'Min (Lx)', value: minValue, fontSize: statFontSize),
                StatItem(
                    label: 'Avg (Lx)', value: avgValue, fontSize: statFontSize),
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
    final valueFontSize = screenWidth < 400 ? 14.0 : 16.0;
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
                color: Colors.black,
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
                border: Border.all(color: Colors.pink.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: valueFontSize,
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
