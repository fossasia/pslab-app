import 'package:pslab/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/barometer_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

import 'gauge_widget.dart';

class BarometerCard extends StatefulWidget {
  const BarometerCard({super.key});
  @override
  State<StatefulWidget> createState() => _BarometerCardState();
}

class _BarometerCardState extends State<BarometerCard> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

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
    final gaugeSize = isLargeScreen ? 260.0 : screenWidth * 0.55;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 15.0 : 10.0;

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
                  currentValue: currentPressure,
                  minValue: 0,
                  maxValue: 2,
                  interval: 1,
                  unit: appLocalizations.atm,
                  decimalPlaces: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Instrumentstats(
              titleFontSize: titleFontSize,
              statFontSize: statFontSize,
              maxValue: maxPressure,
              minValue: minPressure,
              avgValue: avgPressure,
              unit: appLocalizations.atm,
              currentAltitude: currentAltitude,
            ),
          ],
        ),
      ),
    );
  }
}
