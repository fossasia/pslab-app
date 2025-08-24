import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/wave_generator_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class AnalogWaveformControls extends StatefulWidget {
  const AnalogWaveformControls({super.key});

  @override
  State<StatefulWidget> createState() => _AnalogWaveformControlsState();
}

class _AnalogWaveformControlsState extends State<AnalogWaveformControls> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  String iconSin = "assets/icons/ic_sin.png";
  String iconTriangular = "assets/icons/ic_triangular.png";
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
                              waveGeneratorStateProvider.selectedAnalogWave ==
                                      WaveConst.wave1
                                  ? buttonEnabledColor
                                  : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.wave1,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {
                          setState(
                            () {
                              waveGeneratorStateProvider
                                  .setAnalogSelectedWave(WaveConst.wave1);
                            },
                          ),
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              waveGeneratorStateProvider.selectedAnalogWave ==
                                      WaveConst.wave2
                                  ? buttonEnabledColor
                                  : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.wave2,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {
                          setState(
                            () {
                              waveGeneratorStateProvider
                                  .setAnalogSelectedWave(WaveConst.wave2);
                            },
                          ),
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
                          setState(
                            () {
                              waveGeneratorStateProvider
                                  .setPropSelected(WaveConst.frequency);
                            },
                          ),
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 35,
                      child: waveGeneratorStateProvider.selectedAnalogWave ==
                              WaveConst.wave2
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
                                setState(
                                  () {
                                    waveGeneratorStateProvider
                                        .setPropSelected(WaveConst.phase);
                                  },
                                ),
                              },
                            )
                          : Container(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 15,
                      child: IconButton(
                        style: TextButton.styleFrom(
                          backgroundColor: waveGeneratorStateProvider
                                              .waveGeneratorConstants.wave[
                                          waveGeneratorStateProvider
                                              .selectedAnalogWave]
                                      ?[WaveConst.waveType] ==
                                  WaveGeneratorStateProvider.sin
                              ? buttonEnabledColor
                              : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: Image.asset(
                          iconSin,
                          color: Colors.white,
                        ),
                        onPressed: () => {
                          setState(
                            () => waveGeneratorStateProvider.setAnalogWaveType(
                                WaveGeneratorStateProvider.sin),
                          ),
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 15,
                      child: IconButton(
                        style: TextButton.styleFrom(
                          backgroundColor: waveGeneratorStateProvider
                                              .waveGeneratorConstants.wave[
                                          waveGeneratorStateProvider
                                              .selectedAnalogWave]
                                      ?[WaveConst.waveType] ==
                                  WaveGeneratorStateProvider.triangular
                              ? buttonEnabledColor
                              : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: Image.asset(
                          iconTriangular,
                          color: Colors.white,
                        ),
                        onPressed: () => {
                          setState(
                            () => waveGeneratorStateProvider.setAnalogWaveType(
                                WaveGeneratorStateProvider.triangular),
                          ),
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
                appLocalizations.analog,
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
