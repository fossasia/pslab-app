import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/analog_waveform_controls.dart';
import 'package:pslab/view/widgets/wave_generator_graph.dart';
import 'package:pslab/view/widgets/wave_generator_main_controls.dart';

class WaveGeneratorScreen extends StatefulWidget {
  const WaveGeneratorScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WaveGeneratorScreenState();
}

class _WaveGeneratorScreenState extends State<WaveGeneratorScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Wave Generator',
      body: Container(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              flex: 30,
              child: Container(
                color: chartBackgroundColor,
                child: WaveGeneratorGraph(),
              ),
            ),
            Expanded(
              flex: 30,
              child: Column(
                children: [
                  Expanded(
                    flex: 70,
                    child: AnalogWaveformControls(),
                  ),
                  Expanded(
                    flex: 30,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              appLocalizations.produceSound,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () => {},
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              appLocalizations.analog,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () => {},
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              appLocalizations.digital,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () => {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 40,
              child: WaveGeneratorMainControls(),
            ),
          ],
        ),
      ),
    );
  }
}
