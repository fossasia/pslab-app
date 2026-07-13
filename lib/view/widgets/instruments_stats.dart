import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class Instrumentstats extends StatelessWidget {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  final String unit;
  final double minValue;
  final double maxValue;
  final double avgValue;
  final double? currentAltitude;

  final double titleFontSize;
  final double statFontSize;

  const Instrumentstats({
    super.key,
    required this.unit,
    required this.titleFontSize,
    required this.avgValue,
    required this.maxValue,
    required this.minValue,
    required this.statFontSize,
    this.currentAltitude,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child:
              _buildBorderedStatBox(appLocalizations.minLabel, minValue, unit),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:
              _buildBorderedStatBox(appLocalizations.avgLabel, avgValue, unit),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:
              _buildBorderedStatBox(appLocalizations.maxLabel, maxValue, unit),
        ),
        if (currentAltitude != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildBorderedStatBox(
              appLocalizations.altitudeLabel,
              currentAltitude!,
              appLocalizations.meterUnit,
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildBorderedStatBox(String label, double value, String displayUnit) {
    String fullLabel = '$label ($displayUnit)';

    String displayValue = value.truncateToDouble() == value
        ? value.toInt().toString()
        : value.toStringAsFixed(2);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(width: 1.2, color: primaryRed),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 3,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: cardBackgroundColor,
              child: Text(
                fullLabel.toUpperCase(),
                style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 8,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        )
      ],
    );
  }
}
