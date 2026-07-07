import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data_points.dart';
import '../../providers/locator.dart';
import '../../theme/colors.dart';

AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

class SensorChartWidget extends StatelessWidget {
  final String title;
  final String yAxisLabel;
  final String? xAxisLabel;
  final List<ChartDataPoint> data;
  final Color lineColor;

  final List<ChartDataPoint>? data2;
  final Color? lineColor2;
  final List<ChartDataPoint>? data3;
  final Color? lineColor3;
  final List<String>? legendLabels;

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
    this.data2,
    this.lineColor2,
    this.data3,
    this.lineColor3,
    this.legendLabels,
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

  List<ChartDataPoint> _getValidData(List<ChartDataPoint>? input) {
    if (input == null) return [];
    return input.where((point) {
      return point.x.isFinite &&
          point.y.isFinite &&
          !point.x.isNaN &&
          !point.y.isNaN;
    }).toList();
  }

  List<ChartDataPoint> get _validData1 => _getValidData(data);
  List<ChartDataPoint> get _validData2 => _getValidData(data2);
  List<ChartDataPoint> get _validData3 => _getValidData(data3);

  bool get _hasAnyData =>
      _validData1.isNotEmpty ||
      _validData2.isNotEmpty ||
      _validData3.isNotEmpty;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: chartTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (legendLabels != null && legendLabels!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(legendLabels![0], lineColor),
                if (legendLabels!.length > 1 && data2 != null) ...[
                  const SizedBox(width: 16),
                  _buildLegendItem(
                      legendLabels![1], lineColor2 ?? Colors.green),
                ],
                if (legendLabels!.length > 2 && data3 != null) ...[
                  const SizedBox(width: 16),
                  _buildLegendItem(legendLabels![2], lineColor3 ?? Colors.red),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: chartTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      child: !_hasAnyData ? _buildNoDataView() : _buildLineChart(),
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
                if (_validData1.isNotEmpty)
                  _buildBarData(_validData1, lineColor),
                if (_validData2.isNotEmpty)
                  _buildBarData(_validData2, lineColor2 ?? Colors.green),
                if (_validData3.isNotEmpty)
                  _buildBarData(_validData3, lineColor3 ?? Colors.red),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final yValue = spot.y.isFinite
                          ? spot.y.toStringAsFixed(2)
                          : appLocalizations.notAvailable;

                      // Using the bar's color to match the tooltip text to the line
                      return LineTooltipItem(
                        '$yValue${unit ?? ''}',
                        TextStyle(
                          color: spot.bar.color ?? chartTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

  LineChartBarData _buildBarData(List<ChartDataPoint> validData, Color color) {
    return LineChartBarData(
      spots: validData.map((point) => FlSpot(point.x, point.y)).toList(),
      isCurved: isCurved,
      color: color,
      barWidth: lineWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: showDots,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 2,
            color: color,
            strokeWidth: 1,
            strokeColor: chartTextColor,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: false,
        color: color.withAlpha(26),
      ),
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
      ],
    );
  }
  

  double _getMinX() {
    if (minX != null) return minX!;
    if (!_hasAnyData) return 0;
    final allX =
        [..._validData1, ..._validData2, ..._validData3].map((e) => e.x);
    return allX.reduce((a, b) => a < b ? a : b);
  }

  double _getMaxX() {
    if (maxX != null) return maxX!;
    if (!_hasAnyData) return 10;
    final allX =
        [..._validData1, ..._validData2, ..._validData3].map((e) => e.x);
    return allX.reduce((a, b) => a > b ? a : b);
  }

  double _getMinY() {
    if (minY != null) return minY!;
    if (!_hasAnyData) return 0;
    final allY = [..._validData1, ..._validData2, ..._validData3]
        .map((e) => e.y)
        .toList();
    final dataMin = allY.reduce((a, b) => a < b ? a : b);
    final range = _getDataRange();
    final result = dataMin - (range * 0.1);
    return result.isFinite ? result : 0;
  }

  double _getMaxY() {
    if (maxY != null) return maxY!;
    if (!_hasAnyData) return 100;
    final allY = [..._validData1, ..._validData2, ..._validData3]
        .map((e) => e.y)
        .toList();
    final dataMax = allY.reduce((a, b) => a > b ? a : b);
    final range = _getDataRange();
    final result = dataMax + (range * 0.1);
    return result.isFinite ? result : 100;
  }

  double _getDataRange() {
    if (!_hasAnyData) return 1;
    final allY = [..._validData1, ..._validData2, ..._validData3]
        .map((e) => e.y)
        .toList();
    final dataMin = allY.reduce((a, b) => a < b ? a : b);
    final dataMax = allY.reduce((a, b) => a > b ? a : b);
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
