import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:girix_code_gauge/girix_code_gauge.dart';
import 'package:pslab/providers/gas_sensor_state_provider.dart';
import 'package:pslab/theme/colors.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

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
      child: _buildSensorUI(provider),
    );
  }

  Widget _buildSensorUI(GasSensorStateProvider provider) {
    String mode = provider.getActiveMode();
    String unitText = mode == 'Raw' ? "LEVEL" : "PPM";

    double maxScaleLimit = mode == 'Raw' ? 1024.0 : 5000.0;
    double currentValue = provider.getCurrentValue().clamp(0.0, maxScaleLimit);
    String activeGasName = provider.getActiveMode();

    return Column(
      children: [
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, 20.0),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GxRadialGauge(
                    value: GaugeValue(
                        value: currentValue,
                        min: 0,
                        max: mode == 'Raw' ? 1024 : 5000),
                    size: const Size(220, 220),
                    startAngleInDegree: 140,
                    sweepAngleInDegree: 260,
                    showValueAtCenter: false,
                    showMajorTicks: true,
                    showLabels: true,
                    interval: mode == 'Raw' ? 200 : 1000,
                    labelTickStyle: const RadialTickLabelStyle(
                      padding: 22,
                      position: RadialElementPosition.outside,
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    majorTickStyle: RadialTickStyle(
                      color: Colors.blueGrey.shade300,
                      thickness: 2,
                      length: 12,
                      position: RadialElementPosition.outside,
                      alignment: RadialElementAlignment.start,
                    ),
                    style: const RadialGaugeStyle(
                      color: Color(0xFFEEEEEE),
                      thickness: 15,
                      gradient: LinearGradient(
                        colors: [
                          gaugeGradientStart,
                          gaugeGradientCenter,
                          gaugeGradientEnd
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    showNeedle: true,
                    needle: const RadialNeedle(
                      color: Color(0xFF424242),
                      shape: RadialNeedleShape.tapperedLine,
                      thickness: 8,
                      alignment: RadialElementAlignment.end,
                      circle: NeedleCircle(
                        radius: 8,
                        innerColor: Colors.black87,
                        paintingStyle: PaintingStyle.fill,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    child: Column(
                      children: [
                        Text(
                          currentValue.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unitText,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.blueGrey,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            activeGasName.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildBorderedStatBox(
                    appLocalizations.minLabel, provider.getMinValue())),
            const SizedBox(width: 8),
            Expanded(
                child: _buildBorderedStatBox(
                    appLocalizations.avgLabel, provider.getAverageValue())),
            const SizedBox(width: 8),
            Expanded(
                child: _buildBorderedStatBox(
                    appLocalizations.maxLabel, provider.getMaxValue())),
          ],
        ),
      ],
    );
  }

  Widget _buildBorderedStatBox(String label, double value) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(width: 1.2, color: primaryRed),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              value.toInt().toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: cardBackgroundColor,
              child: Text(
                label,
                style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
