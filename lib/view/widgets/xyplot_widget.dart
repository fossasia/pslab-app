import 'package:flutter/material.dart';

class XYPlotWidget extends StatefulWidget {
  const XYPlotWidget({super.key});

  @override
  State<StatefulWidget> createState() => _XYPlotState();
}

class _XYPlotState extends State<XYPlotWidget> {
  bool? isXYPlotSelected = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 5),
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
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: const Color(0xFFCE525F),
                      value: isXYPlotSelected,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            isXYPlotSelected = value;
                          },
                        );
                      },
                    ),
                    const Text(
                      'Enable XY Plot',
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
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    DropdownMenu<String>(
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
                    DropdownMenu<String>(
                      width: 90,
                      initialSelection: 'CH2',
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
                'XY Plot',
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
    );
  }
}
