import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';
import 'package:pslab/constants.dart';

class DataAnalysisWidget extends StatefulWidget {
  const DataAnalysisWidget({super.key});

  @override
  State<StatefulWidget> createState() => _DataAnalysisState();
}

class _DataAnalysisState extends State<DataAnalysisWidget> {
  @override
  Widget build(BuildContext context) {
    OscilloscopeStateProvider oscilloscopeStateProvider =
        Provider.of<OscilloscopeStateProvider>(context, listen: false);
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 5, right: 2.5),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: const Color(0xFFD32F2F)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      left: 4,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Checkbox(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            activeColor: const Color(0xFFCE525F),
                            value: oscilloscopeStateProvider
                                .isFourierTransformSelected,
                            onChanged: (bool? value) {
                              setState(
                                () {
                                  oscilloscopeStateProvider
                                      .isFourierTransformSelected = value!;
                                },
                              );
                            },
                          ),
                          Text(
                            fourierAnalysis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -6,
                      left: 12,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          DropdownMenu<String>(
                            width: 150,
                            initialSelection: oscilloscopeStateProvider.sineFit
                                ? 'Sine Fit'
                                : 'Square Fit',
                            dropdownMenuEntries: <String>[
                              'Sine Fit',
                              'Square Fit',
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
                            textStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                            onSelected: (String? value) {
                              if (value == 'Sine Fit') {
                                oscilloscopeStateProvider.sineFit = true;
                                oscilloscopeStateProvider.squareFit = false;
                              } else {
                                oscilloscopeStateProvider.sineFit = false;
                                oscilloscopeStateProvider.squareFit = true;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: 0,
                      child: DropdownMenu<String>(
                        width: 95,
                        initialSelection:
                            oscilloscopeStateProvider.curveFittingChannel1,
                        dropdownMenuEntries: <String>[
                          '',
                          'CH1',
                          'CH2',
                          'CH3',
                          'MIC',
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
                        textStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                        onSelected: (value) {
                          setState(
                            () {
                              oscilloscopeStateProvider.curveFittingChannel1 =
                                  value!;
                            },
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: -6,
                      right: 0,
                      child: DropdownMenu<String>(
                        width: 95,
                        initialSelection:
                            oscilloscopeStateProvider.curveFittingChannel2,
                        dropdownMenuEntries: <String>[
                          '',
                          'CH1',
                          'CH2',
                          'CH3',
                          'MIC',
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
                        textStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                        onSelected: (value) {
                          setState(
                            () {
                              oscilloscopeStateProvider.curveFittingChannel2 =
                                  value!;
                            },
                          );
                        },
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
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Text(
                      dataAnalysis,
                      style: const TextStyle(
                        color: Color(0xFFC72C2C),
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 5, left: 2.5),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: const Color(0xFFD32F2F)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      top: 0,
                      left: 12,
                      child: Center(
                        child: DropdownMenu<String>(
                          width: 95,
                          initialSelection:
                              oscilloscopeStateProvider.selectedChannelOffset,
                          dropdownMenuEntries: <String>[
                            'CH1',
                            'CH2',
                            'CH3',
                            'MIC',
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
                          textStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                          ),
                          onSelected: (value) => {
                            setState(
                              () {
                                oscilloscopeStateProvider
                                    .selectedChannelOffset = value!;
                              },
                            )
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 8,
                      left: 75,
                      child: Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                inactiveTrackColor: Colors.blueGrey[100],
                                trackHeight: 1,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                activeColor: const Color(0xFFCE525F),
                                min: -oscilloscopeStateProvider
                                    .oscilloscopeAxesScale.yAxisScale,
                                max: oscilloscopeStateProvider
                                    .oscilloscopeAxesScale.yAxisScale,
                                value: oscilloscopeStateProvider.yOffsets[
                                        oscilloscopeStateProvider
                                            .selectedChannelOffset]!
                                    .clamp(
                                        -oscilloscopeStateProvider
                                            .oscilloscopeAxesScale.yAxisScale,
                                        oscilloscopeStateProvider
                                            .oscilloscopeAxesScale.yAxisScale),
                                onChanged: (double value) {
                                  setState(
                                    () {
                                      oscilloscopeStateProvider.yOffsets[
                                          oscilloscopeStateProvider
                                              .selectedChannelOffset] = value;
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
                                    '${oscilloscopeStateProvider.yOffsets[oscilloscopeStateProvider.selectedChannelOffset]!.toStringAsFixed(2)} V',
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: Colors.black,
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
                                  oscilloscopeStateProvider.yOffsets[
                                      oscilloscopeStateProvider
                                          .selectedChannelOffset] = parsedValue;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: 8,
                      left: 75,
                      child: Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                inactiveTrackColor: Colors.blueGrey[100],
                                trackHeight: 1,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                activeColor: const Color(0xFFCE525F),
                                min: 0,
                                max: oscilloscopeStateProvider.timebase / 1000,
                                value: oscilloscopeStateProvider
                                            .oscilloscopeAxesScale.xAxisScale ==
                                        875
                                    ? (oscilloscopeStateProvider.xOffsets[
                                                oscilloscopeStateProvider
                                                    .selectedChannelOffset]! /
                                            1000)
                                        .clamp(
                                            0,
                                            oscilloscopeStateProvider.timebase /
                                                1000)
                                    : oscilloscopeStateProvider.xOffsets[
                                            oscilloscopeStateProvider
                                                .selectedChannelOffset]!
                                        .clamp(
                                            0,
                                            oscilloscopeStateProvider.timebase /
                                                1000),
                                onChanged: (double value) {
                                  setState(
                                    () {
                                      if (oscilloscopeStateProvider
                                              .oscilloscopeAxesScale
                                              .xAxisScale ==
                                          875) {
                                        oscilloscopeStateProvider.xOffsets[
                                                oscilloscopeStateProvider
                                                    .selectedChannelOffset] =
                                            value * 1000;
                                      } else {
                                        oscilloscopeStateProvider.xOffsets[
                                            oscilloscopeStateProvider
                                                .selectedChannelOffset] = value;
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: TextEditingController(
                                text: oscilloscopeStateProvider
                                            .oscilloscopeAxesScale.xAxisScale ==
                                        875
                                    ? '${(oscilloscopeStateProvider.xOffsets[oscilloscopeStateProvider.selectedChannelOffset]! / 1000).toStringAsFixed(2)} ms'
                                    : '${oscilloscopeStateProvider.xOffsets[oscilloscopeStateProvider.selectedChannelOffset]!.toStringAsFixed(2)} ms',
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                fontStyle: FontStyle.normal,
                              ),
                              onSubmitted: (value) {
                                String triggerValue = value
                                    .replaceAll(RegExp(r'[ms]'), "")
                                    .trim();
                                double parsedValue =
                                    double.tryParse(triggerValue) ?? 0.0;
                                if (parsedValue >
                                    (oscilloscopeStateProvider
                                            .oscilloscopeAxesScale.xAxisScale /
                                        1000)) {
                                  parsedValue = oscilloscopeStateProvider
                                          .oscilloscopeAxesScale.xAxisScale /
                                      1000;
                                } else if (parsedValue < 0.0) {
                                  parsedValue = 0.0;
                                }
                                setState(() {
                                  if (oscilloscopeStateProvider
                                          .oscilloscopeAxesScale.xAxisScale ==
                                      875) {
                                    oscilloscopeStateProvider.xOffsets[
                                            oscilloscopeStateProvider
                                                .selectedChannelOffset] =
                                        parsedValue * 1000;
                                  } else {
                                    oscilloscopeStateProvider.xOffsets[
                                            oscilloscopeStateProvider
                                                .selectedChannelOffset] =
                                        parsedValue;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    )
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
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Text(
                      offsets,
                      style: const TextStyle(
                        color: Color(0xFFC72C2C),
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
