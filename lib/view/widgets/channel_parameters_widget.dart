import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChannelParametersWidget extends StatefulWidget {
  const ChannelParametersWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ChannelParametersState();
}

class _ChannelParametersState extends State<ChannelParametersWidget> {
  bool? isCH1Selected = false;
  bool? isCH2Selected = false;
  bool? isCH3Selected = false;
  bool? isMICSelected = false;
  bool? isInBuiltMICSelected = false;

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
                top: 0.h,
                left: 2.w,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: isCH1Selected,
                      activeColor: const Color(0xFFCE525F),
                      onChanged: (bool? value) {
                        setState(
                          () {
                            isCH1Selected = value;
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
                        initialSelection: '+/-16V',
                        width: 60.w,
                        dropdownMenuEntries: <String>[
                          '+/-16V',
                          '+/-8V',
                          '+/-4V',
                          '+/-3V',
                          '+/-2V',
                          '+/-1.5V',
                          '+/-1V',
                          '+/-500mV',
                          '+/-160V',
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
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 0.h),
                      child: DropdownMenu<String>(
                        width: 50.w,
                        initialSelection: 'CH1',
                        dropdownMenuEntries: <String>[
                          'CH1',
                          'CH2',
                          'CH3',
                          'MIC',
                          'RES',
                          'VOL',
                          'CAP',
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
                left: 2.w,
                bottom: 8.h,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: isCH2Selected,
                      activeColor: const Color(0xFFCE525F),
                      onChanged: (bool? value) {
                        setState(
                          () {
                            isCH2Selected = value;
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
                      value: isCH3Selected,
                      activeColor: const Color(0xFFCE525F),
                      onChanged: (bool? value) {
                        setState(
                          () {
                            isCH3Selected = value;
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
                      groupValue: isInBuiltMICSelected,
                      toggleable: true,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            if (value == null) {
                              isInBuiltMICSelected = false;
                            } else {
                              isInBuiltMICSelected = value;
                              isMICSelected = !value;
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
                      groupValue: isMICSelected,
                      toggleable: true,
                      onChanged: (bool? value) {
                        setState(
                          () {
                            if (value == null) {
                              isMICSelected = false;
                            } else {
                              isMICSelected = value;
                              isInBuiltMICSelected = !value;
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
