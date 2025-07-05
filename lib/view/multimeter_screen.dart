import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/multimeter_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/multimeter_knob.dart';

class MultimeterScreen extends StatefulWidget {
  final String icRecord = 'assets/icons/ic_record_white.png';
  const MultimeterScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MultimeterScreenState();
}

class _MultimeterScreenState extends State<MultimeterScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MultimeterStateProvider(),
        ),
      ],
      child: Consumer<MultimeterStateProvider>(
        builder: (context, provider, _) {
          return CommonScaffold(
            title: multimeter,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    flex: 23,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            width: 1, color: multimeterBorderLightRed),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 75,
                            child: Container(
                              padding:
                                  const EdgeInsets.only(right: 10, bottom: 10),
                              alignment: Alignment.centerRight,
                              child: Text(
                                provider.value,
                                style: TextStyle(
                                  fontSize: 50,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Digital-7',
                                  color: multimeterBorderBlack,
                                ),
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: multimeterDividerColor,
                          ),
                          Expanded(
                            flex: 25,
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                provider.unit,
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 77,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              flex: 47,
                              child: Container(
                                width: double.infinity,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                      width: 3, color: multimeterBorderRed),
                                ),
                                child: Text(voltage,
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: multimeterBorderRed,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center),
                              ),
                            ),
                            Expanded(
                              flex: 53,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 67,
                                    child: Container(
                                      height: double.infinity,
                                      margin: const EdgeInsets.only(
                                          top: 5,
                                          left: 10,
                                          right: 2,
                                          bottom: 10),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        border: Border.all(
                                            width: 3, color: Colors.black),
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              unitHz,
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: multimeterBorderBlack,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                            Transform.scale(
                                              scale: 0.75,
                                              child: Switch(
                                                activeColor:
                                                    multimeterBorderBlack,
                                                value: provider.isSwitchChecked,
                                                onChanged: (bool value) {},
                                              ),
                                            ),
                                            Text(
                                              countPulse,
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: multimeterBorderBlack,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 33,
                                    child: Container(
                                      height: double.infinity,
                                      margin: const EdgeInsets.only(
                                          top: 5,
                                          left: 2,
                                          right: 10,
                                          bottom: 10),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        border: Border.all(
                                            width: 3,
                                            color: multimeterBorderBlack),
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Text(measure,
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: multimeterBorderBlack,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        MultimeterKnob(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Image.asset(
                  widget.icRecord,
                  width: 24,
                  height: 24,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.info, color: multimeterIconColor),
                onPressed: () {},
              ),
              IconButton(
                  icon: Icon(Icons.more_vert, color: multimeterIconColor),
                  onPressed: () {}),
            ],
          );
        },
      ),
    );
  }
}
