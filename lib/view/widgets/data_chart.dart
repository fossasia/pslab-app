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
  final int binCount;

  const DistributionHistogram({
    super.key,
    required this.rawValues,
    required this.min,
    required this.max,
    this.binCount = 5,
  });

  List<int> _computeBins() {
    if (rawValues.isEmpty || min >= max) {
      return List.filled(binCount, 0);
    }

    final bins = List<int>.filled(binCount, 0);
    final range = max - min;

    for (final value in rawValues) {
      int binIndex = ((value - min) / range * binCount).floor();
      if (binIndex >= binCount) binIndex = binCount - 1;
      if (binIndex < 0) binIndex = 0;
      bins[binIndex]++;
    }

    return bins;
  }

  @override
  Widget build(BuildContext context) {
    final bins = _computeBins();
    final maxCount = bins.isEmpty ? 0 : bins.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 110,
      width: double.infinity,
      child: CustomPaint(
        painter: _HistogramWithAxesPainter(
          bins: bins,
          minVal: min,
          maxVal: max,
          maxCount: maxCount,
          barColor: Colors.grey.shade700,
          axisColor: Colors.black54,
        ),
      ),
    );
  }
}

class _HistogramWithAxesPainter extends CustomPainter {
  final List<int> bins;
  final double minVal;
  final double maxVal;
  final int maxCount;
  final Color barColor;
  final Color axisColor;

  _HistogramWithAxesPainter({
    required this.bins,
    required this.minVal,
    required this.maxVal,
    required this.maxCount,
    required this.barColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 26.0;
    const double bottomMargin = 18.0;
    const double topMargin = 6.0;
    const double rightMargin = 6.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(leftMargin, topMargin),
      Offset(leftMargin, topMargin + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftMargin, topMargin + chartHeight),
      Offset(leftMargin + chartWidth, topMargin + chartHeight),
      axisPaint,
    );

    if (bins.isNotEmpty && maxCount > 0) {
      final barWidth = chartWidth / bins.length;
      final gap = barWidth * 0.12;

      for (int i = 0; i < bins.length; i++) {
        final count = bins[i];
        final barHeight = (count / maxCount) * chartHeight;

        final left = leftMargin + (i * barWidth) + (gap / 2);
        final top = topMargin + chartHeight - barHeight;
        final right = leftMargin + ((i + 1) * barWidth) - (gap / 2);
        final bottom = topMargin + chartHeight;

        if (barHeight > 0) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTRB(left, top, right, bottom),
            const Radius.circular(2),
          );
          canvas.drawRRect(rect, barPaint);
        }
      }
    }

    _drawText(
      canvas,
      text: '$maxCount',
      offset: Offset(0, topMargin - 4),
      width: leftMargin - 4,
      align: TextAlign.right,
    );

    _drawText(
      canvas,
      text: '0',
      offset: Offset(0, topMargin + chartHeight - 8),
      width: leftMargin - 4,
      align: TextAlign.right,
    );

    canvas.drawLine(
      Offset(leftMargin - 3, topMargin),
      Offset(leftMargin, topMargin),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftMargin - 3, topMargin + chartHeight),
      Offset(leftMargin, topMargin + chartHeight),
      axisPaint,
    );

    final midVal = (minVal + maxVal) / 2;
    _drawText(
      canvas,
      text: minVal.toStringAsFixed(1),
      offset: Offset(leftMargin, topMargin + chartHeight + 3),
      width: chartWidth / 3,
      align: TextAlign.left,
    );

    _drawText(
      canvas,
      text: midVal.toStringAsFixed(1),
      offset: Offset(
          leftMargin + (chartWidth / 2) - 20, topMargin + chartHeight + 3),
      width: 40,
      align: TextAlign.center,
    );

    _drawText(
      canvas,
      text: maxVal.toStringAsFixed(1),
      offset: Offset(leftMargin + chartWidth - (chartWidth / 3),
          topMargin + chartHeight + 3),
      width: chartWidth / 3,
      align: TextAlign.right,
    );

    canvas.drawLine(
      Offset(leftMargin, topMargin + chartHeight),
      Offset(leftMargin, topMargin + chartHeight + 3),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftMargin + (chartWidth / 2), topMargin + chartHeight),
      Offset(leftMargin + (chartWidth / 2), topMargin + chartHeight + 3),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftMargin + chartWidth, topMargin + chartHeight),
      Offset(leftMargin + chartWidth, topMargin + chartHeight + 3),
      axisPaint,
    );
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double width,
    required TextAlign align,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 8.5,
          color: axisColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _HistogramWithAxesPainter oldDelegate) {
    return oldDelegate.bins != bins ||
        oldDelegate.minVal != minVal ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.maxCount != maxCount;
  }
}
