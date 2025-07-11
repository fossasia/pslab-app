import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class PlaybackSummaryDialog extends StatefulWidget {
  final int frequency;
  final int maxAngle;
  final Map<String, dynamic> Function(int servoIndex, int maxAngle) getSummary;

  const PlaybackSummaryDialog({
    super.key,
    required this.frequency,
    required this.maxAngle,
    required this.getSummary,
  });

  @override
  State<PlaybackSummaryDialog> createState() => _PlaybackSummaryDialogState();
}

class _PlaybackSummaryDialogState extends State<PlaybackSummaryDialog> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  int selectedServo = 0;

  @override
  Widget build(BuildContext context) {
    final data = widget.getSummary(
      selectedServo,
      widget.maxAngle,
    );

    final List<FlSpot> pwmSpots = data['spots'];
    final double avgDuty = data['avgDuty'];
    final double minDuty = data['minDuty'];
    final double maxDuty = data['maxDuty'];
    final double avg = data['avgAngle'];
    final double max = data['maxAngle'];
    final double min = data['minAngle'];
    final List<Map<String, dynamic>> labelPoints = data['dutyLabelPoints'];

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 280),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Divider(color: primaryRed)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    appLocalizations.playBackSummary,
                    style: TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: primaryRed)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                appLocalizations.servo,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.black),
                              ),
                              ButtonTheme(
                                alignedDropdown: true,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                minWidth: 0,
                                height: 24,
                                child: DropdownButton<int>(
                                  isDense: true,
                                  isExpanded: false,
                                  value: selectedServo,
                                  dropdownColor: Colors.white,
                                  underline: const SizedBox(),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.black),
                                  items: List.generate(4, (i) {
                                    return DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                          '${appLocalizations.servo} ${i + 1}',
                                          style: const TextStyle(fontSize: 10)),
                                    );
                                  }),
                                  onChanged: (v) =>
                                      setState(() => selectedServo = v!),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatCard(
                                icon: Icons.show_chart,
                                label: appLocalizations.avgAngleLabel,
                                value:
                                    '${avg.toStringAsFixed(1)}${appLocalizations.degreeSymbol}'),
                            _StatCard(
                                icon: Icons.arrow_upward,
                                label: appLocalizations.maxAngleLabel,
                                value:
                                    '${max.toStringAsFixed(1)}${appLocalizations.degreeSymbol}'),
                            _StatCard(
                                icon: Icons.arrow_downward,
                                label: appLocalizations.minAngleLabel,
                                value:
                                    '${min.toStringAsFixed(1)}${appLocalizations.degreeSymbol}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatCard(
                                icon: Icons.timeline,
                                label: appLocalizations.avgDutyLabel,
                                value:
                                    '${avgDuty.toStringAsFixed(1)}${appLocalizations.percentage}'),
                            _StatCard(
                                icon: Icons.trending_up,
                                label: appLocalizations.maxDutyLabel,
                                value:
                                    '${maxDuty.toStringAsFixed(1)}${appLocalizations.percentage}'),
                            _StatCard(
                                icon: Icons.low_priority,
                                label: appLocalizations.minDutyLabel,
                                value:
                                    '${minDuty.toStringAsFixed(1)}${appLocalizations.percentage}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              appLocalizations.pwmWaveForm,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 130,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final calculatedWidth = pwmSpots.isNotEmpty
                                    ? pwmSpots.last.x * 4.5
                                    : 250;
                                final chartWidth =
                                    calculatedWidth < constraints.maxWidth
                                        ? constraints.maxWidth
                                        : calculatedWidth;

                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: chartWidth.toDouble(),
                                    child: LineChart(
                                      LineChartData(
                                        minX: 0,
                                        maxX: pwmSpots.isNotEmpty
                                            ? pwmSpots.last.x
                                            : 100,
                                        minY: 0,
                                        maxY: 1.04,
                                        lineTouchData:
                                            const LineTouchData(enabled: false),
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: true,
                                          drawHorizontalLine: true,
                                          horizontalInterval: 1,
                                          verticalInterval: 10,
                                          getDrawingHorizontalLine: (_) =>
                                              const FlLine(
                                                  color: Colors.white12,
                                                  strokeWidth: 1),
                                          getDrawingVerticalLine: (_) =>
                                              const FlLine(
                                                  color: Colors.white10,
                                                  strokeWidth: 1),
                                        ),
                                        titlesData: FlTitlesData(
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 12,
                                              interval: 1,
                                              getTitlesWidget: (value, _) {
                                                if (pwmSpots.isEmpty) {
                                                  return const SizedBox
                                                      .shrink();
                                                }

                                                for (final label
                                                    in labelPoints) {
                                                  if ((label['x'] - value)
                                                          .abs() <
                                                      0.5) {
                                                    return Text(
                                                      label['label'],
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    );
                                                  }
                                                }

                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 12,
                                              interval: 20,
                                              getTitlesWidget: (value, _) =>
                                                  Text(
                                                '${value.toInt()} ms',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 24,
                                              interval: 1,
                                              getTitlesWidget: (value, _) {
                                                if (value == 1) {
                                                  return Text(
                                                    appLocalizations.high,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                    ),
                                                  );
                                                } else if (value == 0) {
                                                  return Text(
                                                    appLocalizations.low,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
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
                                            right: BorderSide(
                                              color: Colors.white38,
                                            ),
                                          ),
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: pwmSpots,
                                            isStepLineChart: true,
                                            color: Colors.green,
                                            barWidth: 0.6,
                                            belowBarData:
                                                BarAreaData(show: false),
                                            dotData:
                                                const FlDotData(show: false),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Text(
                            appLocalizations.timeMillisecond,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  side: const BorderSide(color: Colors.black54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  appLocalizations.close,
                  style: TextStyle(fontSize: 8, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryRed, size: 18),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.black)),
          const SizedBox(height: 1),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ],
      ),
    );
  }
}
