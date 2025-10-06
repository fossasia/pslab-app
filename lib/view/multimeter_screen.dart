import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/multimeter_config_provider.dart';
import 'package:pslab/providers/multimeter_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/multimeter_config_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/multimeter_knob.dart';

class MultimeterScreen extends StatefulWidget {
  final String icRecord = 'assets/icons/ic_record_white.png';
  final multimeterCircuit = 'assets/images/multimeter_circuit.png';
  final List<List<dynamic>>? playbackData;
  const MultimeterScreen({super.key, this.playbackData});

  @override
  State<StatefulWidget> createState() => _MultimeterScreenState();
}

class _MultimeterScreenState extends State<MultimeterScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late MultimeterStateProvider _provider;
  late MultimeterConfigProvider? _configProvider;
  final CsvService _csvService = CsvService();
  bool _showGuide = false;

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  @override
  void initState() {
    _provider = MultimeterStateProvider();
    _configProvider = MultimeterConfigProvider();
    _provider.setConfigProvider(_configProvider!);

    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.playbackData != null) {
        _provider.startPlayback(widget.playbackData!);
      } else {
        _provider.logData();
      }
    });
    super.initState();
  }

  List<Widget> _getMultimeterContent() {
    return [
      InstrumentImage(imagePath: widget.multimeterCircuit),
    ];
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
          value: 'show_logged_data',
          child: Text(appLocalizations.showLoggedData),
        ),
        PopupMenuItem(
          value: 'multimeter_config',
          child: Text(appLocalizations.multimeterConfigs),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'multimeter_config':
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
            ChangeNotifierProvider<MultimeterConfigProvider>.value(
          value: _configProvider!,
          child: const MultimeterConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.multimeter.toLowerCase()],
          appBarName: appLocalizations.multimeter,
          instrumentIcons: [instrumentIcons[1]],
        ),
      ),
    );
  }

  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
  }

  Future<void> _toggleRecording() async {
    if (_provider.isRecording) {
      final data = _provider.stopRecording();
      await _showSaveFileDialog(data);
    } else {
      bool hasStarted = await _provider.startRecording();
      if (!mounted) return;
      if (hasStarted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appLocalizations.recordingStarted}...',
              style: TextStyle(color: snackBarContentColor),
            ),
            backgroundColor: snackBarBackgroundColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appLocalizations.notConnected,
              style: TextStyle(color: snackBarContentColor),
            ),
            backgroundColor: snackBarBackgroundColor,
          ),
        );
      }
    }
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
          appLocalizations.multimeter.toLowerCase(), data);
      final file = await _csvService.saveCsvFile(
          appLocalizations.multimeter.toLowerCase(), fileName, data);
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => _provider,
        ),
      ],
      child: Consumer<MultimeterStateProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              CommonScaffold(
                title: provider.isPlayingBack
                    ? '${appLocalizations.multimeterTitle} - ${appLocalizations.playback}'
                    : appLocalizations.multimeterTitle,
                key: const Key(multimeterScreenTitleKey),
                onOptionsPressed:
                    provider.isPlayingBack ? null : _showOptionsMenu,
                onGuidePressed: _showInstrumentGuide,
                onRecordPressed:
                    provider.isPlayingBack ? null : _toggleRecording,
                isRecording: provider.isRecording,
                isPlayingBack: provider.isPlayingBack,
                isPlaybackPaused: provider.isPlaybackPaused,
                onPlaybackPauseResume: provider.isPlayingBack
                    ? (provider.isPlaybackPaused
                        ? _provider.resumePlayback
                        : _provider.pausePlayback)
                    : null,
                onPlaybackStop: provider.isPlayingBack
                    ? () async {
                        await _provider.stopPlayback();
                      }
                    : null,
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          Expanded(
                            flex: 23,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    width: 1, color: multimeterBorderLightRed),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 75,
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                          right: 10, bottom: 10),
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        provider.value,
                                        style: TextStyle(
                                          fontSize: 50,
                                          fontStyle: FontStyle.italic,
                                          fontFamily: 'Digital-7',
                                          color: multimeterBorderBlack,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    color: multimeterDividerColor,
                                  ),
                                  Expanded(
                                    flex: 25,
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        provider.unit,
                                        style: TextStyle(
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 77,
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    Expanded(
                                      flex: 47,
                                      child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          border: Border.all(
                                              width: 3,
                                              color: multimeterBorderRed),
                                        ),
                                        child: Text(appLocalizations.voltage,
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: multimeterBorderRed,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 53,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: constraints.maxWidth < 600
                                                ? 67
                                                : (constraints.maxWidth >
                                                        constraints.maxHeight
                                                    ? 56
                                                    : 63),
                                            child: Container(
                                              height: double.infinity,
                                              margin: const EdgeInsets.only(
                                                  top: 5,
                                                  left: 10,
                                                  right: 2,
                                                  bottom: 10),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                border: Border.all(
                                                    width: 3,
                                                    color: Colors.black),
                                              ),
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      appLocalizations.unitHz,
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          color:
                                                              multimeterBorderBlack,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    Transform.scale(
                                                      scale: 0.75,
                                                      child: Switch(
                                                        activeThumbColor:
                                                            multimeterBorderBlack,
                                                        value: provider
                                                            .isSwitchChecked,
                                                        onChanged:
                                                            (bool value) {},
                                                      ),
                                                    ),
                                                    Text(
                                                      appLocalizations
                                                          .countPulse,
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          color:
                                                              multimeterBorderBlack,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: constraints.maxWidth < 600
                                                ? 33
                                                : (constraints.maxWidth >
                                                        constraints.maxHeight
                                                    ? 44
                                                    : 37),
                                            child: Container(
                                              height: double.infinity,
                                              margin: const EdgeInsets.only(
                                                  top: 5,
                                                  left: 2,
                                                  right: 10,
                                                  bottom: 10),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                border: Border.all(
                                                    width: 3,
                                                    color:
                                                        multimeterBorderBlack),
                                              ),
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: Text(
                                                    appLocalizations.measure,
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        color:
                                                            multimeterBorderBlack,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    textAlign:
                                                        TextAlign.center),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: MultimeterKnob(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.multimeter,
                  content: _getMultimeterContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }
}
