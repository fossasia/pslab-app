import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/dust_sensor_state_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/gauge_widget.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';

class DustSensorCard extends StatelessWidget {
  const DustSensorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DustSensorStateProvider>();
    final appLocalizations = getIt.get<AppLocalizations>();
    final width = MediaQuery.sizeOf(context).width;
    final isLargeScreen = width > 900;
    final gaugeSize = isLargeScreen ? 260.0 : width * 0.48;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: InstrumentGauge(
                currentValue: provider.currentReading.voltage,
                minValue: 0,
                maxValue: 5,
                interval: 1,
                unit: 'V',
                size: gaugeSize,
                decimalPlaces: 2,
              ),
            ),
          ),
          Text(
            '${appLocalizations.dustSensorRelativeSignal}: '
            '${provider.currentReading.relativeLevel.toStringAsFixed(0)}%',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            switch (provider.error) {
              DustSensorError.notConnected =>
                appLocalizations.dustSensorNotConnected,
              DustSensorError.readFailed =>
                appLocalizations.dustSensorReadFailed,
              null => provider.isReading
                  ? appLocalizations.dustSensorReadingCh1
                  : appLocalizations.dustSensorStopped,
            },
            textAlign: TextAlign.center,
            style: TextStyle(
              color: provider.error == null
                  ? Colors.blueGrey
                  : Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Instrumentstats(
            unit: 'V',
            titleFontSize: isLargeScreen ? 25 : 20,
            statFontSize: isLargeScreen ? 20 : 15,
            minValue: provider.minVoltage,
            avgValue: provider.averageVoltage,
            maxValue: provider.maxVoltage,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: provider.isReading ? provider.stop : provider.start,
                icon: Icon(provider.isReading ? Icons.stop : Icons.play_arrow),
                label: Text(provider.isReading
                    ? appLocalizations.stop
                    : appLocalizations.dustSensorStart),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: provider.reset,
                icon: const Icon(Icons.refresh),
                label: Text(appLocalizations.dustSensorReset),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
