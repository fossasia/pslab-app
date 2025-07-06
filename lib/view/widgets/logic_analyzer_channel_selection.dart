import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/theme/colors.dart';

class LogicAnalyzerChannelSelection extends StatefulWidget {
  const LogicAnalyzerChannelSelection({super.key});

  @override
  State<StatefulWidget> createState() => _LogicAnalyzerChannelSelectionState();
}

class _LogicAnalyzerChannelSelectionState
    extends State<LogicAnalyzerChannelSelection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 15,
      ),
      child: Column(
        children: [
          Text(
            channelSelection,
            style: TextStyle(
              fontSize: 14,
              color: chartTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: CarouselSlider(
              items: [
                Text(
                  noOfChannelsOne,
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black,
                  ),
                ),
                Text(
                  noOfChannelsTwo,
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black,
                  ),
                ),
                Text(
                  noOfChannelsThree,
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black,
                  ),
                ),
                Text(
                  noOfChannelsFour,
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black,
                  ),
                ),
              ],
              options: CarouselOptions(
                height: 40,
                enableInfiniteScroll: false,
                initialPage: 0,
                viewportFraction: 0.4,
                enlargeCenterPage: true,
                enlargeFactor: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 10, right: 5),
              child: ScrollConfiguration(
                behavior: ScrollBehavior(),
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          DropdownButton(
                            dropdownColor: primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            value: channelLA1,
                            isExpanded: true,
                            underline: Container(),
                            iconEnabledColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: [channelLA1].map(
                              (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              },
                            ).toList(),
                            onChanged: (value) => {},
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white,
                          ),
                          DropdownButton(
                            dropdownColor: primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            value: analysisOptions[0],
                            isExpanded: true,
                            underline: Container(),
                            iconEnabledColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: analysisOptions.map(
                              (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              },
                            ).toList(),
                            onChanged: (value) => {},
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          DropdownButton(
                            dropdownColor: primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            value: channelLA2,
                            isExpanded: true,
                            underline: Container(),
                            iconEnabledColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: [channelLA2].map(
                              (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              },
                            ).toList(),
                            onChanged: (value) => {},
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white,
                          ),
                          DropdownButton(
                            dropdownColor: primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            value: analysisOptions[0],
                            isExpanded: true,
                            underline: Container(),
                            iconEnabledColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: analysisOptions.map(
                              (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              },
                            ).toList(),
                            onChanged: (value) => {},
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          DropdownButton(
                            dropdownColor: primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            value: channelLA3,
                            isExpanded: true,
                            underline: Container(),
                            iconEnabledColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: [channelLA3].map(
                              (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              },
                            ).toList(),
                            onChanged: (value) => {},
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white,
                          ),
                          DropdownButton(
                            dropdownColor: primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            value: analysisOptions[0],
                            isExpanded: true,
                            underline: Container(),
                            iconEnabledColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: analysisOptions.map(
                              (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              },
                            ).toList(),
                            onChanged: (value) => {},
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          DropdownButton(
                            dropdownColor: primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            value: channelLA4,
                            isExpanded: true,
                            underline: Container(),
                            iconEnabledColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: [channelLA4].map(
                              (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              },
                            ).toList(),
                            onChanged: (value) => {},
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white,
                          ),
                          DropdownButton(
                            dropdownColor: primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            value: analysisOptions[0],
                            isExpanded: true,
                            underline: Container(),
                            iconEnabledColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: analysisOptions.map(
                              (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              },
                            ).toList(),
                            onChanged: (value) => {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              fixedSize: const Size(200, 40),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              analyze,
              style: TextStyle(
                color: primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => {},
          )
        ],
      ),
    );
  }
}
