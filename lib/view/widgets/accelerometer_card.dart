import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class AccelerometerCard extends StatefulWidget {
  final String axis;
  final Color color;
  const AccelerometerCard({required this.axis, required this.color, super.key});

  @override
  State<StatefulWidget> createState() => _AccelerometerCardState();
}

class _AccelerometerCardState extends State<AccelerometerCard> {
  List<FlSpot> spots = [];
  int time = 0;
  double minVal = double.infinity;
  double maxVal = double.negativeInfinity;
  double currVal = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      double val = 0.0;
      switch (widget.axis) {
        case 'x':
          val = event.x;
          break;
        case 'y':
          val = event.y;
          break;
        case 'z':
          val = event.z;
          break;
      }
      setState(() {
        currVal = val;
        minVal = val < minVal ? val : minVal;
        maxVal = val > maxVal ? val : maxVal;

        spots.add(FlSpot(time.toDouble(), currVal));
        if (spots.length > 50) {
          spots.removeAt(0);
        }
        time++;
      });
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

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
                  margin: const EdgeInsets.all(4),
                  child: Text(
                    "Min ${minVal.toStringAsFixed(1)} (m/s²)",
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
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
                    maxX: 10,
                    minX: 0,
                    clipData: const FlClipData.all(),
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
