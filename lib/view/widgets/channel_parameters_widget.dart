import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';

import '../../constants.dart';
import '../../theme/colors.dart';

class ChannelParametersWidget extends StatefulWidget {
  const ChannelParametersWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ChannelParametersState();
}

class _ChannelParametersState extends State<ChannelParametersWidget> {
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
                top: -4,
                left: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: oscilloscopeStateProvider.isCH1Selected,
                      activeColor: checkBoxActiveColor,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            oscilloscopeStateProvider.isCH1Selected = value!;
                          },
                        );
                      },
                    ),
                    Text(
                      ch1,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                        fontSize: 15,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        range,
                        style: const TextStyle(
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: DropdownMenu<String>(
                        initialSelection: yAxisRanges[oscilloscopeStateProvider
                            .oscillscopeRangeSelection],
                        width: 140,
                        dropdownMenuEntries: yAxisRanges.map(
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
                            color: oscilloscopeOptionLabelColor, fontSize: 15),
                        onSelected: (String? value) {
                          switch (yAxisRanges.indexOf(value!)) {
                            case 0:
                              oscilloscopeStateProvider.setYAxisScale(16);
                              break;
                            case 1:
                              oscilloscopeStateProvider.setYAxisScale(8);
                              break;
                            case 2:
                              oscilloscopeStateProvider.setYAxisScale(4);
                              break;
                            case 3:
                              oscilloscopeStateProvider.setYAxisScale(3);
                              break;
                            case 4:
                              oscilloscopeStateProvider.setYAxisScale(2);
                              break;
                            case 5:
                              oscilloscopeStateProvider.setYAxisScale(1.5);
                              break;
                            case 6:
                              oscilloscopeStateProvider.setYAxisScale(1);
                              break;
                            case 7:
                              oscilloscopeStateProvider.setYAxisScale(0.5);
                              break;
                            case 8:
                              oscilloscopeStateProvider.setYAxisScale(160);
                              break;
                            default:
                              oscilloscopeStateProvider.setYAxisScale(16);
                              break;
                          }
                          oscilloscopeStateProvider.oscillscopeRangeSelection =
                              yAxisRanges.indexOf(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 4,
                bottom: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: oscilloscopeStateProvider.isCH2Selected,
                      activeColor: checkBoxActiveColor,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            oscilloscopeStateProvider.isCH2Selected = value!;
                          },
                        );
                      },
                    ),
                    Text(
                      ch2,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                        fontSize: 15,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        range,
                        style: const TextStyle(
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 120,
                        child: Text(
                          rangeValue,
                          style: TextStyle(
                            color: oscilloscopeOptionLabelColor,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.normal,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: oscilloscopeStateProvider.isCH3Selected,
                      activeColor: checkBoxActiveColor,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            oscilloscopeStateProvider.isCH3Selected = value!;
                          },
                        );
                      },
                    ),
                    Text(
                      ch3Range,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 2,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Radio<bool>(
                      activeColor: radioButtonActiveColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: true,
                      groupValue:
                          oscilloscopeStateProvider.isInBuiltMICSelected,
                      toggleable: true,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            if (value == null) {
                              oscilloscopeStateProvider.isInBuiltMICSelected =
                                  false;
                              oscilloscopeStateProvider.isAudioInputSelected =
                                  false;
                              oscilloscopeStateProvider.setTimebaseDivisions(8);
                            } else {
                              if (value == true) {
                                oscilloscopeStateProvider
                                    .setTimebaseDivisions(6);
                              } else {
                                oscilloscopeStateProvider
                                    .setTimebaseDivisions(8);
                              }
                              oscilloscopeStateProvider.isAudioInputSelected =
                                  true;
                              oscilloscopeStateProvider.isInBuiltMICSelected =
                                  value;
                              oscilloscopeStateProvider.isMICSelected = !value;
                            }
                          },
                        );
                      },
                    ),
                    Text(
                      inBuiltMic,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    Radio<bool>(
                      activeColor: radioButtonActiveColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: true,
                      groupValue: oscilloscopeStateProvider.isMICSelected,
                      toggleable: true,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            if (value == null) {
                              oscilloscopeStateProvider.isMICSelected = false;
                              oscilloscopeStateProvider.isAudioInputSelected =
                                  false;
                            } else {
                              oscilloscopeStateProvider.isAudioInputSelected =
                                  true;
                              oscilloscopeStateProvider.isMICSelected = value;
                              oscilloscopeStateProvider.isInBuiltMICSelected =
                                  !value;
                            }
                          },
                        );
                      },
                    ),
                    Text(
                      pslabMic,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
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
                channels,
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
