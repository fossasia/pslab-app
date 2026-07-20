import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/gas_sensor_state_provider.dart';
import 'package:pslab/theme/colors.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/gas_sensor_config_provider.dart';
import '../../providers/locator.dart';
import '../widgets/instruments_stats.dart';
import 'gauge_widget.dart';

class GasSensorCard extends StatefulWidget {
  const GasSensorCard({super.key});

  @override
  State<StatefulWidget> createState() => _GasSensorCardState();
}

class _GasSensorCardState extends State<GasSensorCard> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  @override
  Widget build(BuildContext context) {
    GasSensorStateProvider provider =
        Provider.of<GasSensorStateProvider>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    final gaugeSize = isLargeScreen ? 260.0 : screenWidth * 0.55;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 20.0 : 15.0;

    String mode = provider.getActiveMode();
    String unitText = mode == 'Raw' ? "LEVEL" : "PPM";

    double maxScaleLimit = mode == 'Raw' ? 1024.0 : 5000.0;
    double currentValue = provider.getCurrentValue();
    int gaugeInterval = mode == 'Raw' ? 200 : 1000;

    final List<String> allowedModes = [
      'Raw',
      'CO2',
      'NH3',
      'Alcohol',
      'CO',
      'Toluene',
      'Acetone'
    ];

    String currentMode = allowedModes.contains(mode) ? mode : 'Raw';

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 6),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: InstrumentGauge(
                size: gaugeSize,
                currentValue: currentValue,
                minValue: 0,
                maxValue: maxScaleLimit,
                interval: gaugeInterval,
                unit: unitText,
                decimalPlaces: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          PopupMenuButton<String>(
            initialValue: currentMode,
            color: Colors.white,
            position: PopupMenuPosition.under,
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 160),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (String newValue) {
              provider.setActiveMode(newValue);
              Provider.of<GasSensorConfigProvider>(context, listen: false)
                  .updateActiveGas(newValue);
            },
            itemBuilder: (BuildContext context) {
              return allowedModes.map((String value) {
                return PopupMenuItem<String>(
                  value: value,
                  child: Center(
                    child: Text(
                      value.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                );
              }).toList();
            },
            child: SizedBox(
              width: 160,
              height: 36,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      currentMode.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Instrumentstats(
            titleFontSize: titleFontSize,
            statFontSize: statFontSize,
            maxValue: provider.getMaxValue(),
            minValue: provider.getMinValue(),
            avgValue: provider.getAverageValue(),
            unit: unitText,
          ),
        ],
      ),
    );
  }
}
