import 'package:flutter/material.dart';
import 'package:pslab/providers/accelerometer_state_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

class AccelerometerCard extends StatefulWidget {
  final String axis;
  final Color color;
  //final List<FlSpot> spots;

  const AccelerometerCard({required this.axis, required this.color, super.key});

  @override
  State<StatefulWidget> createState() => _AccelerometerCardState();
}

class _AccelerometerCardState extends State<AccelerometerCard> {
  Widget sideTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
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
    const style = TextStyle(
      color: Colors.white,
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
    final provider = Provider.of<AccelerometerStateProvider>(context);
    final List<FlSpot> spots = provider.getAxisData(widget.axis);
    final currVal = provider.getCurrent(widget.axis);
    final minVal = provider.getMin(widget.axis);
    final maxVal = provider.getMax(widget.axis);
    final dataLength = provider.getDataLength(widget.axis);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 2,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(5)),
        child: Row(
          children: [
            Expanded(
              flex: 30,
              child: Column(children: [
                Container(
                  margin: const EdgeInsets.all(15),
                  child: Image.asset(
                    'assets/images/phone_${widget.axis}_axis.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Text(
                    "${currVal.toStringAsFixed(1)} (m/s²)",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    "Min ${minVal.toStringAsFixed(1)} (m/s²)",
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  margin: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    "Max ${maxVal.toStringAsFixed(1)} (m/s²)",
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ]),
            ),
            Expanded(
              flex: 70,
              child: Container(
                padding: const EdgeInsets.only(bottom: 20, top: 10, right: 25),
                color: Colors.black,
                child: LineChart(
                  LineChartData(
                    backgroundColor: Colors.black,
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                        axisNameWidget: Text(
                          'Time(s)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        axisNameSize: 30,
                      ),
                      bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'm/s²',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
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
                    minY: -20,
                    maxY: 20,
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
