import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/wave_generator_config_provider.dart';
import 'package:pslab/providers/wave_generator_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/wave_generator_config_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/analog_waveform_controls.dart';
import 'package:pslab/view/widgets/digital_waveform_controls.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/wave_generator_graph.dart';
import 'package:pslab/view/widgets/wave_generator_main_controls.dart';

class WaveGeneratorScreen extends StatefulWidget {
  final String sineWaveCircuit = 'assets/images/sin_wave_gen_circuit.png';
  final String squareWaveCircuit = 'assets/images/square_wave_gen_circuit.png';
  final String oscilloscopeIcon = 'assets/icons/icon_oscilloscope_white.png';
  final String logicAnalyzerIcon = 'assets/icons/icon_logic_analyzer_white.png';
  final List<List<dynamic>>? playbackData;
  const WaveGeneratorScreen({super.key, this.playbackData});

  @override
  State<StatefulWidget> createState() => _WaveGeneratorScreenState();
}

class _WaveGeneratorScreenState extends State<WaveGeneratorScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late WaveGeneratorStateProvider _provider;
  late WaveGeneratorConfigProvider? _configProvider;
  final CsvService _csvService = CsvService();
  bool _showGuide = false;

  @override
  void initState() {
    _provider = WaveGeneratorStateProvider();
    _configProvider = WaveGeneratorConfigProvider();
    _provider.setConfigProvider(_configProvider!);
    if (widget.playbackData != null) {
      _provider.loadPlaybackData(widget.playbackData!);
    }
    super.initState();
  }

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

  Future<void> _showSaveFileDialog(List<List<dynamic>> data) async {
    final TextEditingController filenameController = TextEditingController();
    final String defaultFilename =
        '${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv';
    filenameController.text = defaultFilename;

    final String? fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocalizations.saveRecording),
          content: TextField(
            controller: filenameController,
            decoration: InputDecoration(
              hintText: appLocalizations.enterFileName,
              labelText: appLocalizations.fileName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.cancel.toUpperCase()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, filenameController.text);
              },
              child: Text(appLocalizations.save),
            ),
          ],
        );
      },
    );

    if (fileName != null) {
      _csvService.writeMetaData(
          appLocalizations.waveGenerator.toLowerCase(), data);
      final file = await _csvService.saveCsvFile(
          appLocalizations.waveGenerator.toLowerCase(), fileName, data);
      if (mounted) {
        if (file != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${appLocalizations.fileSaved}: ${file.path.split('/').last}',
                style: TextStyle(color: snackBarContentColor),
              ),
              backgroundColor: snackBarBackgroundColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appLocalizations.failedToSave,
                style: TextStyle(color: snackBarContentColor),
              ),
              backgroundColor: snackBarBackgroundColor,
            ),
          );
        }
      }
    }
  }

  void _showOptionsMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        0,
        0,
        MediaQuery.of(context).size.height,
      ),
      items: [
        PopupMenuItem(
          value: 'show_guide',
          child: Text(appLocalizations.showGuide),
        ),
        PopupMenuItem(
          value: 'show_logged_data',
          child: Text(appLocalizations.showLoggedData),
        ),
        PopupMenuItem(
          value: 'wave_generator_config',
          child: Text(appLocalizations.waveGeneratorConfigs),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_guide':
            _showInstrumentGuide();
            break;
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'wave_generator_config':
            _navigateToConfig();
            break;
        }
      }
    });
  }

  void _navigateToConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangeNotifierProvider<WaveGeneratorConfigProvider>.value(
          value: _configProvider!,
          child: const WaveGeneratorConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.waveGenerator.toLowerCase()],
          appBarName: appLocalizations.waveGenerator,
          instrumentIcons: [instrumentIcons[4]],
        ),
      ),
    );
  }

  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WaveGeneratorStateProvider>(
          create: (_) => _provider,
        ),
      ],
      child: Consumer<WaveGeneratorStateProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              CommonScaffold(
                title: appLocalizations.waveGenerator,
                key: const Key(waveGeneratorScreenTitleKey),
                onOptionsPressed: _showOptionsMenu,
                body: SafeArea(
                  child: Container(
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
                ),
                actions: [
                  PopupMenuButton<String>(
                    color: primaryRed,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onSelected: (value) {
                      if (value == appLocalizations.oscilloscope) {
                        if (getIt.get<ScienceLab>().isConnected()) {
                          if (Navigator.canPop(context) &&
                              ModalRoute.of(context)?.settings.name ==
                                  '/oscilloscope') {
                            Navigator.popUntil(
                                context, ModalRoute.withName('/oscilloscope'));
                          } else {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/oscilloscope',
                              (route) => route.isFirst,
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                appLocalizations.notConnected,
                              ),
                            ),
                          );
                        }
                      } else {
                        if (getIt.get<ScienceLab>().isConnected()) {
                          if (Navigator.canPop(context) &&
                              ModalRoute.of(context)?.settings.name ==
                                  '/logicAnalyzer') {
                            Navigator.popUntil(
                                context, ModalRoute.withName('/logicAnalyzer'));
                          } else {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/logicAnalyzer',
                              (route) => route.isFirst,
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                appLocalizations.notConnected,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: appLocalizations.oscilloscope,
                        child: ListTile(
                          dense: true,
                          leading: Image.asset(
                            widget.oscilloscopeIcon,
                          ),
                          title: Text(
                            appLocalizations.oscilloscope,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: appLocalizations.logicAnalyzer,
                        child: ListTile(
                          dense: true,
                          leading: Image.asset(
                            widget.logicAnalyzerIcon,
                          ),
                          title: Text(
                            appLocalizations.logicAnalyzer,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.save, color: Colors.white),
                    onPressed: () async {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              appLocalizations.saving,
                              style: TextStyle(color: snackBarContentColor),
                            ),
                            backgroundColor: snackBarBackgroundColor,
                          ),
                        );
                      }
                      await _provider.logData();
                      final data = _provider.recordedData;
                      await _showSaveFileDialog(data);
                    },
                  ),
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
    );
  }
}
