import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';
import 'package:pslab/view/widgets/xyplot_graph.dart';

import '../../theme/colors.dart';

class OscilloscopeGraph extends StatefulWidget {
  const OscilloscopeGraph({super.key});

  @override
  State<StatefulWidget> createState() => _OscilloscopeGraphState();
}

class _OscilloscopeGraphState extends State<OscilloscopeGraph> {
  Widget sideTitleWidgets(double value, TitleMeta meta) {
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

  Widget topTitleWidgets(double value, TitleMeta meta) {
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

  @override
  Widget build(BuildContext context) {
    OscilloscopeStateProvider oscilloscopeStateProvider =
        Provider.of<OscilloscopeStateProvider>(context);
    return Consumer<OscilloscopeStateProvider>(
      builder: (context, provider, _) {
        if (oscilloscopeStateProvider.isXYPlotSelected) {
          return const SizedBox(
            child: XYPlotGraph(),
          );
        } else {
          return SizedBox(
            child: LineChart(
              LineChartData(
                backgroundColor: chartBackgroundColor,
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                    axisNameWidget: Text(
                      oscilloscopeStateProvider
                                  .oscilloscopeAxesScale.xAxisScale ==
                              875
                          ? 'Time (\u00b5s)'
                          : 'Time (ms)',
                      style: TextStyle(
                        fontSize: 10,
                        color: chartTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sideTitles: SideTitles(
                      maxIncluded: false,
                      interval: oscilloscopeStateProvider.oscilloscopeAxesScale
                          .getTimebaseInterval(),
                      reservedSize: 20,
                      showTitles: true,
                      getTitlesWidget: topTitleWidgets,
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'CH1 (V)',
                      style: TextStyle(
                        fontSize: 10,
                        color: chartTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sideTitles: SideTitles(
                      interval:
                          provider.oscilloscopeAxesScale.yAxisScaleMax / 4,
                      reservedSize: 30,
                      showTitles: true,
                      getTitlesWidget: sideTitleWidgets,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    axisNameWidget: Text(
                      'CH2 (V)',
                      style: TextStyle(
                        fontSize: 10,
                        color: chartTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sideTitles: SideTitles(
                      interval:
                          provider.oscilloscopeAxesScale.yAxisScaleMax / 4,
                      reservedSize: 30,
                      showTitles: true,
                      getTitlesWidget: sideTitleWidgets,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: true,
                  horizontalInterval:
                      provider.oscilloscopeAxesScale.yAxisScaleMax / 4,
                  verticalInterval: oscilloscopeStateProvider
                      .oscilloscopeAxesScale
                      .getTimebaseInterval(),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: chartBorderColor,
                    ),
                    left: BorderSide(
                      color: chartBorderColor,
                    ),
                    top: BorderSide(
                      color: chartBorderColor,
                    ),
                    right: BorderSide(
                      color: chartBorderColor,
                    ),
                  ),
                ),
                maxY: provider.oscilloscopeAxesScale.yAxisScaleMax,
                minY: provider.oscilloscopeAxesScale.yAxisScaleMin,
                maxX: oscilloscopeStateProvider
                            .oscilloscopeAxesScale.xAxisScale ==
                        875
                    ? oscilloscopeStateProvider.oscilloscopeAxesScale.xAxisScale
                    : oscilloscopeStateProvider
                            .oscilloscopeAxesScale.xAxisScale /
                        1000,
                minX: 0,
                clipData: const FlClipData.all(),
                lineBarsData: oscilloscopeStateProvider.createPlots(),
              ),
            ),
          );
        }
      },
    );
  }
}
