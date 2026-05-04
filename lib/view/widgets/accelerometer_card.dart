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

  // Practical mobile breakpoints (logical pixels). Anything ≥ 360 is treated
  // as the design baseline; below 320 we begin shedding non-essential chrome.
  static const double _kBaselineWidth = 360.0;
  static const double _kCompactWidth = 320.0;
  static const double _kTinyWidth = 260.0;
  static const double _kMicroWidth = 220.0;

  Widget _sideTitleWidget(
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

  Widget _buildChartSection({
    required List<FlSpot> spots,
    required int dataLength,
    required double width,
    required double scale,
  }) {
    final double safeMaxX =
        dataLength <= 1 ? 50 : (dataLength > 50 ? 50 : dataLength.toDouble());
    final List<FlSpot> safeSpots = spots.isEmpty ? [const FlSpot(0, 0)] : spots;

    // Progressively shed chart chrome at smaller widths.
    final bool showTopTitle = width >= _kTinyWidth;
    final bool showLeftTickLabels = width >= _kMicroWidth;

    final double tickFontSize = (10.5 * scale).clamp(7.0, 11.0);
    final double axisLabelFontSize = (11.0 * scale).clamp(7.5, 11.5);
    final double topAxisNameSize =
        showTopTitle ? (16.0 * scale).clamp(10.0, 18.0).toDouble() : 0.0;
    final double leftAxisNameSize = (14.0 * scale).clamp(9.0, 16.0);
    final double reservedSize =
        showLeftTickLabels ? (22.0 * scale).clamp(14.0, 26.0).toDouble() : 6.0;
    final double lineBarWidth = (2.0 * scale).clamp(1.0, 2.2);
    final double leftPadding = (2.0 * scale).clamp(0.0, 3.0);
    final double rightPadding = (8.0 * scale).clamp(2.0, 10.0);
    final double topPadding = (4.0 * scale).clamp(2.0, 6.0);
    final double bottomPadding = (6.0 * scale).clamp(2.0, 8.0);

    return ClipRect(
      child: Padding(
        padding: EdgeInsets.only(
          left: leftPadding,
          right: rightPadding,
          top: topPadding,
          bottom: bottomPadding,
        ),
        child: RepaintBoundary(
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.black,
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
                  axisNameWidget: showTopTitle
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            appLocalizations.timeAxisLabel,
                            style: TextStyle(
                              fontSize: axisLabelFontSize,
                              color: chartTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  axisNameSize: topAxisNameSize,
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
                        fontSize: axisLabelFontSize,
                        color: chartTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  axisNameSize: leftAxisNameSize,
                  sideTitles: SideTitles(
                    reservedSize: reservedSize,
                    showTitles: showLeftTickLabels,
                    interval: 10,
                    getTitlesWidget: (value, meta) =>
                        _sideTitleWidget(meta, fontSize: tickFontSize),
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
    final double currVal = provider.getCurrent(widget.axis);
    final double minVal = provider.getMin(widget.axis);
    final double maxVal = provider.getMax(widget.axis);
    final int dataLength = provider.getDataLength(widget.axis);
    final String axisImage = 'assets/images/phone_${widget.axis}_axis.png';
    final String axisLabel = appLocalizations.accelerationAxisLabel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool boundedHeight = constraints.maxHeight.isFinite;
        final double targetHeight = (width * 0.55).clamp(140.0, 300.0);

        // Practical scale model: 1.0 at the design baseline (360dp width,
        // 200dp card height), with a sane floor so things stay legible.
        final double widthScale = width / _kBaselineWidth;

        const double outerHMargin = 8.0;
        const double outerVMargin = 6.0;

        final double effectiveHeight = boundedHeight
            ? (constraints.maxHeight - outerVMargin * 2)
                .clamp(60.0, double.infinity)
                .toDouble()
            : targetHeight;
        final double heightScale = effectiveHeight / 200.0;

        final double scale =
            (widthScale < heightScale ? widthScale : heightScale)
                .clamp(0.55, 1.15)
                .toDouble();

        final bool isCompact = width < _kCompactWidth;
        final bool isTiny = width < _kTinyWidth;

        // Card chrome.
        final double cardTopOffset = (8.0 * scale).clamp(5.0, 10.0);
        final double borderRadius = isCompact ? 4.0 : 6.0;
        final double borderWidth = isCompact ? 1.0 : 1.2;

        // Title chip (overlaps the top border).
        final double titleFontSize = isTiny
            ? 10.5
            : (isCompact ? 11.5 : (12.5 * scale).clamp(11.0, 13.0));
        final double titleHPadding = isCompact ? 6.0 : 8.0;
        const double titleVPadding = 1.0;

        // Top info row — designed for ≥320dp; compact mins for tighter widths.
        double rowTopPad = isTiny ? 6.0 : (isCompact ? 8.0 : 10.0);
        double rowBottomPad = isTiny ? 4.0 : (isCompact ? 5.0 : 6.0);
        final double rowHPad = isTiny ? 6.0 : (isCompact ? 8.0 : 10.0);
        double imageSize = isTiny ? 14.0 : (isCompact ? 16.0 : 20.0);
        final double imageGap = isTiny ? 5.0 : (isCompact ? 6.0 : 8.0);

        final double currentFontSize =
            isTiny ? 10.5 : (isCompact ? 12.0 : 13.5);
        final double minMaxFontSize = isTiny ? 9.5 : (isCompact ? 11.0 : 12.5);
        final double currentToMinGap = isTiny ? 8.0 : (isCompact ? 14.0 : 20.0);
        final double minToMaxGap = isTiny ? 6.0 : (isCompact ? 10.0 : 14.0);

        // Chart-first vertical budgeting: reserve at least ~55% of the card
        // for the plot. If the row + paddings would push past the budget,
        // shrink them proportionally so the chart keeps a usable slice.
        // Important: at ultra-small heights, do NOT impose a chart floor
        // larger than what Expanded can actually deliver — otherwise the
        // ConstrainedBox would fight the parent and force overflow. The
        // floor is capped against the realistic remaining space.
        final double estimatedHeaderBase =
            rowTopPad + imageSize + rowBottomPad + 1.0;
        final double availableForChart =
            (effectiveHeight - estimatedHeaderBase).clamp(0.0, effectiveHeight);
        double chartMinHeight =
            (effectiveHeight * 0.55).clamp(80.0, 220.0).toDouble();
        if (chartMinHeight > availableForChart) {
          chartMinHeight = availableForChart;
        }
        final double headerBudget =
            (effectiveHeight - chartMinHeight - 1.0).clamp(28.0, 200.0);
        final double estimatedHeader = rowTopPad + imageSize + rowBottomPad;
        if (estimatedHeader > headerBudget) {
          final double shrink =
              (headerBudget / estimatedHeader).clamp(0.55, 1.0).toDouble();
          rowTopPad = (rowTopPad * shrink).clamp(3.0, rowTopPad).toDouble();
          rowBottomPad =
              (rowBottomPad * shrink).clamp(2.0, rowBottomPad).toDouble();
          imageSize = (imageSize * shrink).clamp(10.0, imageSize).toDouble();
        }

        return Container(
          margin: const EdgeInsets.symmetric(
            vertical: outerVMargin,
            horizontal: outerHMargin,
          ),
          height: boundedHeight ? null : effectiveHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // LAYER 1: bordered card body.
              Container(
                margin: EdgeInsets.only(top: cardTopOffset),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  border: Border.all(width: borderWidth, color: Colors.red),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        rowHPad,
                        rowTopPad,
                        rowHPad,
                        rowBottomPad,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            axisImage,
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: imageGap),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Current: ${currVal.toStringAsFixed(1)} '
                                    '$axisLabel',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: widget.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: currentFontSize,
                                      height: 1.1,
                                    ),
                                  ),
                                  SizedBox(width: currentToMinGap),
                                  Text(
                                    '${appLocalizations.minValue}'
                                    '${minVal.toStringAsFixed(1)}',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: cardContentColor.withValues(
                                          alpha: 0.8),
                                      fontSize: minMaxFontSize,
                                      height: 1.1,
                                    ),
                                  ),
                                  SizedBox(width: minToMaxGap),
                                  Text(
                                    '${appLocalizations.maxValue}'
                                    '${maxVal.toStringAsFixed(1)}',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: cardContentColor.withValues(
                                          alpha: 0.8),
                                      fontSize: minMaxFontSize,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.red.withOpacity(0.5),
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: chartMinHeight),
                        child: Container(
                          color: Colors.black,
                          child: _buildChartSection(
                            spots: spots,
                            dataLength: dataLength,
                            width: width,
                            scale: scale,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // LAYER 2: title chip overlapping the top border.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: titleHPadding,
                      vertical: titleVPadding,
                    ),
                    color: cardBackgroundColor,
                    child: Text(
                      '${widget.axis.toUpperCase()} AXIS',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: titleFontSize,
                        height: 1.0,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
