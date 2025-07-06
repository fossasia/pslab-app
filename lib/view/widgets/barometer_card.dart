import 'package:pslab/view/widgets/gauge_widget.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/barometer_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';
import 'package:pslab/constants.dart';

import '../../theme/colors.dart';

class BarometerCard extends StatefulWidget {
  const BarometerCard({super.key});
  @override
  State<StatefulWidget> createState() => _BarometerCardState();
}

class _BarometerCardState extends State<BarometerCard> {
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
              return Row(
                children: [
                  Expanded(
                    flex: screenWidth < 500 ? 40 : 35,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 75,
                          child: Instrumentstats(
                            titleFontSize: titleFontSize,
                            statFontSize: statFontSize,
                            maxValue: maxPressure,
                            minValue: minPressure,
                            avgValue: avgPressure,
                            unit: atm,
                          ),
                        ),
                        Expanded(
                          flex: 25,
                          child:
                              _buildAltitudeTile(currentAltitude, statFontSize),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: screenWidth < 500 ? 60 : 65,
                    child: GaugeWidget(
                        gaugeSize: gaugeSize,
                        currentValue: currentPressure,
                        minValue: 0,
                        maxValue: 2,
                        unit: atm,
                        currentValueFontSize: pressureValueFontSize),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAltitudeTile(double currentAltitude, double fontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 400 ? 15.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            '$altitudeLabel ($meterUnit)',
            style: TextStyle(
              color: cardContentColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: instrumentStatBoxColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              currentAltitude.toStringAsFixed(2),
              style: TextStyle(
                color: cardContentColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
