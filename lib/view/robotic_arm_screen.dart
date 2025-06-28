import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/robotic_arm_timeline.dart';
import '../theme/colors.dart';
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
  }

  void _showAngleInputDialog(BuildContext context, int index) {
    double currentValue = provider.servoValues[index];
    final controller =
        TextEditingController(text: currentValue.round().toString());

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: angleDialog,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  void updateValue(double newVal) {
                    currentValue = newVal.clamp(0, 360);
                    controller.text = currentValue.round().toString();
                  }

                  return Container(
                    width: 240,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: primaryRed),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$setAngle ${index + 1}',
                            style: TextStyle(color: primaryRed)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove,
                                  size: 18, color: primaryRed),
                              onPressed: () {
                                updateValue(
                                    (double.tryParse(controller.text) ?? 0) -
                                        1);
                                setStateDialog(() {});
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final parsed = double.tryParse(val);
                                  if (parsed != null) {
                                    currentValue = parsed.clamp(0, 360);
                                    setStateDialog(() {});
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon:
                                  Icon(Icons.add, size: 18, color: primaryRed),
                              onPressed: () {
                                updateValue(
                                    (double.tryParse(controller.text) ?? 0) +
                                        1);
                                setStateDialog(() {});
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(cancel)),
                            TextButton(
                              onPressed: () {
                                final value = double.tryParse(controller.text);
                                if (value != null &&
                                    value >= 0 &&
                                    value <= 360) {
                                  setState(() {
                                    provider.updateServoValue(index, value);
                                  });
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(servoValidNumberRange)),
                                  );
                                }
                              },
                              child: Text(ok),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
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
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          final servoHeight = (screenHeight / 2.7);

          return CommonScaffold(
            title: roboticArm,
            actions: [
              IconButton(
                icon: Icon(
                  provider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                tooltip: play,
                onPressed: () {
                  setState(() {
                    provider.togglePlayPause();
                  });
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
                onPressed: () {}, //TODO controls
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
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: screenWidth * 5,
                          child: TimelineScrollView(
                            scrollController: provider.timelineScrollController,
                            timelinePosition: provider.timelinePosition,
                            scrollAmountPerTick: provider.scrollAmountPerTick,
                            timelineDegrees: provider.timelineDegrees,
                            onUpdate: (index, servo, value) {
                              setState(() {
                                provider.updateTimelineDegree(
                                    index, servo, value);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
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
