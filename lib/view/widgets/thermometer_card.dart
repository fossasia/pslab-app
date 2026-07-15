import 'package:pslab/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/thermometer_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';
import 'package:pslab/providers/thermometer_config_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

import 'gauge_widget.dart';

class ThermometerCard extends StatefulWidget {
  const ThermometerCard({super.key});
  @override
  State<StatefulWidget> createState() => _ThermometerCardState();
}

class _ThermometerCardState extends State<ThermometerCard> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;

    ThermometerStateProvider stateProvider =
        Provider.of<ThermometerStateProvider>(context);
    ThermometerConfigProvider configProvider =
        Provider.of<ThermometerConfigProvider>(context);

    double currentTemp = stateProvider.getCurrentTemperature();
    double minTemp = stateProvider.getMinTemperature();
    double maxTemp = stateProvider.getMaxTemperature();
    double avgTemp = stateProvider.getAverageTemperature();

    bool isFahrenheit = configProvider.config.unit == 'Fahrenheit';
    String activeUnit = isFahrenheit
        ? appLocalizations.fahrenheitUnit
        : appLocalizations.celsius;

    double gaugeMin = isFahrenheit ? -40.0 : -40.0;
    double gaugeMax = isFahrenheit ? 257.0 : 125.0;
    int gaugeInterval = isFahrenheit ? 50 : 20;

    final cardMargin = screenWidth < 400 ? 8.0 : 12.0;
    final cardPadding = screenWidth < 400 ? 12.0 : 20.0;
    final gaugeSize = isLargeScreen ? 260.0 : screenWidth * 0.55;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 20.0 : 15.0;

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
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: InstrumentGauge(
                  size: gaugeSize,
                  currentValue: currentTemp,
                  minValue: gaugeMin,
                  maxValue: gaugeMax,
                  interval: gaugeInterval,
                  unit: activeUnit,
                  decimalPlaces: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Instrumentstats(
              titleFontSize: titleFontSize,
              statFontSize: statFontSize,
              maxValue: maxTemp,
              minValue: minTemp,
              avgValue: avgTemp,
              unit: activeUnit,
            ),
          ],
        ),
      ),
    );
  }
}
