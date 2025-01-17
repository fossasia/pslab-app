import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class XYPlotWidget extends StatefulWidget {
  const XYPlotWidget({super.key});

  @override
  State<StatefulWidget> createState() => _XYPlotState();
}

class _XYPlotState extends State<XYPlotWidget> {
  bool? isXYPlotSelected = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 5),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: const Color(0xFFD32F2F)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0.h,
            left: 2.w,
            right: 0.w,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Checkbox(
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
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: const Text(
                    'Enable XY Plot',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
                const Spacer(),
                DropdownMenu<String>(
                  width: 50.w,
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
                    fontSize: 14,
                  ),
                ),
                DropdownMenu<String>(
                  width: 50.w,
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
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
