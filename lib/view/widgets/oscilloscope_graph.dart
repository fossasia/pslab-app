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

  double _maxX(OscilloscopeStateProvider provider) {
    return provider.oscilloscopeAxesScale.xAxisScale == 875
        ? provider.oscilloscopeAxesScale.xAxisScale
        : provider.oscilloscopeAxesScale.xAxisScale / 1000;
  }

  Widget _buildOverlayChart(OscilloscopeStateProvider provider) {
    return LineChart(
      LineChartData(
        backgroundColor: chartBackgroundColor,
        lineTouchData: LineTouchData(
          enabled: !provider.isPlayingBack,
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(
            axisNameWidget: Text(
              provider.isFourierTransformSelected
                  ? 'Frequency (Hz)'
                  : (provider.oscilloscopeAxesScale.xAxisScale == 875
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
              interval: provider.oscilloscopeAxesScale.getTimebaseInterval(),
              reservedSize: 20,
              showTitles: true,
              getTitlesWidget: topTitleWidgets,
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              provider.isFourierTransformSelected ? 'Magnitude (V)' : 'CH1 (V)',
              style: TextStyle(
                fontSize: 10,
                color: chartTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            sideTitles: SideTitles(
              interval: provider.oscilloscopeAxesScale.yAxisScaleMax / 4,
              reservedSize: 30,
              showTitles: true,
              getTitlesWidget: sideTitleWidgets,
            ),
          ),
          rightTitles: AxisTitles(
            axisNameWidget: Text(
              provider.isFourierTransformSelected ? 'Magnitude (V)' : 'CH2 (V)',
              style: TextStyle(
                fontSize: 10,
                color: chartTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            sideTitles: SideTitles(
              interval: provider.oscilloscopeAxesScale.yAxisScaleMax / 4,
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
          horizontalInterval: provider.oscilloscopeAxesScale.yAxisScaleMax / 4,
          verticalInterval:
              provider.oscilloscopeAxesScale.getTimebaseInterval(),
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Color.fromARGB(50, 255, 255, 255),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: Color.fromARGB(50, 255, 255, 255),
              strokeWidth: 1,
            );
          },
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
        maxX: _maxX(provider),
        minX: 0,
        clipData: const FlClipData.all(),
        lineBarsData: provider.createPlots(),
      ),
    );
  }

  Widget _buildStackedChannelChart(
    OscilloscopeStateProvider provider, {
    required String channelName,
    required bool showTimeAxis,
  }) {
    return LineChart(
      LineChartData(
        backgroundColor: chartBackgroundColor,
        lineTouchData: LineTouchData(
          enabled: !provider.isPlayingBack,
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(
            axisNameWidget: showTimeAxis
                ? Text(
                    provider.isFourierTransformSelected
                        ? 'Frequency (Hz)'
                        : (provider.oscilloscopeAxesScale.xAxisScale == 875
                            ? 'Time (\u00b5s)'
                            : 'Time (ms)'),
                    style: TextStyle(
                      fontSize: 10,
                      color: chartTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const SizedBox.shrink(),
            sideTitles: SideTitles(
              maxIncluded: false,
              interval: provider.oscilloscopeAxesScale.getTimebaseInterval(),
              reservedSize: showTimeAxis ? 20 : 8,
              showTitles: showTimeAxis,
              getTitlesWidget: topTitleWidgets,
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              provider.isFourierTransformSelected
                  ? '$channelName (V)'
                  : '$channelName (V)',
              style: TextStyle(
                fontSize: 10,
                color: chartTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            sideTitles: SideTitles(
              interval: provider.oscilloscopeAxesScale.yAxisScaleMax / 4,
              reservedSize: 30,
              showTitles: true,
              getTitlesWidget: sideTitleWidgets,
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: provider.oscilloscopeAxesScale.yAxisScaleMax / 4,
          verticalInterval:
              provider.oscilloscopeAxesScale.getTimebaseInterval(),
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Color.fromARGB(50, 255, 255, 255),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: Color.fromARGB(50, 255, 255, 255),
              strokeWidth: 1,
            );
          },
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
        maxX: _maxX(provider),
        minX: 0,
        clipData: const FlClipData.all(),
        lineBarsData: provider.createPlotForChannel(channelName),
      ),
    );
  }

  Widget _buildStackedCharts(OscilloscopeStateProvider provider) {
    final channels = provider.stackedChannelNames();
    return Column(
      children: [
        for (int i = 0; i < channels.length; i++)
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(bottom: i == channels.length - 1 ? 0 : 2),
              child: _buildStackedChannelChart(
                provider,
                channelName: channels[i],
                showTimeAxis: i == 0,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OscilloscopeStateProvider>(
      builder: (context, provider, _) {
        if (provider.isXYPlotSelected) {
          return const SizedBox(
            child: XYPlotGraph(),
          );
        }
        if (provider.isStackedMode) {
          return SizedBox(
            child: _buildStackedCharts(provider),
          );
        }
        return SizedBox(
          child: _buildOverlayChart(provider),
        );
      },
    );
  }
}
