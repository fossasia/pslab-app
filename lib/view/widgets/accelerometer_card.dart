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

  Widget _sideTitleWidget(
    double value,
    TitleMeta meta, {
    required double fontSize,
  }) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        meta.formattedValue,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: chartTextColor,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _scalingText(String text, double fontSize) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: cardContentColor,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String axisImage,
    required double currentValue,
    required double minValue,
    required double maxValue,
    required double imageSize,
    required double valueFontSize,
    required double labelFontSize,
    required double horizontalPadding,
    required double verticalPadding,
    required double spacing,
  }) {
    final String axisLabel = appLocalizations.accelerationAxisLabel;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            axisImage,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.contain,
          ),
          SizedBox(height: spacing),
          _scalingText(
            '${currentValue.toStringAsFixed(1)} $axisLabel',
            valueFontSize,
          ),
          SizedBox(height: spacing * 0.5),
          _scalingText(
            '${appLocalizations.minValue} ${minValue.toStringAsFixed(1)} $axisLabel',
            labelFontSize,
          ),
          SizedBox(height: spacing * 0.25),
          _scalingText(
            '${appLocalizations.maxValue} ${maxValue.toStringAsFixed(1)} $axisLabel',
            labelFontSize,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection({
    required List<FlSpot> spots,
    required int dataLength,
    required double titleFontSize,
    required double axisNameSize,
    required double reservedSize,
    required double leftPadding,
    required double rightPadding,
    required double topPadding,
    required double bottomPadding,
    required double lineBarWidth,
  }) {
    final double safeMaxX =
        dataLength <= 1 ? 50 : (dataLength > 50 ? 50 : dataLength.toDouble());

    final List<FlSpot> safeSpots = spots.isEmpty ? [const FlSpot(0, 0)] : spots;

    return ClipRect(
      child: Container(
        color: chartBackgroundColor,
        padding: EdgeInsets.only(
          left: leftPadding,
          right: rightPadding,
          top: topPadding,
          bottom: bottomPadding,
        ),
        child: RepaintBoundary(
          child: LineChart(
            LineChartData(
              backgroundColor: chartBackgroundColor,
              minX: 0,
              maxX: safeMaxX,
              minY: -20,
              maxY: 20,
              clipData: const FlClipData.all(),
              gridData: const FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: 10,
                verticalInterval: 10,
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: chartBorderColor),
                  bottom: BorderSide(color: chartBorderColor),
                  top: BorderSide(color: chartBorderColor),
                  right: BorderSide(color: chartBorderColor),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  axisNameWidget: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      appLocalizations.timeAxisLabel,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: chartTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  axisNameSize: axisNameSize,
                  sideTitles: const SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      appLocalizations.accelerationAxisLabel,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: chartTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  axisNameSize: axisNameSize,
                  sideTitles: SideTitles(
                    reservedSize: reservedSize,
                    showTitles: true,
                    interval: 10,
                    getTitlesWidget: (value, meta) => _sideTitleWidget(
                      value,
                      meta,
                      fontSize: titleFontSize,
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: safeSpots,
                  isCurved: safeSpots.length > 2,
                  color: widget.color,
                  barWidth: lineBarWidth,
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
    final double currentValue = provider.getCurrent(widget.axis);
    final double minValue = provider.getMin(widget.axis);
    final double maxValue = provider.getMax(widget.axis);
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
            final double height = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : (width * 0.42).clamp(90.0, 220.0);

            // Use the smaller of width and height (normalised) so the card
            // scales proportionally on narrow or short layouts.
            final double scaleBase =
                width < height * 2.4 ? width : height * 2.4;

            final double leftWidth = (width * 0.34).clamp(80.0, 220.0);

            final double imageSize = (scaleBase * 0.10)
                .clamp(16.0, 48.0)
                .clamp(0.0, height * 0.38);

            final double valueFontSize = (scaleBase * 0.028).clamp(9.0, 14.0);
            final double labelFontSize = (scaleBase * 0.022).clamp(7.5, 11.5);
            final double chartFontSize = (scaleBase * 0.020).clamp(7.0, 11.0);
            final double axisNameSize = (scaleBase * 0.04).clamp(9.0, 20.0);
            final double reservedSize = (scaleBase * 0.05).clamp(14.0, 30.0);
            final double lineBarWidth = (scaleBase * 0.005).clamp(1.0, 2.0);

            final double horizontalPadding =
                (scaleBase * 0.015).clamp(2.0, 8.0);
            final double verticalPadding = (scaleBase * 0.015).clamp(2.0, 8.0);
            final double spacing = (scaleBase * 0.012).clamp(2.0, 6.0);

            final double chartLeftPadding =
                (scaleBase * 0.005).clamp(0.0, 2.0);
            final double chartRightPadding =
                (scaleBase * 0.015).clamp(2.0, 8.0);
            final double chartTopPadding = (scaleBase * 0.012).clamp(2.0, 6.0);
            final double chartBottomPadding =
                (scaleBase * 0.015).clamp(2.0, 8.0);

            return SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: leftWidth,
                    child: _buildInfoSection(
                      axisImage: axisImage,
                      currentValue: currentValue,
                      minValue: minValue,
                      maxValue: maxValue,
                      imageSize: imageSize,
                      valueFontSize: valueFontSize,
                      labelFontSize: labelFontSize,
                      horizontalPadding: horizontalPadding,
                      verticalPadding: verticalPadding,
                      spacing: spacing,
                    ),
                  ),
                  Expanded(
                    child: _buildChartSection(
                      spots: spots,
                      dataLength: dataLength,
                      titleFontSize: chartFontSize,
                      axisNameSize: axisNameSize,
                      reservedSize: reservedSize,
                      leftPadding: chartLeftPadding,
                      rightPadding: chartRightPadding,
                      topPadding: chartTopPadding,
                      bottomPadding: chartBottomPadding,
                      lineBarWidth: lineBarWidth,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
