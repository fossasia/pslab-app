import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/compass_config_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/compass_provider.dart';
import '../providers/compass_config_provider.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';
import '../constants.dart';

class CompassScreen extends StatelessWidget {
  final List<List<dynamic>>? playbackData;

  const CompassScreen({super.key, this.playbackData});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CompassProvider()),
        ChangeNotifierProvider(create: (_) => CompassConfigProvider()),
      ],
      child: CompassScreenContent(playbackData: playbackData),
    );
  }
}

class CompassScreenContent extends StatefulWidget {
  final List<List<dynamic>>? playbackData;

  const CompassScreenContent({super.key, this.playbackData});

  @override
  State<CompassScreenContent> createState() => _CompassScreenContentState();
}

class _CompassScreenContentState extends State<CompassScreenContent> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final CsvService _csvService = CsvService();

  late CompassProvider _provider;
  late CompassConfigProvider _configProvider;

  static const String compassIcon = 'assets/icons/compass_icon.png';
  bool _showGuide = false;
  static const String guideImagePath = 'assets/images/find_mobile_axis.png';

  @override
  void initState() {
    super.initState();
    _provider = context.read<CompassProvider>();
    _configProvider = context.read<CompassConfigProvider>();

    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.playbackData != null) {
          _provider.startPlayback(widget.playbackData!);
        } else {
          _provider.setConfigProvider(_configProvider);
          _provider.initializeSensors();
        }
      }
    });
  }

  @override
  void dispose() {
    _provider.disposeSensors();
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
          value: 'compass_config',
          child: Text('${appLocalizations.compassTitle} Config'),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'compass_config':
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
            ChangeNotifierProvider<CompassConfigProvider>.value(
          value: _configProvider,
          child: const CompassConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.compassTitle.toLowerCase()],
          appBarName: appLocalizations.compassTitle,
          instrumentIcons: [instrumentIcons[9]],
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
          appLocalizations.compassTitle.toLowerCase(), data);
      final file = await _csvService.saveCsvFile(
          appLocalizations.compassTitle.toLowerCase(), fileName, data);
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

  List<Widget> _getCompassContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.compassGuideBody,
      ),
      const InstrumentImage(
        imagePath: guideImagePath,
        height: 200.0,
      ),
      InstrumentIntroText(
        text: appLocalizations.compassGuideImageCaption,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompassProvider>(
      builder: (context, compassProvider, child) {
        return Stack(
          children: [
            CommonScaffold(
              title: compassProvider.isPlayingBack
                  ? '${appLocalizations.compassTitle} - ${appLocalizations.playback}'
                  : appLocalizations.compassTitle,
              onGuidePressed: _showInstrumentGuide,
              onOptionsPressed:
                  compassProvider.isPlayingBack ? null : _showOptionsMenu,
              onRecordPressed:
                  compassProvider.isPlayingBack ? null : _toggleRecording,
              isRecording: compassProvider.isRecording,
              isPlayingBack: compassProvider.isPlayingBack,
              isPlaybackPaused: compassProvider.isPlaybackPaused,
              onPlaybackPauseResume: compassProvider.isPlayingBack
                  ? (compassProvider.isPlaybackPaused
                      ? compassProvider.resumePlayback
                      : compassProvider.pausePlayback)
                  : null,
              onPlaybackStop: compassProvider.isPlayingBack
                  ? () async {
                      await compassProvider.stopPlayback();
                    }
                  : null,
              body: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Transform.rotate(
                            angle: compassProvider.currentDegree,
                            child: Container(
                              width: 300,
                              height: 300,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                compassIcon,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              compassProvider
                                  .getDegreeForAxis(
                                      compassProvider.selectedAxis)
                                  .toStringAsFixed(1),
                              style: TextStyle(
                                color: blackTextColor,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildAxisColumn(
                                    'Bx', compassProvider.magnetometerEvent.x),
                                _buildAxisColumn(
                                    'By', compassProvider.magnetometerEvent.y),
                                _buildAxisColumn(
                                    'Bz', compassProvider.magnetometerEvent.z),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              appLocalizations.parallelToGround,
                              style: TextStyle(
                                color: blackTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildAxisSelector(context, 'X', 'X axis'),
                                _buildAxisSelector(context, 'Y', 'Y axis'),
                                _buildAxisSelector(context, 'Z', 'Z axis'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            if (_showGuide)
              InstrumentOverviewDrawer(
                instrumentName: appLocalizations.compassGuideTitle,
                content: _getCompassContent(),
                onHide: _hideInstrumentGuide,
              ),
          ],
        );
      },
    );
  }

  Widget _buildAxisColumn(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: blackTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: blackTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAxisSelector(BuildContext context, String axis, String label) {
    return Consumer<CompassProvider>(
      builder: (context, compassProvider, child) {
        return Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup(
                groupValue: compassProvider.selectedAxis,
                onChanged: (String? value) {
                  if (value != null) {
                    compassProvider.onAxisSelected(value);
                  }
                },
                child: Radio<String>(
                  value: axis,
                  activeColor: radioButtonActiveColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: compassProvider.selectedAxis == axis
                      ? radioButtonActiveColor
                      : blackTextColor,
                  fontWeight: compassProvider.selectedAxis == axis
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
