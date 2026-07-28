import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/theme/colors.dart';

class ReportGroupBox extends StatelessWidget {
  final String title;
  final Widget child;

  const ReportGroupBox({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          padding:
              const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: primaryRed),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 1,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: oscilloscopeOptionTitleBoxColor),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: oscilloscopeOptionTitleColor,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class UniversalStatText extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const UniversalStatText(
      {super.key,
      required this.label,
      required this.value,
      this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isHighlight ? primaryRed : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class SpecificMetricText extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const SpecificMetricText(
      {super.key,
      required this.label,
      required this.value,
      required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            text: value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
            children: [
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class SignalPieChart extends StatelessWidget {
  final double low;
  final double mid;
  final double high;

  const SignalPieChart(
      {super.key, required this.low, required this.mid, required this.high});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 24,
          sections: [
            PieChartSectionData(
                color: Colors.blue.shade400,
                value: low,
                title: '${low.toInt()}%',
                radius: 18,
                titleStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            PieChartSectionData(
                color: Colors.grey.shade400,
                value: mid,
                title: '${mid.toInt()}%',
                radius: 18,
                titleStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            PieChartSectionData(
                color: primaryRed,
                value: high,
                title: '${high.toInt()}%',
                radius: 18,
                titleStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class MinimalSparkline extends StatelessWidget {
  final List<FlSpot> spots;

  const MinimalSparkline({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    if (spots.length < 2) {
      return const SizedBox(
        height: 140,
        child: Center(
            child: Text('Insufficient data to chart',
                style: TextStyle(color: Colors.black54))),
      );
    }

    double rawMinY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double rawMaxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    double maxX = spots.last.x;

    double paddedMinY =
        rawMinY == rawMaxY ? rawMinY - 1 : rawMinY - (rawMaxY - rawMinY) * 0.1;
    double paddedMaxY =
        rawMinY == rawMaxY ? rawMaxY + 1 : rawMaxY + (rawMaxY - rawMinY) * 0.1;

    return SizedBox(
      height: 140,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          minY: paddedMinY,
          maxY: paddedMaxY,
          minX: spots.first.x,
          maxX: maxX,
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.black87,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true, color: primaryRed.withValues(alpha: 0.05)),
            ),
          ],
        ),
      ),
    );
  }
}

class DistributionHistogram extends StatelessWidget {
  final List<double> rawValues;
  final double min;
  final double max;

  const DistributionHistogram(
      {super.key,
      required this.rawValues,
      required this.min,
      required this.max});

  @override
  Widget build(BuildContext context) {
    if (rawValues.isEmpty) return const SizedBox();

    const int bucketCount = 10;
    List<int> buckets = List.filled(bucketCount, 0);
    double range = max - min == 0 ? 1 : max - min;

    int maxFreq = 0;
    for (double val in rawValues) {
      int index = ((val - min) / range * (bucketCount - 1)).floor();
      if (index >= bucketCount) index = bucketCount - 1;
      if (index < 0) index = 0;
      buckets[index]++;
      if (buckets[index] > maxFreq) maxFreq = buckets[index];
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < bucketCount; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: buckets[i].toDouble(),
              color: Colors.white,
              borderSide: const BorderSide(color: Colors.black87, width: 1.5),
              width: 10,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 120,
      width: double.infinity,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxFreq * 1.1,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}
