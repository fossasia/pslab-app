import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/wave_generator_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class DigitalWaveformControls extends StatefulWidget {
  const DigitalWaveformControls({super.key});

  @override
  State<StatefulWidget> createState() => _DigitalWaveformControlsState();
}

class _DigitalWaveformControlsState extends State<DigitalWaveformControls> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  @override
  Widget build(BuildContext context) {
    WaveGeneratorStateProvider waveGeneratorStateProvider =
        Provider.of<WaveGeneratorStateProvider>(context);
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(width: 3, color: primaryRed),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              waveGeneratorStateProvider.selectedDigitalWave ==
                                      WaveConst.sqr1
                                  ? buttonEnabledColor
                                  : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.sqr1.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {
                          setState(() {
                            waveGeneratorStateProvider
                                .setDigitalSelectedWave(WaveConst.sqr1);
                          })
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              waveGeneratorStateProvider.selectedDigitalWave ==
                                      WaveConst.sqr2
                                  ? buttonEnabledColor
                                  : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.sqr2.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {
                          setState(() {
                            waveGeneratorStateProvider
                                .setDigitalSelectedWave(WaveConst.sqr2);
                          })
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              waveGeneratorStateProvider.selectedDigitalWave ==
                                      WaveConst.sqr3
                                  ? buttonEnabledColor
                                  : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.sqr3.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {
                          setState(() {
                            waveGeneratorStateProvider
                                .setDigitalSelectedWave(WaveConst.sqr3);
                          })
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              waveGeneratorStateProvider.selectedDigitalWave ==
                                      WaveConst.sqr4
                                  ? buttonEnabledColor
                                  : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.sqr4.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {
                          setState(() {
                            waveGeneratorStateProvider
                                .setDigitalSelectedWave(WaveConst.sqr4);
                          })
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 35,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              waveGeneratorStateProvider.propSelected ==
                                      WaveConst.frequency
                                  ? buttonEnabledColor
                                  : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.freq,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {
                          setState(() {
                            waveGeneratorStateProvider
                                .setPropSelected(WaveConst.frequency);
                          })
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 35,
                      child: waveGeneratorStateProvider.selectedDigitalWave !=
                              WaveConst.sqr1
                          ? TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    waveGeneratorStateProvider.propSelected ==
                                            WaveConst.phase
                                        ? buttonEnabledColor
                                        : buttonDisabledColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                appLocalizations.phase,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: () => {
                                setState(() {
                                  waveGeneratorStateProvider
                                      .setPropSelected(WaveConst.phase);
                                })
                              },
                            )
                          : Container(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 35,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              waveGeneratorStateProvider.propSelected ==
                                      WaveConst.duty
                                  ? buttonEnabledColor
                                  : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.duty,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {
                          setState(() {
                            waveGeneratorStateProvider
                                .setPropSelected(WaveConst.duty);
                          })
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: oscilloscopeOptionTitleBoxColor),
              child: Text(
                appLocalizations.digital,
                style: TextStyle(
                  color: oscilloscopeOptionTitleColor,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
