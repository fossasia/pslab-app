import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/providers/logic_analyzer_config_provider.dart';
import 'package:pslab/providers/logic_analyzer_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/logic_analyzer_config_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/logic_analyzer_channel_selection.dart';
import 'package:pslab/view/widgets/logic_analyzer_graph.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

class LogicAnalyzerScreen extends StatefulWidget {
  const LogicAnalyzerScreen({super.key, this.playbackData});
  final List<List<dynamic>>? playbackData;
  final logicAnalyzerCircuit = 'assets/images/logic_analyzer_circuit.png';

  @override
  State<StatefulWidget> createState() => _LogicAnalyzerScreenState();
}

class _LogicAnalyzerScreenState extends State<LogicAnalyzerScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late LogicAnalyzerStateProvider _provider;
  late LogicAnalyzerConfigProvider? _configProvider;
  final CsvService _csvService = CsvService();
  bool _showGuide = false;

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getLogicAnalyzerContent() {
    return [
      InstrumentIntroText(text: appLocalizations.logicAnalyzerIntro),
      InstrumentImage(imagePath: widget.logicAnalyzerCircuit),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerWaveGenCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint3,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint4,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint5,
      ),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerConnectionCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerConnectionBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerConnectionBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerConnectionBulletPoint3,
      ),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerUsageCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint3,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint4,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint5,
      ),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerEdgeCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerEdgeBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerEdgeBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerEdgeBulletPoint3,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerEdgeBulletPoint4,
      ),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerMeasurementCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerMeasurementBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerMeasurementBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerMeasurementBulletPoint3,
      ),
    ];
  }

  @override
  void initState() {
    _provider = LogicAnalyzerStateProvider();
    _configProvider = LogicAnalyzerConfigProvider();
    _provider.setConfigProvider(_configProvider!);
    if (widget.playbackData != null) {
      _provider.loadPlaybackData(widget.playbackData!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
    super.initState();
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _setPortraitOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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
        appLocalizations.logicAnalyzer.toLowerCase(),
        data,
      );
      final file = await _csvService.saveCsvFile(
        appLocalizations.logicAnalyzer.toLowerCase(),
        fileName,
        data,
      );
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
          value: 'show_logged_data',
          child: Text(appLocalizations.showLoggedData),
        ),
        PopupMenuItem(
          value: 'logic_analyzer_config',
          child: Text(appLocalizations.logicAnalyzerConfigs),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'logic_analyzer_config':
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
            ChangeNotifierProvider<LogicAnalyzerConfigProvider>.value(
              value: _configProvider!,
              child: const LogicAnalyzerConfigScreen(),
            ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.logicAnalyzer.toLowerCase()],
          appBarName: appLocalizations.logicAnalyzer,
          instrumentIcons: [instrumentIcons[2]],
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
      providers: [ChangeNotifierProvider(create: (context) => _provider)],
      child: Consumer<LogicAnalyzerStateProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              CommonScaffold(
                title: appLocalizations.logicAnalyzerTitle,
                onOptionsPressed: _showOptionsMenu,
                onGuidePressed: _showInstrumentGuide,
                body: SafeArea(
                  minimum: const EdgeInsets.only(right: 0, bottom: 0),
                  child: Container(
                    decoration: BoxDecoration(color: chartBackgroundColor),
                    padding: const EdgeInsets.only(bottom: 5, top: 5),
                    child: Row(
                      children: [
                        Expanded(flex: 73, child: LogicAnalyzerGraph()),
                        Expanded(
                          flex: 27,
                          child: LogicAnalyzerChannelSelection(),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.save, color: Colors.white),
                    onPressed: () async {
                      if (!getIt.get<ScienceLab>().isConnected()) {
                        if (context.mounted) {
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
                        return;
                      }
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
                  instrumentName: appLocalizations.logicAnalyzer,
                  content: _getLogicAnalyzerContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }
}
