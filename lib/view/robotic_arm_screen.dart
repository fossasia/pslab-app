import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/robotic_arm_controls.dart';
import 'package:pslab/view/widgets/robotic_arm_dialog.dart';
import 'package:pslab/view/widgets/robotic_arm_summary.dart';
import 'package:pslab/view/widgets/robotic_arm_timeline.dart';
import '../providers/robotic_arm_state_provider.dart';
import 'logged_data_screen.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'widgets/servo_card.dart';

class RoboticArmScreen extends StatefulWidget {
  const RoboticArmScreen({super.key});

  @override
  State<RoboticArmScreen> createState() => _RoboticArmScreenState();
}

class _RoboticArmScreenState extends State<RoboticArmScreen> {
  late RoboticArmStateProvider provider;
  late List<String> servoLabels;
  bool _showGuide = false;
  static const imagePath = 'assets/images/robotic_arm_guide.png';
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  @override
  void initState() {
    super.initState();
    servoLabels = [
      appLocalizations.servo1,
      appLocalizations.servo2,
      appLocalizations.servo3,
      appLocalizations.servo4,
    ];
    provider = RoboticArmStateProvider();
    provider.initialize();

    provider.onPlaybackEnd = () {
      showDialog(
        context: context,
        builder: (_) => PlaybackSummaryDialog(
          frequency: int.parse(provider.selectedFrequency
              .replaceAll(appLocalizations.hzSuffix, '')),
          maxAngle: provider.maxAngle,
          getSummary: provider.generateSummary,
        ),
      );
    };
  }

  @override
  void dispose() {
    provider.disposeResources();
    super.dispose();
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getRoboticArmContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.roboticArmIntro,
      ),
      const InstrumentImage(
        imagePath: imagePath,
      ),
      InstrumentIntroText(
        text: appLocalizations.roboticArmConnection,
      ),
    ];
  }

  void _showAngleInputDialog(BuildContext context, int index) {
    final currentValue = provider.servoValues[index];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: appLocalizations.angleDialog,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) {
        return SafeArea(
          child: AngleInputTopDialog(
            index: index,
            initialValue: currentValue,
            onValueConfirmed: (newVal) {
              provider.updateServoValue(index, newVal);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RoboticArmStateProvider>.value(
          value: provider,
        ),
      ],
      child: Consumer<RoboticArmStateProvider>(
        builder: (context, provider, _) {
          final screenHeight = MediaQuery.of(context).size.height;
          final servoHeight = (screenHeight / 2.5);
          final screenWidth = MediaQuery.of(context).size.width;
          final scrollAmount = (screenWidth / 6);
          return CommonScaffold(
            title: appLocalizations.roboticArmTitle,
            actions: [
              IconButton(
                icon: Icon(
                  provider.manualEnabled
                      ? Icons.play_arrow
                      : provider.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                  color: Colors.white,
                ),
                tooltip: provider.manualEnabled
                    ? appLocalizations.manualMode
                    : provider.isPlaying
                        ? appLocalizations.pause
                        : appLocalizations.play,
                onPressed: () {
                  if (!provider.manualEnabled) {
                    setState(() {
                      provider.togglePlayPause(
                          scrollAmountPerTick: scrollAmount);
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white),
                tooltip: appLocalizations.stop,
                onPressed: () {
                  setState(() {
                    provider.stopScrolling(resetPosition: true);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: appLocalizations.controls,
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return ChangeNotifierProvider<
                          RoboticArmStateProvider>.value(
                        value: provider,
                        child: Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: EdgeInsets.zero,
                          child: SafeArea(
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(color: Colors.transparent),
                                  ),
                                ),
                                SizedBox(
                                  width: 300,
                                  child: RoboticArmControls(
                                    onClose: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                tooltip: appLocalizations.saveData,
                onPressed: () async {
                  final TextEditingController fileNameController =
                      TextEditingController();

                  final String? enteredFileName = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return Dialog(
                        insetPadding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.all(8),
                            width: 220,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  appLocalizations.enterFileName,
                                  style: TextStyle(fontSize: 9),
                                ),
                                const SizedBox(height: 2),
                                TextField(
                                  controller: fileNameController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 6),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 26,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(null),
                                        child: Text(appLocalizations.cancel,
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.black)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      height: 26,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop(
                                              fileNameController.text.trim());
                                        },
                                        child: Text(appLocalizations.save,
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.black)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );

                  try {
                    await provider.exportTimelineToCsv(
                      instrumentName: appLocalizations.roboticArmTitle,
                      fileName: (enteredFileName!),
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.fileSaved)),
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.csvSavingError)),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.info, color: Colors.white),
                tooltip: appLocalizations.showGuide,
                onPressed: () {
                  setState(() {
                    _showGuide = !_showGuide;
                  });
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == appLocalizations.showLoggedData) {
                    final List<List<dynamic>>? data = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoggedDataScreen(
                          instrumentName: appLocalizations.roboticArmTitle,
                          appBarName: appLocalizations.showLoggedData,
                          instrumentIcon: 'assets/icons/robotic_arm.png',
                        ),
                      ),
                    );

                    if (data != null) {
                      setState(() {
                        provider.importTimelineFromCsv(data);
                      });
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: appLocalizations.showLoggedData,
                    child: Text(appLocalizations.showLoggedData),
                  ),
                ],
              ),
            ],
            body: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: servoHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(4, (index) {
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  child: SizedBox(
                                    height: servoHeight,
                                    child: ServoCard(
                                      value: provider.servoValues[index],
                                      label: servoLabels[index],
                                      servoId: index,
                                      onChanged: (val) {
                                        setState(() {
                                          provider.updateServoValue(index, val);
                                        });
                                      },
                                      onTap: () =>
                                          _showAngleInputDialog(context, index),
                                      cardHeight: servoHeight,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Scrollbar(
                            controller: provider.timelineScrollController,
                            thumbVisibility: true,
                            thickness: screenHeight * 0.006,
                            radius: const Radius.circular(4),
                            child: TimelineScrollView(
                              totalTimelineItems: provider.totalTimelineItems,
                              screenHeight: screenHeight,
                              timelinePosition: provider.timelinePosition,
                              timelineDegrees: provider.timelineDegrees,
                              scrollController:
                                  provider.timelineScrollController,
                              onUpdate: (index, servo, value) {
                                setState(() {
                                  provider.updateTimelineDegree(
                                      index, servo, value);
                                });
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                if (_showGuide)
                  InstrumentOverviewDrawer(
                    instrumentName: appLocalizations.roboticArmTitle,
                    content: _getRoboticArmContent(),
                    onHide: _hideInstrumentGuide,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
