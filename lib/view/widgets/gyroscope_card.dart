import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pslab/providers/gyroscope_state_provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

import '../../theme/colors.dart';

class GyroscopeCard extends StatefulWidget {
  final String axis;
  final Color color;

  const GyroscopeCard({required this.axis, required this.color, super.key});

  @override
  State<StatefulWidget> createState() => _GyroscopeCardState();
}

class _GyroscopeCardState extends State<GyroscopeCard> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
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

  @override
  Widget build(BuildContext context) {
    GyroscopeProvider provider = Provider.of<GyroscopeProvider>(context);

    List<FlSpot> spots = provider.getAxisData(widget.axis.toLowerCase());
    double currVal = provider.getCurrent(widget.axis.toLowerCase());
    double minVal = provider.getMin(widget.axis.toLowerCase());
    double maxVal = provider.getMax(widget.axis.toLowerCase());
    int dataLength = provider.getDataLength(widget.axis.toLowerCase());

    double chartMinY = -20;
    double chartMaxY = 20;

    String axisImage =
        'assets/images/phone_${widget.axis.toLowerCase()}_axis.png';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
            color: cardBackgroundColor, borderRadius: BorderRadius.circular(5)),
        child: Row(
          children: [
            Expanded(
              flex: 30,
              child: Column(children: [
                Container(
                  margin: const EdgeInsets.all(15),
                  child: Image.asset(
                    axisImage,
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      IconData fallbackIcon;
                      switch (widget.axis.toLowerCase()) {
                        case 'x':
                          fallbackIcon = Icons.rotate_left;
                          break;
                        case 'y':
                          fallbackIcon = Icons.rotate_right;
                          break;
                        case 'z':
                          fallbackIcon = Icons.rotate_90_degrees_ccw;
                          break;
                        default:
                          fallbackIcon = Icons.rotate_left;
                      }
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          fallbackIcon,
                          color: widget.color,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Text(
                    "${currVal.toStringAsFixed(1)} ${appLocalizations.gyroscopeAxisLabel}",
                    style: TextStyle(color: cardContentColor, fontSize: 14),
                  ),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    "${appLocalizations.minValue} ${minVal.toStringAsFixed(1)} ${appLocalizations.gyroscopeAxisLabel}",
                    style: TextStyle(color: cardContentColor, fontSize: 10),
                  ),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  margin: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    "${appLocalizations.maxValue} ${maxVal.toStringAsFixed(1)} ${appLocalizations.gyroscopeAxisLabel}",
                    style: TextStyle(color: cardContentColor, fontSize: 10),
                  ),
                ),
              ]),
            ),
            Expanded(
              flex: 70,
              child: Container(
                padding: const EdgeInsets.only(bottom: 20, top: 10, right: 25),
                color: chartBackgroundColor,
                child: LineChart(
                  LineChartData(
                    backgroundColor: chartBackgroundColor,
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(left: 25),
                          child: Text(
                            appLocalizations.timeAxisLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: chartTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        axisNameSize: 20,
                      ),
                      bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          appLocalizations.gyroscopeAxisLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: chartTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        sideTitles: SideTitles(
                          reservedSize: 30,
                          showTitles: true,
                          getTitlesWidget: sideTitleWidgets,
                          interval: 10,
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      horizontalInterval: 10,
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
                    minY: chartMinY,
                    maxY: chartMaxY,
                    maxX: dataLength > 50 ? 50 : dataLength.toDouble(),
                    minX: 0,
                    clipData: const FlClipData.all(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: widget.color,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
