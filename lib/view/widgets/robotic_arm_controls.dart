import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';
import '../../providers/robotic_arm_state_provider.dart';

class RoboticArmControls extends StatefulWidget {
  final VoidCallback onClose;

  const RoboticArmControls({super.key, required this.onClose});

  @override
  State<RoboticArmControls> createState() => _RoboticArmControlsState();
}

class _RoboticArmControlsState extends State<RoboticArmControls> {
  bool manualChecked = false;

  late AppLocalizations appLocalizations;
  late String selectedDuration;
  late String selectedFrequency;
  late String selectedMaxAngle;

  @override
  void initState() {
    super.initState();
    appLocalizations = getIt.get<AppLocalizations>();
    selectedDuration = appLocalizations.duration1Min;
    selectedFrequency = appLocalizations.frequency50Hz;
    selectedMaxAngle = appLocalizations.angle180;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoboticArmStateProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        elevation: 8,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.black, width: 1),
        ),
        child: SizedBox(
          height: screenHeight * 0.63,
          child: Column(
            children: [
              Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        appLocalizations.controlsTitle,
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
                    bottom: -2,
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
              SizedBox(
                height: screenHeight * 0.030,
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: screenHeight * 0.083,
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
                                        content:
                                            Text(appLocalizations.playBackStop),
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
                            appLocalizations.manualLabel,
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: screenHeight * 0.083,
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
                            appLocalizations.feedbackLabel,
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: screenHeight * 0.026,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: screenHeight * 0.11,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RadioGroup(
                                  groupValue: provider.selectedDuration,
                                  onChanged: (value) {
                                    provider.setSelectedDuration(value!);
                                  },
                                  child: Radio<String>(
                                    value: appLocalizations.duration1Min,
                                    activeColor: primaryRed,
                                  ),
                                ),
                                Text(
                                  appLocalizations.duration1Min,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RadioGroup(
                                  groupValue: provider.selectedDuration,
                                  onChanged: (value) {
                                    provider.setSelectedDuration(value!);
                                  },
                                  child: Radio<String>(
                                    value: appLocalizations.duration2Min,
                                    activeColor: primaryRed,
                                  ),
                                ),
                                Text(
                                  appLocalizations.duration2Min,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Consumer<RoboticArmStateProvider>(
                              builder: (context, provider, _) {
                                final hasValues = provider.timelineDegrees.any(
                                  (row) => row.any((val) => val != null),
                                );

                                return Center(
                                  child: TextButton(
                                    onPressed: hasValues
                                        ? () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(appLocalizations
                                                    .clearTimelineTitle),
                                                content: Text(appLocalizations
                                                    .clearTimelineConfirmation),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: Text(
                                                        appLocalizations.cancel
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black)),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      provider
                                                          .clearTimelineDegrees();
                                                      provider
                                                          .setSelectedDuration(
                                                              appLocalizations
                                                                  .duration1Min);
                                                      provider
                                                          .setSelectedFrequency(
                                                              appLocalizations
                                                                  .frequency50Hz);
                                                      provider.setManualEnabled(
                                                          false);
                                                    },
                                                    child: Text(
                                                      appLocalizations.clear,
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        : null,
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor:
                                          hasValues ? primaryRed : Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      textStyle: const TextStyle(fontSize: 11),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      side: BorderSide(
                                        color: hasValues
                                            ? primaryRed
                                            : Colors.black,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          size: 14,
                                          color: hasValues
                                              ? primaryRed
                                              : Colors.black,
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.009),
                                        Text(
                                          appLocalizations.clear,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Timeline',
                            style: TextStyle(fontSize: 8, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: screenHeight * 0.026,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: screenHeight * 0.11,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RadioGroup(
                            groupValue: provider.selectedFrequency,
                            onChanged: (value) {
                              if (provider.isPlaying) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(appLocalizations.frequencyChange),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.black87,
                                  ),
                                );
                                return;
                              }
                              provider.setSelectedFrequency(value!);
                            },
                            child: Radio<String>(
                              value: appLocalizations.frequency50Hz,
                              activeColor: primaryRed,
                            ),
                          ),
                          Text(
                            appLocalizations.frequency50Hz,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          RadioGroup(
                            groupValue: provider.selectedFrequency,
                            onChanged: (value) {
                              if (provider.isPlaying) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(appLocalizations.frequencyChange),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.black87,
                                  ),
                                );
                                return;
                              }
                              provider.setSelectedFrequency(value!);
                            },
                            child: Radio<String>(
                              value: appLocalizations.frequency100Hz,
                              activeColor: primaryRed,
                            ),
                          ),
                          Text(
                            appLocalizations.frequency100Hz,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Frequency',
                            style: TextStyle(fontSize: 8, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: screenHeight * 0.026,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: screenHeight * 0.11,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RadioGroup(
                            groupValue: provider.selectedMaxAngle,
                            onChanged: (value) {
                              provider.setSelectedMaxAngle(value!);
                            },
                            child: Radio<String>(
                              value: appLocalizations.angle180,
                              activeColor: primaryRed,
                            ),
                          ),
                          Text(
                            appLocalizations.angle180,
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          RadioGroup(
                            groupValue: provider.selectedMaxAngle,
                            onChanged: (value) {
                              provider.setSelectedMaxAngle(value!);
                            },
                            child: Radio<String>(
                              value: appLocalizations.angle360,
                              activeColor: primaryRed,
                            ),
                          ),
                          Text(
                            appLocalizations.angle360,
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Maximum Angle',
                            style: TextStyle(fontSize: 8, color: Colors.black),
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
    );
  }
}
