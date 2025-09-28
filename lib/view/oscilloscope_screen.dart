import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/oscilloscope_config_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/oscilloscope_config_screen.dart';
import 'package:pslab/view/widgets/channel_parameters_widget.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/data_analysis_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/measurements_list.dart';
import 'package:pslab/view/widgets/oscilloscope_graph.dart';
import 'package:pslab/view/widgets/oscilloscope_screen_tabs.dart';
import 'package:pslab/view/widgets/timebase_trigger_widget.dart';
import 'package:pslab/view/widgets/xyplot_widget.dart';

import '../providers/oscilloscope_state_provider.dart';

class OscilloscopeScreen extends StatefulWidget {
  final String icRecord = 'assets/icons/ic_record_white.png';
  final String oscilloscopeSchematic =
      'assets/images/oscilloscope_schematic.png';
  final String micSchematic = 'assets/images/mic_schematic.png';
  final String timebaseView = 'assets/images/timebase_view.png';
  final String dataAnalysisView = 'assets/images/data_analysis_view.png';
  final String xyPlotView = 'assets/images/xy_plot_view.png';
  final List<List<dynamic>>? playbackData;
  const OscilloscopeScreen({super.key, this.playbackData});

  @override
  State<StatefulWidget> createState() => _OscilloscopeScreenState();
}

