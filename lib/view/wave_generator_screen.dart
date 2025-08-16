import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/wave_generator_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/analog_waveform_controls.dart';
import 'package:pslab/view/widgets/digital_waveform_controls.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/wave_generator_graph.dart';
import 'package:pslab/view/widgets/wave_generator_main_controls.dart';

class WaveGeneratorScreen extends StatefulWidget {
  final String sineWaveCircuit = 'assets/images/sin_wave_circuit.png';
  final String squareWaveCircuit = 'assets/images/square_wave_circuit.png';
  const WaveGeneratorScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WaveGeneratorScreenState();
}

class _WaveGeneratorScreenState extends State<WaveGeneratorScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _showGuide = false;

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getWaveGeneratorContent() {
    return [
      InstrumentIntroText(text: appLocalizations.waveGeneratorIntro),
      InstrumentIntroText(
        text: appLocalizations.sineWaveCaption,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentImage(imagePath: widget.sineWaveCircuit),
      InstrumentBulletPoint(text: appLocalizations.sineWaveBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.sineWaveBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.sineWaveBulletPoint3),
      InstrumentBulletPoint(text: appLocalizations.sineWaveBulletPoint4),
      InstrumentBulletPoint(text: appLocalizations.sineWaveBulletPoint5),
      InstrumentIntroText(
        text: appLocalizations.squareWaveCaption,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentImage(imagePath: widget.squareWaveCircuit),
      InstrumentBulletPoint(text: appLocalizations.squareWaveBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.squareWaveBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.squareWaveBulletPoint3),
      InstrumentBulletPoint(text: appLocalizations.squareWaveBulletPoint4),
      InstrumentBulletPoint(text: appLocalizations.squareWaveBulletPoint5),
      InstrumentIntroText(
        text: appLocalizations.pwmCaption,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(text: appLocalizations.pwmBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.pwmBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.pwmBulletPoint3),
      InstrumentBulletPoint(text: appLocalizations.pwmBulletPoint4),
    ];
  }

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
            return Stack(
              children: [
                CommonScaffold(
                  title: appLocalizations.waveGenerator,
                  body: Container(
                    margin:
                        const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0),
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
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                                                    .modeSelected =
                                                WaveConst.square;
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
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                  actions: [
                    IconButton(
                      icon: Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.save, color: Colors.white),
                      onPressed: () {},
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == appLocalizations.showGuide) {
                          setState(() {
                            _showGuide = !_showGuide;
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: appLocalizations.showGuide,
                          child: Text(appLocalizations.showGuide),
                        ),
                      ],
                    )
                  ],
                ),
                if (_showGuide)
                  InstrumentOverviewDrawer(
                    instrumentName: appLocalizations.waveGenerator,
                    content: _getWaveGeneratorContent(),
                    onHide: _hideInstrumentGuide,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
