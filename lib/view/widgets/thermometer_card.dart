import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/gauge_widget.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/thermometer_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

class ThermometerCard extends StatefulWidget {
  const ThermometerCard({super.key});
  @override
  State<StatefulWidget> createState() => _ThermometerCardState();
}

class _ThermometerCardState extends State<ThermometerCard> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    ThermometerStateProvider provider =
        Provider.of<ThermometerStateProvider>(context);
    double currentTemp = provider.getCurrentTemperature();
    double minTemp = provider.getMinTemperature();
    double maxTemp = provider.getMaxTemperature();
    double avgTemp = provider.getAverageTemperature();
    final cardMargin = screenWidth < 400 ? 8.0 : 12.0;
    final cardPadding = screenWidth < 400 ? 12.0 : 20.0;
    final gaugeSize = isLargeScreen ? 240.0 : screenWidth * 0.45;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 20.0 : 15.0;
    final tempValueFontSize = isLargeScreen ? 20.0 : 16.0;

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
                          currentValue: currentTemp,
                          minValue: -40,
                          maxValue: 125,
                          unit: appLocalizations.celsius,
                          currentValueFontSize: tempValueFontSize),
                    ),
                    Expanded(
                      flex: 60,
                      child: Instrumentstats(
                        titleFontSize: titleFontSize,
                        statFontSize: statFontSize,
                        maxValue: maxTemp,
                        minValue: minTemp,
                        avgValue: avgTemp,
                        unit: appLocalizations.celsius,
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
                        maxValue: maxTemp,
                        minValue: minTemp,
                        avgValue: avgTemp,
                        unit: appLocalizations.celsius,
                      ),
                    ),
                    Expanded(
                      flex: screenWidth < 500 ? 60 : 65,
                      child: GaugeWidget(
                          gaugeSize: gaugeSize,
                          currentValue: currentTemp,
                          minValue: -40,
                          maxValue: 125,
                          unit: appLocalizations.celsius,
                          currentValueFontSize: tempValueFontSize),
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
