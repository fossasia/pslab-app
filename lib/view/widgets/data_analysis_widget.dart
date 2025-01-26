import 'package:flutter/material.dart';

class DataAnalysisWidget extends StatefulWidget {
  const DataAnalysisWidget({super.key});

  @override
  State<StatefulWidget> createState() => _DataAnalysisState();
}

class _DataAnalysisState extends State<DataAnalysisWidget> {
  bool? isFourierTransformSelected = false;
  double horizontalOffset = 0;
  double verticalOffset = 0;

  @override
  Widget build(BuildContext context) {
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
                            value: isFourierTransformSelected,
                            onChanged: (bool? value) {
                              setState(
                                () {
                                  isFourierTransformSelected = value;
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
                            initialSelection: 'Sine Fit',
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
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: 0,
                      child: DropdownMenu<String>(
                        width: 90,
                        initialSelection: '',
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
                      ),
                    ),
                    Positioned(
                      bottom: -6,
                      right: 0,
                      child: DropdownMenu<String>(
                        width: 90,
                        initialSelection: '',
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
                          width: 90,
                          initialSelection: 'CH1',
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
                                min: -16,
                                max: 16,
                                value: verticalOffset,
                                onChanged: (double value) {
                                  setState(
                                    () {
                                      verticalOffset = value;
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          Text(
                            '${verticalOffset.toStringAsFixed(2)} V',
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
                                max: 1,
                                value: horizontalOffset,
                                onChanged: (double value) {
                                  setState(
                                    () {
                                      horizontalOffset = value;
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          Text(
                            '${horizontalOffset.toStringAsFixed(2)} ms',
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
