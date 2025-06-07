import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pslab/colors.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/robotic_arm_timeline.dart';
import '../others/science_lab_common.dart';
import 'widgets/servo_card.dart';

class RoboticArmScreen extends StatefulWidget {
  const RoboticArmScreen({super.key});

  @override
  State<RoboticArmScreen> createState() => _RoboticArmScreenState();
}

class _RoboticArmScreenState extends State<RoboticArmScreen> {
  List<double> servoValues = [0, 0, 0, 0];
  ScrollController timelineScrollController = ScrollController();
  Timer? _debounceTimer;
  Timer? timelineTimer;
  int timelinePosition = 0;
  bool isPlaying = false;
  late ScienceLab scienceLab;
  final int totalTimelineItems = 60;
  final double scrollAmountPerTick = 120;
  List<List<double>> timelineDegrees =
      List.generate(60, (_) => List.filled(4, 0));
  int selectedServoIndex = 0;
  double selectedServoValue = 0.0;
  @override
  void initState() {
    super.initState();
    _setLandscapeOrientation();
    scienceLab =
        ScienceLabCommon(ScienceLabCommon.communicationHandler).getScienceLab();
    Future.microtask(() async {
      await scienceLab.connect();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _sendAllServoCommands(List<double> servoValues) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        await scienceLab.servo4(
          servoValues[0],
          servoValues[1],
          servoValues[2],
          servoValues[3],
        );
      } catch (e) {
        developer.log("Servo command failed", error: e, name: 'ServoControl');
      }
    });
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void togglePlayPause() {
    if (isPlaying) {
      timelineTimer?.cancel();
      setState(() {
        isPlaying = false;
      });
    } else {
      timelineTimer?.cancel();

      timelineTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (timelinePosition >= totalTimelineItems) {
          stopScrolling(resetPosition: false);
          return;
        }

        timelineScrollController.animateTo(
          timelineScrollController.offset + scrollAmountPerTick,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeInOut,
        );

        List<double> currentAngles = timelineDegrees[timelinePosition];

        if (scienceLab.isConnected()) {
          try {
            await scienceLab.servo4(
              currentAngles[0],
              currentAngles[1],
              currentAngles[2],
              currentAngles[3],
            );
          } catch (e) {
            developer.log("Servo timeline failed",
                error: e, name: 'ServoControl');
          }
        }

        setState(() {
          timelinePosition++;
        });
      });

      setState(() {
        isPlaying = true;
      });
    }
  }

  void stopScrolling({bool resetPosition = true}) {
    timelineTimer?.cancel();
    setState(() {
      isPlaying = false;
      timelinePosition = 0;
    });
    if (resetPosition) {
      timelineScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
      );
    }
  }

  void _showAngleInputDialog(int index) {
    double currentValue = servoValues[index];
    final controller =
        TextEditingController(text: currentValue.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void updateValue(double newValue) {
              if (newValue < 0) newValue = 0;
              if (newValue > 360) newValue = 360;
              currentValue = newValue;
              controller.text = currentValue.toStringAsFixed(0);
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }

            return AlertDialog(
              title: Text('$setAngle${index + 1}'),
              content: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      setStateDialog(() {
                        updateValue(currentValue - 1);
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: enterAngleRange,
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed >= 0 && parsed <= 360) {
                          setStateDialog(() {
                            currentValue = parsed;
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setStateDialog(() {
                        updateValue(currentValue + 1);
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    final value = double.tryParse(text);

                    if (text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorCannotBeEmpty)),
                      );
                      return;
                    }

                    if (value == null || value < 0 || value > 360) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(servoValidNumberRange)),
                      );
                      return;
                    }

                    setState(() {
                      servoValues[index] = value;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(ok),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(cancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final servoWidth = (screenWidth / 4) - 7;
    final servoHeight = (screenHeight / 2.9);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          roboticArm,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryRed,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            tooltip: play,
            onPressed: togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: stop,
            onPressed: () {
              stopScrolling(resetPosition: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune), // TODO: Controls
            tooltip: controls,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: saveData,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: showGuide,
            onPressed: () {}, // TODO:
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == showLoggedDataKey) {} // TODO:
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: showLoggedDataKey,
                child: Text(showLoggedData),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: servoHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: servoWidth,
                    height: servoHeight,
                    child: ServoCard(
                      value: servoValues[index],
                      label: servoLabels[index],
                      servoId: index,
                      onChanged: (val) {
                        setState(() => servoValues[index] = val);
                        _sendAllServoCommands(servoValues);
                      },
                      onTap: () => _showAngleInputDialog(index),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: screenWidth * 5,
              child: TimelineScrollView(
                scrollController: timelineScrollController,
                timelinePosition: timelinePosition,
                scrollAmountPerTick: scrollAmountPerTick,
                timelineDegrees: timelineDegrees,
                onUpdate: (index, servo, value) {
                  setState(() {
                    timelineDegrees[index][servo] = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
