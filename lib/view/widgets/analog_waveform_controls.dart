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
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  String iconSin = "assets/icons/ic_sin.png";
  String iconTriangular = "assets/icons/ic_triangular.png";
  String iconSawtooth = "assets/icons/ic_sawtooth.png";

  @override
  Widget build(BuildContext context) {
    WaveGeneratorStateProvider waveGeneratorStateProvider =
        Provider.of<WaveGeneratorStateProvider>(context);

    int currentAmpInt = waveGeneratorStateProvider.waveGeneratorConstants
                .wave[waveGeneratorStateProvider.selectedAnalogWave]
            ?[WaveConst.amplitude] ??
        30;
    double currentAmp = currentAmpInt / 10.0;
    List<double> ampOptions = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];

    if (!ampOptions.contains(currentAmp)) {
      ampOptions.add(currentAmp);
      ampOptions.sort();
    }

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
                        child: Semantics(
                          selected:
                              waveGeneratorStateProvider.selectedAnalogWave ==
                                  WaveConst.wave1,
                          child: Text(
                            appLocalizations.wave1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
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
                        child: Semantics(
                          selected:
                              waveGeneratorStateProvider.selectedAnalogWave ==
                                  WaveConst.wave2,
                          child: Text(
                            appLocalizations.wave2,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
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
                      flex: 28,
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
                        child: Semantics(
                          selected: waveGeneratorStateProvider.propSelected ==
                              WaveConst.frequency,
                          child: Text(
                            appLocalizations.freq,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
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
                      flex: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: buttonDisabledColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.only(left: 4, right: 0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            isExpanded: true,
                            value: currentAmp,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white, size: 18),
                            dropdownColor:
                                Theme.of(context).colorScheme.surface,
                            items: ampOptions.map((double value) {
                              return DropdownMenuItem<double>(
                                value: value,
                                child: Text(
                                  "±${value.toStringAsFixed(1)}V",
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 14),
                                ),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return ampOptions.map<Widget>((double value) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "Amp: ±${value.toStringAsFixed(1)}V",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (double? newValue) {
                              if (newValue != null) {
                                waveGeneratorStateProvider
                                    .setAmplitude(newValue);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 28,
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
                              child: Semantics(
                                selected:
                                    waveGeneratorStateProvider.propSelected ==
                                        WaveConst.phase,
                                child: Text(
                                  appLocalizations.phase,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
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
                      flex: 12,
                      child: IconButton(
                        tooltip: appLocalizations.sine,
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
                        icon: Semantics(
                          selected: waveGeneratorStateProvider
                                          .waveGeneratorConstants.wave[
                                      waveGeneratorStateProvider
                                          .selectedAnalogWave]
                                  ?[WaveConst.waveType] ==
                              WaveGeneratorStateProvider.sin,
                          child: Image.asset(
                            iconSin,
                            color: Colors.white,
                          ),
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
                      flex: 12,
                      child: IconButton(
                        tooltip: appLocalizations.triangular,
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
                        icon: Semantics(
                          selected: waveGeneratorStateProvider
                                          .waveGeneratorConstants.wave[
                                      waveGeneratorStateProvider
                                          .selectedAnalogWave]
                                  ?[WaveConst.waveType] ==
                              WaveGeneratorStateProvider.triangular,
                          child: Image.asset(
                            iconTriangular,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => {
                          setState(
                            () => waveGeneratorStateProvider.setAnalogWaveType(
                                WaveGeneratorStateProvider.triangular),
                          ),
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 12,
                      child: IconButton(
                        tooltip: appLocalizations.sawtooth,
                        style: TextButton.styleFrom(
                          backgroundColor: waveGeneratorStateProvider
                                              .waveGeneratorConstants.wave[
                                          waveGeneratorStateProvider
                                              .selectedAnalogWave]
                                      ?[WaveConst.waveType] ==
                                  WaveGeneratorStateProvider.sawtooth
                              ? buttonEnabledColor
                              : buttonDisabledColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: Semantics(
                          selected: waveGeneratorStateProvider
                                          .waveGeneratorConstants.wave[
                                      waveGeneratorStateProvider
                                          .selectedAnalogWave]
                                  ?[WaveConst.waveType] ==
                              WaveGeneratorStateProvider.sawtooth,
                          child: Image.asset(
                            iconSawtooth,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => {
                          setState(
                            () => waveGeneratorStateProvider.setAnalogWaveType(
                                WaveGeneratorStateProvider.sawtooth),
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
