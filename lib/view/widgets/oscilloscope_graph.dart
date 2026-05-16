import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
    return Consumer<OscilloscopeStateProvider>(
      builder: (context, provider, _) {
        if (provider.isXYPlotSelected) {
          return const SizedBox(child: XYPlotGraph());
        }

        return SizedBox(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                if (pointerSignal.scrollDelta.dy < 0) {
                  provider.zoomIn();
                } else {
                  provider.zoomOut();
                }
              }
            },
            child: LineChart(
                  LineChartData(
                    backgroundColor: chartBackgroundColor,
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(
                        axisNameWidget: Text(
                          provider.isFourierTransformSelected
                              ? 'Frequency (Hz)'
                              : (provider.oscilloscopeAxesScale.xAxisScale ==
                                      875
                                  ? 'Time (\u00b5s)'
                                  : 'Time (ms)'),
                          style: TextStyle(
                            fontSize: 10,
                            color: chartTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        sideTitles: SideTitles(
                          maxIncluded: false,
                          interval: provider.oscilloscopeAxesScale
                              .getTimebaseInterval(),
                          reservedSize: 20,
                          showTitles: true,
                          getTitlesWidget: topTitleWidgets,
                        ),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          provider.isFourierTransformSelected
                              ? 'Magnitude (V)'
                              : 'CH1 (V)',
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
                          provider.isFourierTransformSelected
                              ? 'Magnitude (V)'
                              : 'CH2 (V)',
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
                      verticalInterval:
                          provider.oscilloscopeAxesScale.getTimebaseInterval(),
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: Color.fromARGB(50, 255, 255, 255),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => const FlLine(
                        color: Color.fromARGB(50, 255, 255, 255),
                        strokeWidth: 1,
                      ),
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
                    maxY: provider.oscilloscopeAxesScale.yAxisScaleMax,
                    minY: provider.oscilloscopeAxesScale.yAxisScaleMin,
                    maxX: provider.oscilloscopeAxesScale.xAxisScale == 875
                        ? provider.oscilloscopeAxesScale.xAxisScale
                        : provider.oscilloscopeAxesScale.xAxisScale / 1000,
                    minX: 0,
                    clipData: const FlClipData.all(),
                    lineBarsData: provider.createPlots(),
                  ),
                ),
              ),
        );
      },
    );
  }
}
