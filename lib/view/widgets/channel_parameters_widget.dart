import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        Provider.of<OscilloscopeStateProvider>(context);
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
                top: 0.h,
                left: 2.w,
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
                            oscilloscopeStateProvider.isCH1Selected = value;
                          },
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: const Text(
                        'CH1',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 1.h, left: 3.w),
                      child: const Text(
                        'Range',
                        style: TextStyle(
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 1.h, left: 4.w),
                      child: DropdownMenu<String>(
                        initialSelection: yAxisRanges[0],
                        width: 60.w,
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
                        textStyle: const TextStyle(
                          fontSize: 14,
                        ),
                        onSelected: (String? value) {
                          switch (yAxisRanges.indexOf(value!)) {
                            case 0:
                              oscilloscopeStateProvider.yAxisRange = 16;
                              break;
                            case 1:
                              oscilloscopeStateProvider.yAxisRange = 8;
                              break;
                            case 2:
                              oscilloscopeStateProvider.yAxisRange = 4;
                              break;
                            case 3:
                              oscilloscopeStateProvider.yAxisRange = 3;
                              break;
                            case 4:
                              oscilloscopeStateProvider.yAxisRange = 2;
                              break;
                            case 5:
                              oscilloscopeStateProvider.yAxisRange = 1.5;
                              break;
                            case 6:
                              oscilloscopeStateProvider.yAxisRange = 1;
                              break;
                            case 7:
                              oscilloscopeStateProvider.yAxisRange = 500;
                              break;
                            case 8:
                              oscilloscopeStateProvider.yAxisRange = 160;
                              break;
                            default:
                              oscilloscopeStateProvider.yAxisRange = 16;
                              break;
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 0.h),
                      child: DropdownMenu<String>(
                        width: 50.w,
                        initialSelection: rangeMenuEntries[0],
                        dropdownMenuEntries: rangeMenuEntries.map(
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
                left: 2.w,
                bottom: 8.h,
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
                            oscilloscopeStateProvider.isCH2Selected = value;
                          },
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: const Text(
                        'CH2',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 1.h, left: 3.w),
                      child: const Text(
                        'Range',
                        style: TextStyle(
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h, left: 4.w),
                      child: SizedBox(
                        width: 60.w,
                        child: const Text(
                          '+/-16V',
                          style: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: SizedBox(
                        width: 45.w,
                        child: const Text(
                          'CH2',
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
                top: 16.h,
                right: 4.w,
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
                            oscilloscopeStateProvider.isCH3Selected = value;
                          },
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: const Text(
                        'CH3 (+/- 3.3V)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 8.h,
                right: 4.w,
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
                            } else {
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
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: const Text(
                        'In-Built MIC',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.normal,
                        ),
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
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: const Text(
                        'PSLab MIC',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
          left: 0.w,
          right: 0.w,
          top: 2.h,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: const BoxDecoration(color: Colors.white),
              child: const Text(
                'Channel Parameters',
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
