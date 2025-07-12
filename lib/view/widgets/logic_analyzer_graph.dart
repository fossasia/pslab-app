import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/logic_analyzer_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class LogicAnalyzerGraph extends StatefulWidget {
  const LogicAnalyzerGraph({super.key});

  @override
  State<StatefulWidget> createState() => _LogicAnalyzerGraphState();
}

class _LogicAnalyzerGraphState extends State<LogicAnalyzerGraph> {
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

  Widget topTitleWidgets(double value, TitleMeta meta) {
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
    return Consumer<LogicAnalyzerStateProvider>(
        builder: (context, provider, _) {
      return !provider.isProcessing
          ? SizedBox(
              child: provider.isData
                  ? LineChart(
                      transformationConfig: FlTransformationConfig(
                        minScale: 1,
                        maxScale: 1000,
                        scaleAxis: FlScaleAxis.horizontal,
                        panEnabled: true,
                        scaleEnabled: true,
                      ),
                      LineChartData(
                        backgroundColor: chartBackgroundColor,
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: AxisTitles(
                            axisNameWidget: Text(
                              appLocalizations.logicAnalyzerAxisTitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: chartTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            axisNameSize: 20,
                            sideTitles: SideTitles(
                              maxIncluded: false,
                              reservedSize: 20,
                              showTitles: true,
                              getTitlesWidget: topTitleWidgets,
                            ),
                          ),
                          bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              maxIncluded: false,
                              minIncluded: false,
                              interval: 1,
                              reservedSize: 30,
                              showTitles: true,
                              getTitlesWidget: sideTitleWidgets,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: true,
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
                        clipData: const FlClipData.all(),
                        lineBarsData: provider.createPlots(),
                        maxY: provider.getMaxY(),
                        minY: provider.getMinY(),
                      ),
                    )
                  : Center(
                      child: Text(
                        appLocalizations.noChartDataAvailable,
                        style: TextStyle(
                          color: logicAnalyzerGraphTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
            )
          : SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: primaryRed,
                ),
              ),
            );
    });
  }
}
