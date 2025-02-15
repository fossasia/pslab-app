import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';

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
                          const Text(
                            'Fourier Analysis',
                            style: TextStyle(
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
                    child: const Text(
                      'Data Analysis',
                      style: TextStyle(
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
                              data: const SliderThemeData(
                                trackHeight: 1,
                                thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                activeColor: const Color(0xFFCE525F),
                                min: -oscilloscopeStateProvider
                                    .oscillscopeAxesScale.yAxisScale,
                                max: oscilloscopeStateProvider
                                    .oscillscopeAxesScale.yAxisScale,
                                value: oscilloscopeStateProvider.yOffsets[
                                        oscilloscopeStateProvider
                                            .selectedChannelOffset]!
                                    .clamp(
                                        -oscilloscopeStateProvider
                                            .oscillscopeAxesScale.yAxisScale,
                                        oscilloscopeStateProvider
                                            .oscillscopeAxesScale.yAxisScale),
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
                          Text(
                            '${oscilloscopeStateProvider.yOffsets[oscilloscopeStateProvider.selectedChannelOffset]!.toStringAsFixed(2)} V',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              fontStyle: FontStyle.normal,
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
                              data: const SliderThemeData(
                                trackHeight: 1,
                                thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                activeColor: const Color(0xFFCE525F),
                                min: 0,
                                max: oscilloscopeStateProvider.timebase / 1000,
                                value: oscilloscopeStateProvider
                                            .oscillscopeAxesScale.xAxisScale ==
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
                                              .oscillscopeAxesScale
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
                          Text(
                            oscilloscopeStateProvider
                                        .oscillscopeAxesScale.xAxisScale ==
                                    875
                                ? '${(oscilloscopeStateProvider.xOffsets[oscilloscopeStateProvider.selectedChannelOffset]! / 1000).toStringAsFixed(2)} ms'
                                : '${oscilloscopeStateProvider.xOffsets[oscilloscopeStateProvider.selectedChannelOffset]!.toStringAsFixed(2)} ms',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              fontStyle: FontStyle.normal,
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
                    child: const Text(
                      'Offsets',
                      style: TextStyle(
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
