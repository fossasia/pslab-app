import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data_points.dart';
import '../../providers/locator.dart';
import '../../theme/colors.dart';

AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

class SensorChartWidget extends StatelessWidget {
  final String title;
  final String yAxisLabel;
  final String? xAxisLabel;
  final List<ChartDataPoint> data;
  final Color lineColor;
  final Color? backgroundColor;
  final double? minY;
  final double? maxY;
  final double? minX;
  final double? maxX;
  final bool showGrid;
  final bool showDots;
  final bool isCurved;
  final double lineWidth;
  final String? unit;
  final int? maxDataPoints;
  final Widget? customNoDataWidget;
  const SensorChartWidget({
    super.key,
    required this.title,
    required this.yAxisLabel,
    required this.data,
    this.xAxisLabel = 'Time (s)',
    this.lineColor = chartLineColor,
    this.backgroundColor,
    this.minY,
    this.maxY,
    this.minX,
    this.maxX,
    this.showGrid = true,
    this.showDots = false,
    this.isCurved = true,
    this.lineWidth = 2.0,
    this.unit,
    this.maxDataPoints,
    this.customNoDataWidget,
  });
  List<ChartDataPoint> get _validData {
    return data.where((point) {
      return point.x.isFinite &&
          point.y.isFinite &&
          !point.x.isNaN &&
          !point.y.isNaN;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _buildHeader(),
          _buildChart(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: primaryRed,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: chartTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: backgroundColor ?? chartBackgroundColor,
        border: Border.all(color: chartTextColor),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        ),
      ),
      child: _validData.isEmpty ? _buildNoDataView() : _buildLineChart(),
    );
  }

  Widget _buildNoDataView() {
    return Stack(
      children: [
        _buildAxisLabels(),
        Center(
          child: customNoDataWidget ??
              Text(
                appLocalizations.noData,
                style: TextStyle(
                  color: chartHintTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    if (_validData.isEmpty) {
      return _buildNoDataView();
    }
    return Stack(
      children: [
        _buildAxisLabels(),
        Padding(
          padding:
              const EdgeInsets.only(left: 50, right: 16, top: 16, bottom: 40),
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.transparent,
              gridData: FlGridData(
                show: showGrid,
                drawVerticalLine: showGrid,
                drawHorizontalLine: showGrid,
                horizontalInterval: _calculateGridInterval(),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withAlpha(77),
                  strokeWidth: 0.8,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.grey.withAlpha(77),
                  strokeWidth: 0.8,
                ),
              ),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.grey.withAlpha(120),
                  width: 1,
                ),
              ),
              minX: _getMinX(),
              maxX: _getMaxX(),
              minY: _getMinY(),
              maxY: _getMaxY(),
              lineBarsData: [
                LineChartBarData(
                  spots: _validData
                      .map((point) => FlSpot(point.x, point.y))
                      .toList(),
                  isCurved: isCurved,
                  color: lineColor,
                  barWidth: lineWidth,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: showDots,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 2,
                        color: lineColor,
                        strokeWidth: 1,
                        strokeColor: chartTextColor,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: false,
                    color: lineColor.withAlpha(26),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final yValue = spot.y.isFinite
                          ? spot.y.toStringAsFixed(2)
                          : appLocalizations.notAvailable;
                      final xValue = spot.x.isFinite
                          ? spot.x.toStringAsFixed(1)
                          : appLocalizations.notAvailable;
                      return LineTooltipItem(
                        '$yAxisLabel: $yValue${unit ?? ''}\n${appLocalizations.time}: $xValue',
                        TextStyle(
                          color: chartTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAxisLabels() {
    return Stack(
      children: [
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                appLocalizations.timeAxisLabel,
                style: TextStyle(
                  color: chartTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  yAxisLabel,
                  style: TextStyle(
                    color: chartTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_validData.isNotEmpty)
          Positioned(
            top: 12,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: lineColor.withAlpha(230),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_validData.last.y.toStringAsFixed(2)}${unit ?? ''}',
                style: TextStyle(
                  color: chartTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _getMinX() {
    if (minX != null) return minX!;
    if (_validData.isEmpty) return 0;
    return _validData.first.x;
  }

  double _getMaxX() {
    if (maxX != null) return maxX!;
    if (_validData.isEmpty) return 10;
    return _validData.last.x;
  }

  double _getMinY() {
    if (minY != null) return minY!;
    if (_validData.isEmpty) return 0;
    final values = _validData.map((e) => e.y).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final range = _getDataRange();
    final result = dataMin - (range * 0.1);
    return result.isFinite ? result : 0;
  }

  double _getMaxY() {
    if (maxY != null) return maxY!;
    if (_validData.isEmpty) return 100;
    final values = _validData.map((e) => e.y).toList();
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final range = _getDataRange();
    final result = dataMax + (range * 0.1);
    return result.isFinite ? result : 100;
  }

  double _getDataRange() {
    if (_validData.isEmpty) return 1;
    final values = _validData.map((e) => e.y).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final range = dataMax - dataMin;
    if (!range.isFinite || range <= 0) {
      return dataMax.abs().isFinite ? dataMax.abs() : 1;
    }
    return range;
  }

  double _calculateGridInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 0 || !range.isFinite) return 1;
    final interval = range / 5;
    if (!interval.isFinite) return 1;
    if (interval >= 1000) return (interval / 1000).ceilToDouble() * 1000;
    if (interval >= 100) return (interval / 100).ceilToDouble() * 100;
    if (interval >= 10) return (interval / 10).ceilToDouble() * 10;
    if (interval >= 1) return interval.ceilToDouble();
    final result = (interval * 10).ceilToDouble() / 10;
    return result.isFinite ? result : 1;
  }
}
