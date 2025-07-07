import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/gauge_widget.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/luxmeter_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';

class LuxMeterCard extends StatefulWidget {
  const LuxMeterCard({super.key});
  @override
  State<StatefulWidget> createState() => _LuxMeterCardState();
}

class _LuxMeterCardState extends State<LuxMeterCard> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    LuxMeterStateProvider provider =
        Provider.of<LuxMeterStateProvider>(context);
    double currentLux = provider.getCurrentLux();
    double minLux = provider.getMinLux();
    double maxLux = provider.getMaxLux();
    double avgLux = provider.getAverageLux();
    final cardMargin = screenWidth < 400 ? 8.0 : 16.0;
    final cardPadding = screenWidth < 400 ? 12.0 : 20.0;
    final gaugeSize = isLargeScreen ? 240.0 : screenWidth * 0.45;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 20.0 : 15.0;
    final luxValueFontSize = isLargeScreen ? 20.0 : 16.0;

    return Card(
      margin: EdgeInsets.all(cardMargin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isLargeScreen) {
                return Column(
                  children: [
                    Expanded(
                      flex: 40,
                      child: GaugeWidget(
                          gaugeSize: gaugeSize,
                          currentValue: currentLux,
                          minValue: 0,
                          maxValue: 10000,
                          unit: 'Lx',
                          currentValueFontSize: luxValueFontSize),
                    ),
                    Expanded(
                      flex: 60,
                      child: Instrumentstats(
                        titleFontSize: titleFontSize,
                        statFontSize: statFontSize,
                        maxValue: maxLux,
                        minValue: minLux,
                        avgValue: avgLux,
                        unit: 'Lx',
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      flex: screenWidth < 500 ? 40 : 35,
                      child: Instrumentstats(
                        titleFontSize: titleFontSize,
                        statFontSize: statFontSize,
                        maxValue: maxLux,
                        minValue: minLux,
                        avgValue: avgLux,
                        unit: 'Lx',
                      ),
                    ),
                    Expanded(
                      flex: screenWidth < 500 ? 60 : 65,
                      child: GaugeWidget(
                          gaugeSize: gaugeSize,
                          currentValue: currentLux,
                          minValue: 0,
                          maxValue: 10000,
                          unit: 'Lx',
                          currentValueFontSize: luxValueFontSize),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
