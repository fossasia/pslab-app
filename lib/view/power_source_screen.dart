import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/power_source_config_provider.dart';
import 'package:pslab/providers/power_source_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/power_source_config_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/power_source_knob.dart';

class PowerSourceScreen extends StatefulWidget {
  final String icRecord = 'assets/icons/ic_record_white.png';
  final String powerSourceCircuit = 'assets/images/powersource_circuit.png';
  final List<List<dynamic>>? playbackData;
  const PowerSourceScreen({super.key, this.playbackData});

  @override
  State<StatefulWidget> createState() => _PowerSourceScreenState();
}

class _PowerSourceScreenState extends State<PowerSourceScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late PowerSourceStateProvider _provider;
  late PowerSourceConfigProvider? _configProvider;
  final CsvService _csvService = CsvService();
  bool _showGuide = false;

  @override
  void initState() {
    _provider = PowerSourceStateProvider();
    _configProvider = PowerSourceConfigProvider();
    _provider.setConfigProvider(_configProvider!);

    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.playbackData != null) {
        _provider.startPlayback(widget.playbackData!);
      }
    });
    super.initState();
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getPowerSourceContent() {
    return [
      InstrumentIntroText(text: appLocalizations.powerSourceIntro),
      InstrumentImage(imagePath: widget.powerSourceCircuit),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint3),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint4),
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
          value: 'power_source_config',
          child: Text(appLocalizations.powerSourceConfigs),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'power_source_config':
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
            ChangeNotifierProvider<PowerSourceConfigProvider>.value(
          value: _configProvider!,
          child: const PowerSourceConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.powerSource.toLowerCase()],
          appBarName: appLocalizations.powerSource,
          instrumentIcons: [instrumentIcons[5]],
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
          appLocalizations.powerSource.toLowerCase(), data);
      final file = await _csvService.saveCsvFile(
          appLocalizations.powerSource.toLowerCase(), fileName, data);
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
        ChangeNotifierProvider(create: (_) => _provider),
      ],
      child: Consumer<PowerSourceStateProvider>(
        builder: (context, provider, _) {
          final powerSourceCards = [
            Card(
              color: scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            appLocalizations.pinPV1,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: TextEditingController(
                              text:
                                  '${provider.voltagePV1.toStringAsFixed(2)} V',
                            ),
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                            onSubmitted: (value) async {
                              String powerValue =
                                  value.replaceAll("V", "").trim();
                              double parsedValue =
                                  double.tryParse(powerValue) ?? 0.0;
                              await provider.setPV1(parsedValue);
                            },
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_up),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV1(
                                          provider.voltagePV1 + provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_down),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV1(
                                          provider.voltagePV1 - provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
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
                  Expanded(
                    flex: 55,
                    child: PowerSourceKnob(
                      maxValue: 1000,
                      pin: Pin.pv1,
                    ),
                  )
                ],
              ),
            ),
            Card(
              color: scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            appLocalizations.pinPV2,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: TextEditingController(
                              text:
                                  '${provider.voltagePV2.toStringAsFixed(2)} V',
                            ),
                            textAlign: TextAlign.center,
                            onSubmitted: (value) async {
                              String powerValue =
                                  value.replaceAll("V", "").trim();
                              double parsedValue =
                                  double.tryParse(powerValue) ?? 0.0;
                              await provider.setPV2(parsedValue);
                            },
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_up),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV2(
                                          provider.voltagePV2 + provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_down),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV2(
                                          provider.voltagePV2 - provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
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
                  Expanded(
                    flex: 55,
                    child: PowerSourceKnob(
                      maxValue: 660,
                      pin: Pin.pv2,
                    ),
                  )
                ],
              ),
            ),
            Card(
              color: scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            appLocalizations.pinPV3,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: TextEditingController(
                              text:
                                  '${provider.voltagePV3.toStringAsFixed(2)} V',
                            ),
                            textAlign: TextAlign.center,
                            onSubmitted: (value) async {
                              String powerValue =
                                  value.replaceAll("V", "").trim();
                              double parsedValue =
                                  double.tryParse(powerValue) ?? 0.0;
                              await provider.setPV3(parsedValue);
                            },
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_up),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV3(
                                          provider.voltagePV3 + provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_down),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV3(
                                          provider.voltagePV3 - provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
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
                  Expanded(
                    flex: 55,
                    child: PowerSourceKnob(
                      maxValue: 330,
                      pin: Pin.pv3,
                    ),
                  )
                ],
              ),
            ),
            Card(
              color: scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            appLocalizations.pinPCS,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: TextEditingController(
                              text:
                                  '${provider.currentPCS.toStringAsFixed(2)} mA',
                            ),
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                            onSubmitted: (value) async {
                              String powerValue =
                                  value.replaceAll("V", "").trim();
                              double parsedValue =
                                  double.tryParse(powerValue) ?? 0.0;
                              await provider.setPCS(parsedValue);
                            },
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_up),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPCS(
                                          provider.currentPCS + provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_down),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPCS(
                                          provider.currentPCS - provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
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
                  Expanded(
                    flex: 55,
                    child: PowerSourceKnob(
                      maxValue: 330,
                      pin: Pin.pcs,
                    ),
                  )
                ],
              ),
            ),
          ];
          return Stack(
            children: [
              CommonScaffold(
                title: appLocalizations.powerSourceTitle,
                key: const Key(powerSourceScreenTitleKey),
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
                body: ScrollConfiguration(
                  behavior: ScrollBehavior(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return constraints.maxWidth < 600
                          ? ListView(
                              children: powerSourceCards,
                            )
                          : GridView(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.5,
                              ),
                              children: powerSourceCards,
                            );
                    },
                  ),
                ),
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.powerSource,
                  content: _getPowerSourceContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }
}
