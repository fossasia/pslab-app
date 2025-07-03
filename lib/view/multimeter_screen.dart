import 'package:flutter/material.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/multimeter_knob.dart';

class MultimeterScreen extends StatefulWidget {
  const MultimeterScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MultimeterScreenState();
}

class _MultimeterScreenState extends State<MultimeterScreen> {
  @override
  Widget build(BuildContext context) {
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
                      width: 1,
                      color: const Color.fromARGB(255, 240, 162, 162)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 75,
                      child: Container(
                        padding: const EdgeInsets.only(right: 10, bottom: 10),
                        alignment: Alignment.centerRight,
                        child: Text(
                          "0.38",
                          style: TextStyle(
                            fontSize: 50,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Digital-7',
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey,
                    ),
                    Expanded(
                        flex: 25,
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            "Volts",
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 77,
              child: Stack(
                children: [
                  Column(children: [
                    Expanded(
                        flex: 47,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                                width: 3, color: const Color(0xFFD32F2F)),
                          ),
                          child: Text("Voltage",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: const Color(0xFFD32F2F),
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        )),
                    Expanded(
                        flex: 53,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 67,
                              child: Container(
                                height: double.infinity,
                                margin: const EdgeInsets.only(
                                    top: 5, left: 10, right: 2, bottom: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  border:
                                      Border.all(width: 3, color: Colors.black),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Hz",
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      Transform.scale(
                                        scale: 0.75,
                                        child: Switch(
                                          activeColor: Colors.black,
                                          value: true,
                                          onChanged: (value) {},
                                        ),
                                      ),
                                      Text(
                                        "Count Pulse",
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.black,
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
                                    top: 5, left: 2, right: 10, bottom: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  border:
                                      Border.all(width: 3, color: Colors.black),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Text("Measure",
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center),
                                ),
                              ),
                            )
                          ],
                        )),
                  ]),
                  RadialDial(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
