import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/gyroscope_state_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class GyroscopeCard extends StatefulWidget {
  final String axis;
  final Color color;

  const GyroscopeCard({
    required this.axis,
    required this.color,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _GyroscopeCardState();
}

class _GyroscopeCardState extends State<GyroscopeCard> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  static const double _kBaselineWidth = 360.0;
  static const double _kCompactWidth = 320.0;
  static const double _kTinyWidth = 260.0;
  static const double _kMicroWidth = 220.0;

  IconData _fallbackIcon() {
    switch (widget.axis.toLowerCase()) {
      case 'x':
        return Icons.rotate_left;
      case 'y':
        return Icons.rotate_right;
      case 'z':
        return Icons.rotate_90_degrees_ccw;
      default:
        return Icons.rotate_left;
    }
  }

  Widget _buildTopInfoRow({
    required String axisImage,
    required String axisLabel,
    required double currVal,
    required double minVal,
    required double maxVal,
    required double imageSize,
    required double imageGap,
    required double currentFontSize,
    required double minMaxFontSize,
    required double currentToMinGap,
    required double minToMaxGap,
  }) {
    final TextStyle currentStyle = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: currentFontSize,
      height: 1.1,
    );
    final TextStyle minMaxStyle = TextStyle(
      color: cardContentColor.withValues(alpha: 0.8),
      fontSize: minMaxFontSize,
      height: 1.1,
    );

    final Widget currentText = Text(
      'Current: ${currVal.toStringAsFixed(1)} $axisLabel',
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: currentStyle,
    );
    final Widget minText = Text(
      '${appLocalizations.minValue}${minVal.toStringAsFixed(1)}',
      maxLines: 1,
      softWrap: false,
      style: minMaxStyle,
    );
    final Widget maxText = Text(
      '${appLocalizations.maxValue}${maxVal.toStringAsFixed(1)}',
      maxLines: 1,
      softWrap: false,
      style: minMaxStyle,
    );

    final Widget axisImg = Image.asset(
      axisImage,
      width: imageSize,
      height: imageSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _fallbackIcon(),
            color: widget.color,
            size: imageSize * 0.6,
          ),
        );
      },
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        axisImg,
        SizedBox(width: imageGap),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: currentText,
          ),
        ),
        SizedBox(width: currentToMinGap),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            minText,
            SizedBox(width: minToMaxGap),
            maxText,
          ],
        ),
      ],
    );
  }

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

    final bool showTopTitle = width >= _kTinyWidth;
    final bool showLeftTickLabels = width >= _kMicroWidth;
    final bool sparseTicks = width < _kCompactWidth;
    final double tickInterval = sparseTicks ? 20.0 : 10.0;

    final double widthFactor = (width / _kBaselineWidth).clamp(0.55, 1.15);

    final double tickFontSize = (10.0 * scale).clamp(8.0, 10.5).toDouble();
    final double axisLabelFontSize = (10.5 * scale).clamp(7.5, 11.0).toDouble();
    final double topAxisNameSize =
        showTopTitle ? (15.0 * scale).clamp(9.0, 17.0).toDouble() : 0.0;
    final double leftAxisNameSize =
        (12.0 * widthFactor).clamp(9.0, 14.0).toDouble();
    final double reservedSize = !showLeftTickLabels
        ? 4.0
        : sparseTicks
            ? (tickFontSize * 2.0 + 4.0).clamp(16.0, 22.0).toDouble()
            : (tickFontSize * 2.2 + 4.0).clamp(18.0, 26.0).toDouble();
    final double lineBarWidth = (2.0 * scale).clamp(1.0, 2.2);
    final double leftPadding = (1.5 * scale).clamp(0.0, 2.0);
    final double rightPadding = (6.0 * scale).clamp(2.0, 8.0);
    final double topPadding = (3.0 * scale).clamp(1.5, 5.0);
    final double bottomPadding = (5.0 * scale).clamp(2.0, 7.0);

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
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: tickInterval,
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
                      appLocalizations.gyroscopeAxisLabel,
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
                    interval: tickInterval,
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
    final GyroscopeProvider provider = Provider.of<GyroscopeProvider>(context);

    final List<FlSpot> spots = provider.getAxisData(widget.axis.toLowerCase());
    final double currVal = provider.getCurrent(widget.axis.toLowerCase());
    final double minVal = provider.getMin(widget.axis.toLowerCase());
    final double maxVal = provider.getMax(widget.axis.toLowerCase());
    final int dataLength = provider.getDataLength(widget.axis.toLowerCase());
    final String axisImage =
        'assets/images/phone_${widget.axis.toLowerCase()}_axis.png';
    final String axisLabel = appLocalizations.gyroscopeAxisLabel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool boundedHeight = constraints.maxHeight.isFinite;
        final double targetHeight = (width * 0.55).clamp(140.0, 300.0);

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

        final double cardTopOffset = (8.0 * scale).clamp(5.0, 10.0);
        final double borderRadius = isCompact ? 4.0 : 6.0;
        final double borderWidth = isCompact ? 1.0 : 1.2;

        final double titleFontSize = isTiny
            ? 10.5
            : (isCompact ? 11.5 : (12.5 * scale).clamp(11.0, 13.0));
        final double titleHPadding = isCompact ? 6.0 : 8.0;
        const double titleVPadding = 1.0;

        double rowTopPad = isTiny ? 6.0 : (isCompact ? 8.0 : 10.0);
        double rowBottomPad = isTiny ? 4.0 : (isCompact ? 5.0 : 6.0);
        final double rowHPad = isTiny ? 5.0 : (isCompact ? 8.0 : 10.0);
        double imageSize = isTiny ? 12.0 : (isCompact ? 16.0 : 20.0);
        final double imageGap = isTiny ? 3.0 : (isCompact ? 6.0 : 8.0);

        final double currentFontSize = isTiny ? 9.5 : (isCompact ? 12.0 : 13.5);
        final double minMaxFontSize = isTiny ? 8.5 : (isCompact ? 11.0 : 12.5);
        final double currentToMinGap = isTiny ? 3.0 : (isCompact ? 6.0 : 12.0);
        final double minToMaxGap = isTiny ? 4.0 : (isCompact ? 8.0 : 12.0);

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
                      child: _buildTopInfoRow(
                        axisImage: axisImage,
                        axisLabel: axisLabel,
                        currVal: currVal,
                        minVal: minVal,
                        maxVal: maxVal,
                        imageSize: imageSize,
                        imageGap: imageGap,
                        currentFontSize: currentFontSize,
                        minMaxFontSize: minMaxFontSize,
                        currentToMinGap: currentToMinGap,
                        minToMaxGap: minToMaxGap,
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.red.withValues(alpha: 0.5),
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
