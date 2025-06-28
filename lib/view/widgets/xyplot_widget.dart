import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';

import '../../theme/colors.dart';

class XYPlotWidget extends StatefulWidget {
  const XYPlotWidget({super.key});

  @override
  State<StatefulWidget> createState() => _XYPlotState();
}

class _XYPlotState extends State<XYPlotWidget> {
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
                top: 4,
                left: 4,
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: checkBoxActiveColor,
                      value: oscilloscopeStateProvider.isXYPlotSelected,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            oscilloscopeStateProvider.isXYPlotSelected = value!;
                          },
                        );
                      },
                    ),
                    Text(
                      enablePlot,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
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
                      width: 95,
                      initialSelection: oscilloscopeStateProvider.xyPlotAxis1,
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
                        oscilloscopeStateProvider.xyPlotAxis1 = value!;
                      },
                    ),
                    DropdownMenu<String>(
                      width: 95,
                      initialSelection: oscilloscopeStateProvider.xyPlotAxis2,
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
                        oscilloscopeStateProvider.xyPlotAxis2 = value!;
                      },
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
              decoration: BoxDecoration(color: oscilloscopeOptionTitleBoxColor),
              child: Text(
                xyPlot,
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
