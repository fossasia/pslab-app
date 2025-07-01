import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/robotic_arm_controls.dart';
import 'package:pslab/view/widgets/robotic_arm_dialog.dart';
import 'package:pslab/view/widgets/robotic_arm_summary.dart';
import 'package:pslab/view/widgets/robotic_arm_timeline.dart';
import '../providers/robotic_arm_state_provider.dart';
import 'widgets/servo_card.dart';

class RoboticArmScreen extends StatefulWidget {
  const RoboticArmScreen({super.key});

  @override
  State<RoboticArmScreen> createState() => _RoboticArmScreenState();
}

class _RoboticArmScreenState extends State<RoboticArmScreen> {
  late RoboticArmStateProvider provider;

  @override
  void initState() {
    super.initState();
    provider = RoboticArmStateProvider();
    provider.initialize();

    provider.onPlaybackEnd = () {
      showDialog(
        context: context,
        builder: (_) => PlaybackSummaryDialog(
          frequency:
              int.parse(provider.selectedFrequency.replaceAll(hzSuffix, '')),
          maxAngle: provider.maxAngle,
          getSummary: provider.generateSummary,
        ),
      );
    };
  }

  void _showAngleInputDialog(BuildContext context, int index) {
    final currentValue = provider.servoValues[index];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: angleDialog,
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
            title: roboticArm,
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
                    ? manualMode
                    : provider.isPlaying
                        ? pause
                        : play,
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
                tooltip: stop,
                onPressed: () {
                  setState(() {
                    provider.stopScrolling(resetPosition: true);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: controls,
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
                tooltip: saveData,
                onPressed: () {}, //TODO
              ),
              IconButton(
                icon: const Icon(Icons.info, color: Colors.white),
                tooltip: showGuide,
                onPressed: () {}, //TODO
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == showLoggedDataKey) {
                    // TODO
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: showLoggedDataKey,
                    child: Text(showLoggedData),
                  ),
                ],
              ),
            ],
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                                  const EdgeInsets.symmetric(horizontal: 4),
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
                    const SizedBox(height: 3),
                    Expanded(
                      child: Scrollbar(
                        controller: provider.timelineScrollController,
                        thumbVisibility: true,
                        thickness: 8,
                        radius: const Radius.circular(4),
                        child: TimelineScrollView(
                          totalTimelineItems: provider.totalTimelineItems,
                          screenHeight: screenHeight,
                          timelinePosition: provider.timelinePosition,
                          timelineDegrees: provider.timelineDegrees,
                          scrollController: provider.timelineScrollController,
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
          );
        },
      ),
    );
  }
}
