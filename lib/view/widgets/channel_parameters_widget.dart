import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';

import '../../constants.dart';

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
            border: Border.all(width: 1, color: const Color(0xFFD32F2F)),
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
                      activeColor: const Color(0xFFCE525F),
                      onChanged: (bool? value) {
                        setState(
                          () {
                            oscilloscopeStateProvider.isCH1Selected = value!;
                          },
                        );
                      },
                    ),
                    const Text(
                      'CH1',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                        fontSize: 15,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Range',
                        style: TextStyle(
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
                        textStyle: const TextStyle(fontSize: 15),
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
                      activeColor: const Color(0xFFCE525F),
                      onChanged: (bool? value) {
                        setState(
                          () {
                            oscilloscopeStateProvider.isCH2Selected = value!;
                          },
                        );
                      },
                    ),
                    const Text(
                      'CH2',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                        fontSize: 15,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Range',
                        style: TextStyle(
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 120,
                        child: Text(
                          '+/-16V',
                          style: TextStyle(
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
                      activeColor: const Color(0xFFCE525F),
                      onChanged: (bool? value) {
                        setState(
                          () {
                            oscilloscopeStateProvider.isCH3Selected = value!;
                          },
                        );
                      },
                    ),
                    const Text(
                      'CH3 (+/- 3.3V)',
                      style: TextStyle(
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
                      activeColor: const Color(0xFFCE525F),
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
                    const Text(
                      'In-Built MIC',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    Radio<bool>(
                      activeColor: const Color(0xFFCE525F),
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
                    const Text(
                      'PSLab MIC',
                      style: TextStyle(
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
              decoration: const BoxDecoration(color: Colors.white),
              child: const Text(
                'Channels',
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
