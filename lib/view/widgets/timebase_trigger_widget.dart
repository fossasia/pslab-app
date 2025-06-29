import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';

import '../../theme/colors.dart';

class TimebaseTriggerWidget extends StatefulWidget {
  const TimebaseTriggerWidget({super.key});

  @override
  State<StatefulWidget> createState() => _TimebaseTriggerState();
}

class _TimebaseTriggerState extends State<TimebaseTriggerWidget> {
  @override
  Widget build(BuildContext context) {
    OscilloscopeStateProvider oscilloscopeStateProvider =
        Provider.of<OscilloscopeStateProvider>(context, listen: false);
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 5),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: primaryRed),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: -4,
                left: 4,
                right: 0,
                child: Row(
                  children: [
                    Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: checkBoxActiveColor,
                      value: oscilloscopeStateProvider.isTriggerSelected,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            oscilloscopeStateProvider.isTriggerSelected =
                                value!;
                          },
                        );
                      },
                    ),
                    Text(
                      trigger,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: DropdownMenu<String>(
                        width: 95,
                        initialSelection:
                            oscilloscopeStateProvider.triggerChannel,
                        dropdownMenuEntries: channelEntries.map(
                          (String value) {
                            return DropdownMenuEntry<String>(
                              label: value,
                              value: value,
                            );
                          },
                        ).toList(),
                        inputDecorationTheme: const InputDecorationTheme(
                          border: InputBorder.none,
                        ),
                        textStyle: TextStyle(
                          color: oscilloscopeOptionLabelColor,
                          fontSize: 15,
                        ),
                        onSelected: (String? value) {
                          oscilloscopeStateProvider.triggerChannel = value!;
                        },
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          inactiveTrackColor: sliderInActiveColor,
                          trackHeight: 1,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                        ),
                        child: Selector<OscilloscopeStateProvider, double>(
                          selector: (context, provider) =>
                              provider.oscilloscopeAxesScale.yAxisScale,
                          builder: (context, yAxisScale, _) {
                            return Slider(
                              activeColor: sliderActiveColor,
                              min: -yAxisScale,
                              max: yAxisScale,
                              value: oscilloscopeStateProvider.trigger
                                  .clamp(-yAxisScale, yAxisScale),
                              onChanged: (double value) {
                                setState(
                                  () {
                                    oscilloscopeStateProvider.trigger = value;
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: TextEditingController(
                          text:
                              "${oscilloscopeStateProvider.trigger.toStringAsFixed(1)} V",
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: oscilloscopeOptionLabelColor,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                        ),
                        onSubmitted: (value) {
                          String triggerValue =
                              value.replaceAll("V", "").trim();
                          double parsedValue =
                              double.tryParse(triggerValue) ?? 0.0;
                          if (parsedValue >
                              oscilloscopeStateProvider
                                  .oscilloscopeAxesScale.yAxisScaleMax) {
                            parsedValue = oscilloscopeStateProvider
                                .oscilloscopeAxesScale.yAxisScaleMax;
                          } else if (parsedValue <
                              oscilloscopeStateProvider
                                  .oscilloscopeAxesScale.yAxisScaleMin) {
                            parsedValue = oscilloscopeStateProvider
                                .oscilloscopeAxesScale.yAxisScaleMin;
                          }
                          setState(() {
                            oscilloscopeStateProvider.trigger = parsedValue;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: DropdownMenu<String>(
                        width: 155,
                        initialSelection:
                            oscilloscopeStateProvider.triggerMode ==
                                    MODE.rising.toString()
                                ? 'Rising Edge'
                                : oscilloscopeStateProvider.triggerMode ==
                                        MODE.falling.toString()
                                    ? 'Falling Edge'
                                    : 'Dual Edge',
                        dropdownMenuEntries: <String>[
                          'Rising Edge',
                          'Falling Edge',
                          'Dual Edge',
                        ].map(
                          (String value) {
                            return DropdownMenuEntry<String>(
                              label: value,
                              value: value,
                            );
                          },
                        ).toList(),
                        inputDecorationTheme: const InputDecorationTheme(
                          border: InputBorder.none,
                        ),
                        textStyle: TextStyle(
                          color: oscilloscopeOptionLabelColor,
                          fontSize: 14,
                        ),
                        onSelected: (String? value) {
                          switch (value) {
                            case 'Rising Edge':
                              oscilloscopeStateProvider.triggerMode =
                                  MODE.rising.toString();
                              break;
                            case 'Falling Edge':
                              oscilloscopeStateProvider.triggerMode =
                                  MODE.falling.toString();
                              break;
                            case 'Dual Edge':
                              oscilloscopeStateProvider.triggerMode =
                                  MODE.dual.toString();
                              break;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -2,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      timeBase,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          inactiveTrackColor: sliderInActiveColor,
                          trackHeight: 1,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          activeColor: sliderActiveColor,
                          min: 0,
                          max: oscilloscopeStateProvider.timebaseDivisions
                              .toDouble(),
                          divisions:
                              oscilloscopeStateProvider.timebaseDivisions,
                          value: oscilloscopeStateProvider.timebaseSlider.clamp(
                              0,
                              oscilloscopeStateProvider.timebaseDivisions
                                  .toDouble()),
                          onChanged: (double value) {
                            setState(
                              () {
                                oscilloscopeStateProvider.timebaseSlider =
                                    value;
                                oscilloscopeStateProvider.setTimebase(value);
                              },
                            );
                            switch (value) {
                              case 0:
                                oscilloscopeStateProvider.samples = 512;
                                oscilloscopeStateProvider.timeGap =
                                    (2 * oscilloscopeStateProvider.timebase) /
                                        oscilloscopeStateProvider.samples;
                                break;
                              case 1:
                                oscilloscopeStateProvider.samples = 512;
                                oscilloscopeStateProvider.timeGap =
                                    (2 * oscilloscopeStateProvider.timebase) /
                                        oscilloscopeStateProvider.samples;
                                break;
                              case 2:
                                oscilloscopeStateProvider.samples = 512;
                                oscilloscopeStateProvider.timeGap =
                                    (2 * oscilloscopeStateProvider.timebase) /
                                        oscilloscopeStateProvider.samples;
                                break;
                              case 3:
                                oscilloscopeStateProvider.samples = 512;
                                oscilloscopeStateProvider.timeGap =
                                    (2 * oscilloscopeStateProvider.timebase) /
                                        oscilloscopeStateProvider.samples;
                                break;
                              case 4:
                                oscilloscopeStateProvider.samples = 1024;
                                oscilloscopeStateProvider.timeGap =
                                    (2 * oscilloscopeStateProvider.timebase) /
                                        oscilloscopeStateProvider.samples;
                                break;
                              case 5:
                                oscilloscopeStateProvider.samples = 1024;
                                oscilloscopeStateProvider.timeGap =
                                    (2 * oscilloscopeStateProvider.timebase) /
                                        oscilloscopeStateProvider.samples;
                                break;
                              case 6:
                                oscilloscopeStateProvider.samples = 1024;
                                oscilloscopeStateProvider.timeGap =
                                    (2 * oscilloscopeStateProvider.timebase) /
                                        oscilloscopeStateProvider.samples;
                                break;
                              case 7:
                                oscilloscopeStateProvider.samples = 1024;
                                oscilloscopeStateProvider.timeGap =
                                    (2 * oscilloscopeStateProvider.timebase) /
                                        oscilloscopeStateProvider.samples;
                                break;
                              default:
                                oscilloscopeStateProvider.samples = 512;
                                oscilloscopeStateProvider.timeGap =
                                    (2 * oscilloscopeStateProvider.timebase) /
                                        oscilloscopeStateProvider.samples;
                                break;
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        oscilloscopeStateProvider.timebase == 875
                            ? '${oscilloscopeStateProvider.timebase.toStringAsFixed(2)} \u00b5s'
                            : '${(oscilloscopeStateProvider.timebase / 1000).toStringAsFixed(2)} ms',
                        style: TextStyle(
                          color: oscilloscopeOptionLabelColor,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 1,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: oscilloscopeOptionTitleBoxColor),
              child: Text(
                timeBaseAndTrigger,
                style: TextStyle(
                  color: oscilloscopeOptionTitleColor,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