class _OscilloscopeScreenState extends State<OscilloscopeScreen> {
  late OscilloscopeStateProvider _provider;
  late OscilloscopeConfigProvider? _configProvider;
  final CsvService _csvService = CsvService();
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _showGuide = false;
  @override
  void initState() {
    _provider = OscilloscopeStateProvider();
    _configProvider = OscilloscopeConfigProvider();
    _provider.setConfigProvider(_configProvider!);

    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (widget.playbackData != null) {
        _provider.startPlayback(widget.playbackData!);
      }
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _setLandscapeOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    super.didChangeDependencies();
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
          value: 'oscilloscope_config',
          child: Text(appLocalizations.oscilloscopeConfigs),
        ),
        PopupMenuItem<CheckboxListTile>(
          child: CheckboxListTile(
            title: Text(appLocalizations.automatedMeasurements),
            secondary: IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(appLocalizations.automatedMeasurements),
                        content:
                            Text(appLocalizations.automatedMeasurementsInfo),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(appLocalizations.ok),
                          ),
                        ],
                      );
                    },
                  );
                }),
            value: _provider.isMeasurementsChecked,
            onChanged: (bool? newValue) {
              setState(() {
                _provider.isMeasurementsChecked = newValue ?? false;
              });
              Navigator.pop(context);
            },
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'oscilloscope_config':
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
            ChangeNotifierProvider<OscilloscopeConfigProvider>.value(
          value: _configProvider!,
          child: const OscilloscopeConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.oscilloscope.toLowerCase()],
          appBarName: appLocalizations.oscilloscope,
          instrumentIcons: [instrumentIcons[0]],
        ),
      ),
    );
  }

  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
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

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getOscilloscopeContent() {
    return [
      InstrumentBulletPoint(text: appLocalizations.oscilloscopeBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.oscilloscopeBulletPoint2),
      InstrumentImage(imagePath: widget.oscilloscopeSchematic),
      InstrumentBulletPoint(text: appLocalizations.oscilloscopeBulletPoint3),
      InstrumentBulletPoint(text: appLocalizations.oscilloscopeBulletPoint4),
      InstrumentHeading(text: appLocalizations.channelParameters),
      InstrumentIntroText(text: appLocalizations.channelParametersIntro),
      InstrumentBulletPoint(
          text: appLocalizations.channelParametersBulletPoint1),
      InstrumentBulletPoint(
          text: appLocalizations.channelParametersBulletPoint2),
      InstrumentBulletPoint(
          text: appLocalizations.channelParametersBulletPoint3),
      InstrumentImage(imagePath: widget.micSchematic),
      InstrumentBulletPoint(
          text: appLocalizations.channelParametersBulletPoint4),
      InstrumentHeading(text: appLocalizations.timeBaseAndTrigger),
      InstrumentIntroText(text: appLocalizations.timebaseIntro),
      InstrumentBulletPoint(text: appLocalizations.timebaseBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.timebaseBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.timebaseBulletPoint3),
      InstrumentImage(imagePath: widget.timebaseView),
      InstrumentHeading(text: appLocalizations.dataAnalysis),
      InstrumentBulletPoint(text: appLocalizations.dataAnalysisBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.dataAnalysisBulletPoint2),
      InstrumentImage(imagePath: widget.dataAnalysisView),
      InstrumentHeading(text: appLocalizations.xyPlot),
      InstrumentBulletPoint(text: appLocalizations.xyPlotBulletPoint1),
      InstrumentImage(imagePath: widget.xyPlotView),
    ];
  }

  @override
  void dispose() {
    _setPortraitOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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
          appLocalizations.oscilloscope.toLowerCase(), data);
      final file = await _csvService.saveCsvFile(
          appLocalizations.oscilloscope.toLowerCase(), fileName, data);
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
        ChangeNotifierProvider<OscilloscopeStateProvider>(
          create: (_) => _provider,
        ),
      ],
      child: Consumer<OscilloscopeStateProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              CommonScaffold(
                title: appLocalizations.oscilloscope,
                key: const Key(oscilloscopeScreenTitleKey),
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
                  minimum: const EdgeInsets.only(right: 0, bottom: 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        margin: const EdgeInsets.only(left: 5, top: 5),
                        child: widget.playbackData != null
                            ? Container(
                                margin:
                                    const EdgeInsets.only(right: 5, bottom: 5),
                                padding: const EdgeInsets.only(bottom: 20),
                                color: Colors.black,
                                child: OscilloscopeGraph(),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    flex: 89,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 5),
                                      child: Stack(
                                        children: [
                                          Column(
                                            children: [
                                              Expanded(
                                                flex:
                                                    constraints.maxHeight < 600
                                                        ? 68
                                                        : 80,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 20),
                                                  color: Colors.black,
                                                  child:
                                                      const OscilloscopeGraph(),
                                                ),
                                              ),
                                              Expanded(
                                                flex:
                                                    constraints.maxHeight < 600
                                                        ? 32
                                                        : 20,
                                                child: Selector<
                                                    OscilloscopeStateProvider,
                                                    int>(
                                                  selector: (context,
                                                          provider) =>
                                                      provider.selectedIndex,
                                                  builder: (context,
                                                      selectedIndex, _) {
                                                    switch (selectedIndex) {
                                                      case 0:
                                                        return const ChannelParametersWidget();
                                                      case 1:
                                                        return const TimebaseTriggerWidget();
                                                      case 2:
                                                        return const DataAnalysisWidget();
                                                      case 3:
                                                        return const XYPlotWidget();
                                                      default:
                                                        return const ChannelParametersWidget();
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          provider.isMeasurementsChecked
                                              ? Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: SizedBox(
                                                      width: 135,
                                                      child: MeasurementsList(
                                                          dataParamsChannels:
                                                              provider
                                                                  .dataParamsChannels)),
                                                )
                                              : const SizedBox.shrink(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 11,
                                    child: OscilloscopeScreenTabs(),
                                  )
                                ],
                              ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if ((((provider.isCH1Selected ||
                                      provider.isCH2Selected ||
                                      provider.isCH3Selected ||
                                      provider.isMICSelected) &&
                                  getIt<ScienceLab>().isConnected()) ||
                              provider.isInBuiltMICSelected) &&
                          !provider.autoScale()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(appLocalizations.noSignal),
                          ),
                        );
                      }
                    },
                    child: Text(appLocalizations.autoScale,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  widget.playbackData == null
                      ? IconButton(
                          icon: provider.isRunning
                              ? const Icon(
                                  Icons.pause,
                                  color: Colors.white,
                                )
                              : const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                          onPressed: () {
                            if (provider.isRunning) {
                              provider.isRunning = false;
                            } else {
                              provider.isRunning = true;
                            }
                            setState(
                              () {},
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.oscilloscope,
                  content: _getOscilloscopeContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }
}
