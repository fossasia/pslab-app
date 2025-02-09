import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';

class OscilloscopeGraph extends StatefulWidget {
  const OscilloscopeGraph({super.key});

  @override
  State<StatefulWidget> createState() => _OscilloscopeGraphState();
}

class _OscilloscopeGraphState extends State<OscilloscopeGraph> {
  Widget sideTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 9,
    );
    return SideTitleWidget(
      meta: meta,
      child: Text(
        meta.formattedValue,
        style: style,
      ),
    );
  }

  Widget topTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 9,
    );
    return SideTitleWidget(
      meta: meta,
      child: Text(
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
        return SizedBox(
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.black,
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  axisNameWidget: Text(
                    oscilloscopeStateProvider.timebase == 875
                        ? 'Time (\u00b5s)'
                        : 'Time (ms)',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  sideTitles: SideTitles(
                    maxIncluded: false,
                    interval: oscilloscopeStateProvider.getTimebaseInterval(),
                    reservedSize: 20,
                    showTitles: true,
                    getTitlesWidget: topTitleWidgets,
                  ),
                ),
                bottomTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'CH1 (V)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  sideTitles: SideTitles(
                    interval: provider.yAxisScale / 4,
                    reservedSize: 30,
                    showTitles: true,
                    getTitlesWidget: sideTitleWidgets,
                  ),
                ),
                rightTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'CH2 (V)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  sideTitles: SideTitles(
                    interval: provider.yAxisScale / 4,
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
                horizontalInterval: provider.yAxisScale / 4,
                verticalInterval:
                    oscilloscopeStateProvider.getTimebaseInterval(),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(
                    color: Colors.white38,
                  ),
                  left: BorderSide(
                    color: Colors.white38,
                  ),
                  top: BorderSide(
                    color: Colors.white38,
                  ),
                  right: BorderSide(
                    color: Colors.white38,
                  ),
                ),
              ),
              maxY: provider.yAxisScale,
              minY: -provider.yAxisScale,
              maxX: oscilloscopeStateProvider.timebase == 875
                  ? oscilloscopeStateProvider.timebase
                  : oscilloscopeStateProvider.timebase / 1000,
              minX: 0,
              clipData: const FlClipData.all(),
              lineBarsData: oscilloscopeStateProvider.createLineBarsData(),
            ),
          ),
        );
      },
    );
  }
}
