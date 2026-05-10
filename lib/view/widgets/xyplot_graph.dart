import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class XYPlotGraph extends StatefulWidget {
  const XYPlotGraph({super.key});

  @override
  State<StatefulWidget> createState() => _XYPlotGraphState();
}

class _XYPlotGraphState extends State<XYPlotGraph> {
  Widget titleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      color: chartTextColor,
      fontSize: 9,
    );
    return SideTitleWidget(
      meta: meta,
      child: Text(
        maxLines: 1,
        meta.formattedValue,
        style: style,
      ),
    );
  }

  FlLine getHorizontalVerticalLine(double value) {
    if ((value).abs() <= 0.1) {
      return const FlLine(
        color: Colors.white70,
        strokeWidth: 1,
        dashArray: [8, 4],
      );
    } else {
      return const FlLine(
        color: Colors.blueGrey,
        strokeWidth: 0.4,
        dashArray: [8, 4],
      );
    }
  }

  FlLine getVerticalVerticalLine(double value) {
    if ((value).abs() <= 0.1) {
      return const FlLine(
        color: Colors.white70,
        strokeWidth: 1,
        dashArray: [8, 4],
      );
    } else {
      return const FlLine(
        color: Colors.blueGrey,
        strokeWidth: 0.4,
        dashArray: [8, 4],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep this read (listen:false) so axis labels don't rebuild too much
    final oscilloscopeStateProvider =
        Provider.of<OscilloscopeStateProvider>(context, listen: false);

    return Consumer<OscilloscopeStateProvider>(
      builder: (context, provider, _) {
        return Listener(
          // KEY: without this, scroll events often get consumed inside the chart subtree
          behavior: HitTestBehavior.opaque,
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              final bool zoomIn = pointerSignal.scrollDelta.dy < 0;

              // Use X zoom to keep behavior consistent with normal oscilloscope plot
              provider.zoomX(zoomIn: zoomIn);

              // If you *prefer* zooming Y for XYPlot, use this instead:
              // provider.zoomY(zoomIn: zoomIn);
            }
          },
          child: LineChart(
            LineChartData(
              backgroundColor: chartBackgroundColor,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  axisNameWidget: Text(
                    '${oscilloscopeStateProvider.xyPlotAxis1} (V)',
                    style: TextStyle(
                      color: chartTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  sideTitles: SideTitles(
                    maxIncluded: true,
                    interval: 4,
                    reservedSize: 30,
                    showTitles: true,
                    getTitlesWidget: titleWidgets,
                  ),
                ),
                leftTitles: AxisTitles(
                  // NOTE: your original code used xyPlotAxis1 for left too
                  // (keeping same so you don't change behavior)
                  axisNameWidget: Text(
                    '${oscilloscopeStateProvider.xyPlotAxis1} (V)',
                    style: TextStyle(
                      color: chartTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  sideTitles: SideTitles(
                    maxIncluded: true,
                    interval: 4,
                    reservedSize: 30,
                    showTitles: true,
                    getTitlesWidget: titleWidgets,
                  ),
                ),
                topTitles: AxisTitles(
                  axisNameWidget: Text(
                    '${oscilloscopeStateProvider.xyPlotAxis2} (V)',
                    style: TextStyle(
                      color: chartTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  sideTitles: SideTitles(
                    maxIncluded: true,
                    interval: 4,
                    reservedSize: 20,
                    showTitles: true,
                    getTitlesWidget: titleWidgets,
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: 4,
                verticalInterval: 4,
                getDrawingHorizontalLine: getHorizontalVerticalLine,
                getDrawingVerticalLine: getVerticalVerticalLine,
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: chartBorderColor),
                  left: BorderSide(color: chartBorderColor),
                  top: BorderSide(color: chartBorderColor),
                  right: BorderSide(color: chartBorderColor),
                ),
              ),
              maxX: 16,
              maxY: 16,
              minX: -16,
              minY: -16,
              clipData: const FlClipData.all(),
              lineBarsData: provider.createXYPlot(), // use provider (reactive)
            ),
          ),
        );
      },
    );
  }
}
