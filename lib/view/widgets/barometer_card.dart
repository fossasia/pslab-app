import 'package:pslab/view/widgets/gauge_widget.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/barometer_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

import '../../theme/colors.dart';

class BarometerCard extends StatefulWidget {
  const BarometerCard({super.key});
  @override
  State<StatefulWidget> createState() => _BarometerCardState();
}

class _BarometerCardState extends State<BarometerCard> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    BarometerStateProvider provider =
        Provider.of<BarometerStateProvider>(context);
    double currentPressure = provider.getCurrentPressure();
    double minPressure = provider.getMinPressure();
    double maxPressure = provider.getMaxPressure();
    double avgPressure = provider.getAveragePressure();
    double currentAltitude = provider.getCurrentAltitude();
    final cardMargin = screenWidth < 400 ? 8.0 : 16.0;
    final cardPadding = screenWidth < 400 ? 12.0 : 20.0;
    final gaugeSize = isLargeScreen ? 240.0 : screenWidth * 0.45;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 15.0 : 10.0;
    final pressureValueFontSize = isLargeScreen ? 20.0 : 16.0;

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
                      child: Center(
                        child: GaugeWidget(
                          gaugeSize: gaugeSize,
                          currentValue: currentPressure,
                          minValue: 0,
                          maxValue: 2,
                          unit: appLocalizations.atm,
                          currentValueFontSize: pressureValueFontSize,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 60,
                      child: Instrumentstats(
                        titleFontSize: titleFontSize,
                        statFontSize: statFontSize,
                        maxValue: maxPressure,
                        minValue: minPressure,
                        avgValue: avgPressure,
                        unit: appLocalizations.atm,
                        currentAltitude: currentAltitude,
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
                        maxValue: maxPressure,
                        minValue: minPressure,
                        avgValue: avgPressure,
                        unit: appLocalizations.atm,
                        currentAltitude: currentAltitude,
                      ),
                    ),
                    Expanded(
                      flex: screenWidth < 500 ? 60 : 65,
                      child: GaugeWidget(
                          gaugeSize: gaugeSize,
                          currentValue: currentPressure,
                          minValue: 0,
                          maxValue: 2,
                          unit: appLocalizations.atm,
                          currentValueFontSize: pressureValueFontSize),
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
