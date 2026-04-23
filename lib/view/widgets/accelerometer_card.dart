import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/accelerometer_state_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class AccelerometerCard extends StatefulWidget {
  final String axis;
  final Color color;

  const AccelerometerCard({
    required this.axis,
    required this.color,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _AccelerometerCardState();
}

class _AccelerometerCardState extends State<AccelerometerCard> {
  final AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  Widget sideTitleWidgets(
      double value,
      TitleMeta meta, {
        required bool compact,
      }) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        meta.formattedValue,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: chartTextColor,
          fontSize: compact ? 8 : 9,
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required BoxConstraints constraints,
    required String axisImage,
    required double currVal,
    required double minVal,
    required double maxVal,
    required bool isNarrow,
    required bool centered,
  }) {
    final double imageSize =
    (constraints.maxWidth * 0.15).clamp(30.0, 50.0).toDouble();

    final double labelWidth = isNarrow ? 110 : 130;

    return KeyedSubtree(
      key: ValueKey('accelerometer-info-${widget.axis}-$centered'),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 10 : 12,
          vertical: isNarrow ? 10 : 12,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              axisImage,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
            ),
            SizedBox(height: isNarrow ? 6 : 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${currVal.toStringAsFixed(1)} ${appLocalizations.accelerationAxisLabel}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cardContentColor,
                  fontSize: isNarrow ? 12 : 14,
                ),
              ),
            ),
            SizedBox(height: isNarrow ? 6 : 8),
            Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: SizedBox(
                width: centered ? null : labelWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                  centered ? Alignment.center : Alignment.centerLeft,
                  child: Text(
                    "${appLocalizations.minValue} ${minVal.toStringAsFixed(1)} ${appLocalizations.accelerationAxisLabel}",
                    textAlign: centered ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      color: cardContentColor,
                      fontSize: isNarrow ? 8 : 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: SizedBox(
                width: centered ? null : labelWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                  centered ? Alignment.center : Alignment.centerLeft,
                  child: Text(
                    "${appLocalizations.maxValue} ${maxVal.toStringAsFixed(1)} ${appLocalizations.accelerationAxisLabel}",
                    textAlign: centered ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      color: cardContentColor,
                      fontSize: isNarrow ? 8 : 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection({
    required List<FlSpot> spots,
    required int dataLength,
    required bool isNarrow,
  }) {
    final double safeMaxX =
    dataLength <= 1 ? 50 : (dataLength > 50 ? 50 : dataLength.toDouble());

    final List<FlSpot> safeSpots =
    spots.isEmpty ? [const FlSpot(0, 0)] : spots;

    return KeyedSubtree(
      key: ValueKey('accelerometer-chart-${widget.axis}-$isNarrow'),
      child: Container(
        padding: EdgeInsets.only(
          left: isNarrow ? 8 : 0,
          right: isNarrow ? 10 : 20,
          top: isNarrow ? 8 : 10,
          bottom: isNarrow ? 10 : 16,
        ),
        color: chartBackgroundColor,
        child: RepaintBoundary(
          child: LineChart(
            LineChartData(
              backgroundColor: chartBackgroundColor,
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  axisNameWidget: Padding(
                    padding: EdgeInsets.only(left: isNarrow ? 0 : 18),
                    child: Text(
                      appLocalizations.timeAxisLabel,
                      style: TextStyle(
                        fontSize: isNarrow ? 8 : 10,
                        color: chartTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  axisNameSize: isNarrow ? 16 : 20,
                  sideTitles: const SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    appLocalizations.accelerationAxisLabel,
                    style: TextStyle(
                      fontSize: isNarrow ? 8 : 10,
                      color: chartTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  axisNameSize: isNarrow ? 16 : 20,
                  sideTitles: SideTitles(
                    reservedSize: isNarrow ? 22 : 30,
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        sideTitleWidgets(value, meta, compact: isNarrow),
                    interval: 10,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
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
                  bottom: BorderSide(color: chartBorderColor),
                  left: BorderSide(color: chartBorderColor),
                  top: BorderSide(color: chartBorderColor),
                  right: BorderSide(color: chartBorderColor),
                ),
              ),
              minY: -20,
              maxY: 20,
              minX: 0,
              maxX: safeMaxX,
              clipData: const FlClipData.all(),
              lineBarsData: [
                LineChartBarData(
                  spots: safeSpots,
                  isCurved: safeSpots.length > 2,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final AccelerometerStateProvider provider =
    Provider.of<AccelerometerStateProvider>(context);

    final List<FlSpot> spots = provider.getAxisData(widget.axis);
    final double currVal = provider.getCurrent(widget.axis);
    final double minVal = provider.getMin(widget.axis);
    final double maxVal = provider.getMax(widget.axis);
    final int dataLength = provider.getDataLength(widget.axis);
    final String axisImage = 'assets/images/phone_${widget.axis}_axis.png';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;

            final bool useVerticalLayout = width < 420;
            final bool isNarrow = width < 400;
            final bool useFallbackScroll = width < 320 || height < 180;

            final Widget infoSection = _buildInfoSection(
              constraints: constraints,
              axisImage: axisImage,
              currVal: currVal,
              minVal: minVal,
              maxVal: maxVal,
              isNarrow: isNarrow,
              centered: useVerticalLayout,
            );

            final Widget chartSection = _buildChartSection(
              spots: spots,
              dataLength: dataLength,
              isNarrow: isNarrow,
            );

            final Widget content = useVerticalLayout
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 165,
                  child: infoSection,
                ),
                SizedBox(
                  height: 180,
                  child: chartSection,
                ),
              ],
            )
                : SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 170,
                    child: infoSection,
                  ),
                  Expanded(
                    child: chartSection,
                  ),
                ],
              ),
            );

            if (useFallbackScroll) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: width),
                  child: content,
                ),
              );
            }

            return content;
          },
        ),
      ),
    );
  }
}