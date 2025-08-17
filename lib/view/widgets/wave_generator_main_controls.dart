import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/wave_generator_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class WaveGeneratorMainControls extends StatefulWidget {
  const WaveGeneratorMainControls({super.key});

  @override
  State<StatefulWidget> createState() => _WaveGeneratorMainControlsState();
}

class _WaveGeneratorMainControlsState extends State<WaveGeneratorMainControls> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  String iconSin = "assets/icons/ic_sin.png";
  String iconTriangular = "assets/icons/ic_triangular.png";
  String iconPwm = "assets/icons/ic_pwm_pic.png";
  var labelMap = {};
  var unitMap = {};
  final minValues = {
    WaveConst.frequency: WaveData.freqMin.value,
    WaveConst.phase: WaveData.phaseMin.value,
    WaveConst.duty: WaveData.dutyMin.value,
  };
  final maxValues = {
    WaveConst.frequency: WaveData.freqMax.value,
    WaveConst.phase: WaveData.phaseMax.value,
    WaveConst.duty: WaveData.dutyMax.value,
  };
  @override
  Widget build(BuildContext context) {
    labelMap = {
      WaveConst.frequency: appLocalizations.frequency,
      WaveConst.phase: appLocalizations.phaseOffset,
      WaveConst.duty: appLocalizations.duty,
    };
    unitMap = {
      WaveConst.frequency: appLocalizations.unitHz,
      WaveConst.phase: appLocalizations.unitDeg,
      WaveConst.duty: appLocalizations.unitPercentage,
    };
    return Consumer<WaveGeneratorStateProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Expanded(
              flex: 75,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                color: Colors.black,
                child: Column(
                  children: [
                    Expanded(
                      flex: 80,
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 20,
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      provider.waveGeneratorConstants
                                                  .modeSelected ==
                                              WaveConst.square
                                          ? (provider.waveGeneratorConstants
                                                              .wave[
                                                          provider
                                                              .selectedAnalogWave]
                                                      ?[WaveConst.waveType] ==
                                                  WaveGeneratorStateProvider.sin
                                              ? iconSin
                                              : iconTriangular)
                                          : iconPwm,
                                      height: 40,
                                      width: 40,
                                    ),
                                    Text(
                                      provider.waveGeneratorConstants
                                                  .modeSelected ==
                                              WaveConst.square
                                          ? (provider.waveGeneratorConstants
                                                              .wave[
                                                          provider
                                                              .selectedAnalogWave]
                                                      ?[WaveConst.waveType] ==
                                                  WaveGeneratorStateProvider.sin
                                              ? appLocalizations.sine
                                              : appLocalizations.tri)
                                          : appLocalizations.pwm.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const VerticalDivider(),
                            Expanded(
                              flex: 80,
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: 8,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.waveGeneratorConstants
                                                  .modeSelected ==
                                              WaveConst.square
                                          ? '${appLocalizations.frequency}: ${provider.waveGeneratorConstants.wave[provider.selectedAnalogWave]?[WaveConst.frequency]} Hz'
                                          : '${appLocalizations.frequency}: ${provider.waveGeneratorConstants.wave[WaveConst.sqr1]?[WaveConst.frequency]} Hz',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          provider.waveGeneratorConstants
                                                      .modeSelected ==
                                                  WaveConst.square
                                              ? '${appLocalizations.phase}: ${provider.waveGeneratorConstants.wave[provider.selectedAnalogWave]?[WaveConst.phase] ?? '--'}°'
                                              : '${appLocalizations.phase}: ${provider.waveGeneratorConstants.wave[provider.selectedDigitalWave]?[WaveConst.phase] ?? '--'}°',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        provider.waveGeneratorConstants
                                                    .modeSelected ==
                                                WaveConst.pwm
                                            ? Text(
                                                '${appLocalizations.duty}: ${provider.waveGeneratorConstants.wave[provider.selectedDigitalWave]?[WaveConst.duty]}%',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: const Divider(),
                    ),
                    Expanded(
                      flex: 20,
                      child: Transform.translate(
                        offset: const Offset(0, -8),
                        child: Container(
                          margin: const EdgeInsets.only(
                            left: 32,
                          ),
                          alignment: Alignment.centerLeft,
                          child: provider.propSelected != null
                              ? Text(
                                  provider.waveGeneratorConstants
                                              .modeSelected ==
                                          WaveConst.square
                                      ? '${labelMap[provider.propSelected]}: ${provider.waveGeneratorConstants.wave[provider.selectedAnalogWave]?[provider.propSelected]}${unitMap[provider.propSelected]}'
                                      : (provider.propSelected ==
                                              WaveConst.frequency
                                          ? '${labelMap[provider.propSelected]}: ${provider.waveGeneratorConstants.wave[WaveConst.sqr1]?[provider.propSelected]}${unitMap[provider.propSelected]}'
                                          : '${labelMap[provider.propSelected]}: ${provider.waveGeneratorConstants.wave[provider.selectedDigitalWave]?[provider.propSelected]}${unitMap[provider.propSelected]}'),
                                  style: TextStyle(
                                    color: waveGeneratorPropTextColor,
                                    fontSize: 16,
                                  ),
                                )
                              : Container(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  height: 35,
                  width: 30,
                  child: IconButton.filled(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.chevron_left),
                    onPressed: () async {
                      if (provider.propSelected != null) {
                        await provider.decrementValue();
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: provider.propSelected == null
                          ? buttonDisabledColor
                          : buttonEnabledColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      inactiveTrackColor: sliderInActiveColor,
                      trackHeight: 1,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      activeColor: provider.propSelected == null
                          ? buttonDisabledColor
                          : sliderActiveColor,
                      min: minValues[provider.propSelected]?.toDouble() ??
                          WaveData.freqMin.value.toDouble(),
                      max: maxValues[provider.propSelected]?.toDouble() ??
                          WaveData.freqMax.value.toDouble(),
                      value: provider.waveGeneratorConstants.modeSelected ==
                              WaveConst.square
                          ? provider
                                  .waveGeneratorConstants
                                  .wave[provider.selectedAnalogWave]![
                                      provider.propSelected]
                                  ?.toDouble() ??
                              WaveData.freqMin.value.toDouble()
                          : (provider.propSelected == WaveConst.frequency
                              ? provider
                                      .waveGeneratorConstants
                                      .wave[WaveConst.sqr1]![
                                          provider.propSelected]
                                      ?.toDouble() ??
                                  WaveData.freqMin.value.toDouble()
                              : provider
                                      .waveGeneratorConstants
                                      .wave[provider.selectedDigitalWave]![
                                          provider.propSelected]
                                      ?.toDouble() ??
                                  WaveData.freqMin.value.toDouble()),
                      onChanged: (value) async {
                        if (provider.propSelected != null) {
                          await provider.setValue(value.round());
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 35,
                  width: 30,
                  child: IconButton.filled(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.chevron_right),
                    onPressed: () async {
                      if (provider.propSelected != null) {
                        await provider.incrementValue();
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: provider.propSelected == null
                          ? buttonDisabledColor
                          : buttonEnabledColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
