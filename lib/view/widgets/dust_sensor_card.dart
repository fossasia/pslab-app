import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/gauge_widget.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/dust_sensor_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

class DustSensorCard extends StatefulWidget {
  const DustSensorCard({super.key});
  @override
  State<StatefulWidget> createState() => _DustSensorCardState();
}

class _DustSensorCardState extends State<DustSensorCard> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    DustSensorStateProvider provider =
        Provider.of<DustSensorStateProvider>(context);
    double currentDust = provider.getCurrentDust();
    double ppm = provider.getPPM();
    String airQuality = provider.getAirQuality();
    final cardMargin = screenWidth < 400 ? 8.0 : 12.0;
    final cardPadding = screenWidth < 400 ? 12.0 : 20.0;
    final gaugeSize = isLargeScreen ? 240.0 : screenWidth * 0.45;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 20.0 : 15.0;
    final dustValueFontSize = isLargeScreen ? 20.0 : 16.0;

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
                          currentValue: ppm,
                          minValue: 0,
                          maxValue: 100,
                          unit: appLocalizations.ppm,
                          currentValueFontSize: dustValueFontSize,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoTile(
                              appLocalizations.ppm,
                              ppm.toStringAsFixed(2),
                              titleFontSize,
                              statFontSize),
                          const SizedBox(height: 16),
                          _buildInfoTile(appLocalizations.airQuality,
                              airQuality, titleFontSize, statFontSize),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      flex: screenWidth < 500 ? 40 : 35,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoTile(
                              appLocalizations.ppm,
                              ppm.toStringAsFixed(2),
                              titleFontSize * 0.8,
                              statFontSize),
                          const SizedBox(height: 12),
                          _buildInfoTile(appLocalizations.airQuality,
                              airQuality, titleFontSize * 0.8, statFontSize),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: screenWidth < 500 ? 60 : 65,
                      child: GaugeWidget(
                          gaugeSize: gaugeSize,
                          currentValue: ppm,
                          minValue: 0,
                          maxValue: 100,
                          unit: appLocalizations.ppm,
                          currentValueFontSize: dustValueFontSize),
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

  Widget _buildInfoTile(
      String label, String value, double labelSize, double valueSize) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: blackTextColor,
            fontSize: labelSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: instrumentStatBoxColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: cardContentColor,
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
