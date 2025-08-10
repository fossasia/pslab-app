import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/wave_generator_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/analog_waveform_controls.dart';
import 'package:pslab/view/widgets/digital_waveform_controls.dart';
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
    return SafeArea(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<WaveGeneratorStateProvider>(
            create: (_) => WaveGeneratorStateProvider(),
          ),
        ],
        child: Consumer<WaveGeneratorStateProvider>(
          builder: (context, provider, _) {
            return CommonScaffold(
              title: appLocalizations.waveGenerator,
              body: Container(
                margin: const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0),
                child: Column(
                  children: [
                    Expanded(
                      flex: 30,
                      child: Container(
                        color: chartBackgroundColor,
                        child: WaveGeneratorGraph(),
                      ),
                    ),
                    Column(
                      children: [
                        provider.waveGeneratorConstants.modeSelected ==
                                WaveConst.square
                            ? AnalogWaveformControls()
                            : DigitalWaveformControls(),
                        SizedBox(
                          height: 60,
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
                                    backgroundColor: provider
                                                .waveGeneratorConstants
                                                .modeSelected ==
                                            WaveConst.square
                                        ? buttonEnabledColor
                                        : buttonDisabledColor,
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
                                  onPressed: () => {
                                    setState(
                                      () {
                                        provider.waveGeneratorConstants
                                            .modeSelected = WaveConst.square;
                                        provider.propSelected = null;
                                        provider.previewWave();
                                      },
                                    ),
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: provider
                                                .waveGeneratorConstants
                                                .modeSelected ==
                                            WaveConst.pwm
                                        ? buttonEnabledColor
                                        : buttonDisabledColor,
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
                                  onPressed: () => {
                                    setState(
                                      () {
                                        provider.waveGeneratorConstants
                                            .modeSelected = WaveConst.pwm;
                                        provider.propSelected = null;
                                        provider.previewWave();
                                      },
                                    ),
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      flex: 40,
                      child: WaveGeneratorMainControls(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
