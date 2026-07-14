import 'package:pslab/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/soundmeter_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

import 'gauge_widget.dart';

class SoundMeterCard extends StatefulWidget {
  const SoundMeterCard({super.key});
  @override
  State<StatefulWidget> createState() => _SoundMeterCardState();
}

class _SoundMeterCardState extends State<SoundMeterCard> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;

    SoundMeterStateProvider provider =
        Provider.of<SoundMeterStateProvider>(context);

    double currentDb = provider.getCurrentDb();
    double minDb = provider.getMinDb();
    double maxDb = provider.getMaxDb();
    double avgDb = provider.getAverageDb();

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
                  currentValue: currentDb,
                  minValue: 0,
                  maxValue: 200,
                  interval: 20,
                  unit: appLocalizations.db,
                  decimalPlaces: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Instrumentstats(
              titleFontSize: titleFontSize,
              statFontSize: statFontSize,
              maxValue: maxDb,
              minValue: minDb,
              avgValue: avgDb,
              unit: appLocalizations.db,
            ),
          ],
        ),
      ),
    );
  }
}
