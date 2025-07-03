import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/theme/colors.dart';

import '../../constants.dart';
import '../../providers/robotic_arm_state_provider.dart';

class RoboticArmControls extends StatefulWidget {
  final VoidCallback onClose;

  const RoboticArmControls({super.key, required this.onClose});

  @override
  State<RoboticArmControls> createState() => _RoboticArmControlsState();
}

class _RoboticArmControlsState extends State<RoboticArmControls> {
  bool manualChecked = false;
  String selectedDuration = duration1Min;
  String selectedFrequency = frequency50Hz;
  String selectedMaxAngle = angle180;
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoboticArmStateProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        elevation: 8,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryRed, width: 1),
        ),
        child: SizedBox(
          width: 280,
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        controlsTitle,
                        style: TextStyle(
                          color: primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.close, color: primaryRed),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 30,
                      margin: const EdgeInsets.only(left: 6, right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Consumer<RoboticArmStateProvider>(
                            builder: (context, provider, _) {
                              return Checkbox(
                                value: provider.manualEnabled,
                                onChanged: (bool? value) {
                                  final newValue = value ?? false;
                                  if (newValue && provider.isPlaying) {
                                    provider.stopScrolling(resetPosition: true);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(playBackStop),
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.black87,
                                      ),
                                    );
                                  }
                                  provider.setManualEnabled(newValue);
                                },
                                activeColor: primaryRed,
                              );
                            },
                          ),
                          Text(
                            manualLabel,
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 30,
                      margin: const EdgeInsets.only(left: 6, right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Consumer<RoboticArmStateProvider>(
                            builder: (context, provider, _) {
                              return Checkbox(
                                value: provider.feedbackEnabled,
                                onChanged: (bool? value) {
                                  provider.setFeedbackEnabled(value ?? false);
                                },
                                activeColor: primaryRed,
                              );
                            },
                          ),
                          Text(
                            feedbackLabel,
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: duration1Min,
                                groupValue: provider.selectedDuration,
                                activeColor: primaryRed,
                                onChanged: (value) {
                                  provider.setSelectedDuration(value!);
                                },
                              ),
                              Text(duration1Min,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: duration2Min,
                                groupValue: provider.selectedDuration,
                                activeColor: primaryRed,
                                onChanged: (value) {
                                  provider.setSelectedDuration(value!);
                                },
                              ),
                              Text(duration2Min,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Consumer<RoboticArmStateProvider>(
                            builder: (context, provider, _) {
                              final hasValues = provider.timelineDegrees.any(
                                (row) => row.any((val) => val != null),
                              );

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: hasValues
                                        ? () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(clearTimelineTitle),
                                                content: Text(
                                                    clearTimelineConfirmation),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade300,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        cancel,
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black),
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      provider
                                                          .clearTimelineDegrees();
                                                      provider
                                                          .setSelectedDuration(
                                                              duration1Min);
                                                      provider
                                                          .setSelectedFrequency(
                                                              frequency50Hz);
                                                      provider.setManualEnabled(
                                                          false);
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: primaryRed,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        clear,
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        : null,
                                    icon: Icon(
                                      Icons.recycling,
                                      color:
                                          hasValues ? primaryRed : Colors.black,
                                    ),
                                    tooltip: clearTimelineTooltip,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    )),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: frequency50Hz,
                        groupValue: provider.selectedFrequency,
                        activeColor: primaryRed,
                        onChanged: (value) {
                          if (provider.isPlaying) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(frequencyChange),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.black87,
                              ),
                            );
                            return;
                          }
                          provider.setSelectedFrequency(value!);
                        },
                      ),
                      Text(
                        frequency50Hz,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: frequency100Hz,
                        groupValue: provider.selectedFrequency,
                        activeColor: primaryRed,
                        onChanged: (value) {
                          if (provider.isPlaying) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(frequencyChange),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.black87,
                              ),
                            );
                            return;
                          }
                          provider.setSelectedFrequency(value!);
                        },
                      ),
                      Text(
                        frequency100Hz,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: angle180,
                        groupValue: provider.selectedMaxAngle,
                        activeColor: primaryRed,
                        onChanged: (value) {
                          provider.setSelectedMaxAngle(value!);
                        },
                      ),
                      Text(
                        angle180,
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: angle360,
                        groupValue: provider.selectedMaxAngle,
                        activeColor: primaryRed,
                        onChanged: (value) {
                          provider.setSelectedMaxAngle(value!);
                        },
                      ),
                      Text(
                        angle360,
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
