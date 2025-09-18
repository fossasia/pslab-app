import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/providers/accelerometer_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/accelerometer_card.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/view/logged_data_screen.dart';

import '../providers/accelerometer_config_provider.dart';
import '../theme/colors.dart';
import 'accelerometer_config_screen.dart';

class AccelerometerScreen extends StatefulWidget {
  const AccelerometerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AccelerometerScreenState();
}

class _AccelerometerScreenState extends State<AccelerometerScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _showGuide = false;
  static const imagePath = 'assets/images/bh1750_schematic.png';
  final CsvService _csvService = CsvService();
  late AccelerometerStateProvider _provider;
  late AccelerometerConfigProvider _configProvider;

  @override
  void initState() {
    super.initState();
    _provider = AccelerometerStateProvider();
    _configProvider = AccelerometerConfigProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider.setConfigProvider(_configProvider);
        _provider.initializeSensors();
      }
    });
  }

  @override
  void dispose() {
    _provider.disposeSensors();
    _provider.dispose();
    super.dispose();
  }

  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getAccelerometerContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.accelerometerIntro,
      ),
      const InstrumentImage(
        imagePath: imagePath,
      ),
      InstrumentIntroText(
        text: appLocalizations.accelerometerImageDesc,
      ),
      InstrumentIntroText(
        text: appLocalizations.accelerometerSteps,
      ),
      InstrumentBulletPoint(text: appLocalizations.accelerometerBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.accelerometerBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.accelerometerBulletPoint3),
      InstrumentIntroText(text: appLocalizations.accelerometerDesc),
      InstrumentIntroText(text: appLocalizations.accelerometerNote),
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
          value: 'accelerometer_config',
          child: Text(appLocalizations.accelerometerConfigurations),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'accelerometer_config':
            _navigateToConfig();
            break;
        }
      }
    });
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.accelerometer.toLowerCase()],
          appBarName: appLocalizations.accelerometer,
          instrumentIcons: [instrumentIcons[7]],
        ),
      ),
    );
  }

  void _navigateToConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => _configProvider,
          child: const AccelerometerConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_provider.isRecording) {
      final data = _provider.stopRecording();
      await _showSaveFileDialog(data);
    } else {
      await _provider.startRecording();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appLocalizations.recordingStarted}...',
            style: TextStyle(color: snackBarContentColor),
          ),
          backgroundColor: snackBarBackgroundColor,
        ),
      );
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
          appLocalizations.accelerometer.toLowerCase(), data);
      final file = await _csvService.saveCsvFile(
          appLocalizations.accelerometer.toLowerCase(), fileName, data);
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
    return ChangeNotifierProvider<AccelerometerStateProvider>.value(
      value: _provider,
      child: Stack(children: [
        Consumer<AccelerometerStateProvider>(
          builder: (context, provider, child) {
            return CommonScaffold(
              title: appLocalizations.accelerometerTitle,
              key: const Key(accelerometerScreenTitleKey),
              onGuidePressed: _showInstrumentGuide,
              onOptionsPressed: _showOptionsMenu,
              onRecordPressed: _toggleRecording,
              isRecording: provider.isRecording,
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: AccelerometerCard(
                          color: xOrientationChartLineColor,
                          axis: appLocalizations.xAxis),
                    ),
                    Expanded(
                      child: AccelerometerCard(
                          color: yOrientationChartLineColor,
                          axis: appLocalizations.yAxis),
                    ),
                    Expanded(
                      child: AccelerometerCard(
                          color: zOrientationChartLineColor,
                          axis: appLocalizations.zAxis),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_showGuide)
          InstrumentOverviewDrawer(
            instrumentName: appLocalizations.accelerometer,
            content: _getAccelerometerContent(),
            onHide: _hideInstrumentGuide,
          ),
      ]),
    );
  }
}
