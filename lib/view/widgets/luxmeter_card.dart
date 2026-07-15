import 'package:pslab/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/luxmeter_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';

import 'gauge_widget.dart';

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
                  currentValue: currentLux,
                  minValue: 0,
                  maxValue: 10000,
                  interval: 2000,
                  unit: 'Lx',
                  decimalPlaces: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Instrumentstats(
              titleFontSize: titleFontSize,
              statFontSize: statFontSize,
              maxValue: maxLux,
              minValue: minLux,
              avgValue: avgLux,
              unit: 'Lx',
            ),
          ],
        ),
      ),
    );
  }
}
