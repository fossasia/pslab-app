import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/logic_analyzer_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class LogicAnalyzerChannelSelection extends StatefulWidget {
  const LogicAnalyzerChannelSelection({super.key});

  @override
  State<StatefulWidget> createState() => _LogicAnalyzerChannelSelectionState();
}

class _LogicAnalyzerChannelSelectionState
    extends State<LogicAnalyzerChannelSelection> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late List<String> channelNames;
  late List<String> analysisOptions;

  @override
  void initState() {
    super.initState();
    channelNames = [
      appLocalizations.channelLA1,
      appLocalizations.channelLA2,
      appLocalizations.channelLA3,
      appLocalizations.channelLA4,
    ];
    analysisOptions = [
      appLocalizations.analysisOptionEveryEdge,
      appLocalizations.analysisOptionEveryFallingEdge,
      appLocalizations.analysisOptionEveryRisingEdge,
      appLocalizations.analysisOptionEveryFourthRisingEdge,
      appLocalizations.analysisOptionDisabled,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LogicAnalyzerStateProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.only(
            left: 15,
          ),
          child: Column(
            children: [
              Text(
                appLocalizations.channelSelection,
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
                  color: logicAnalyzerTextColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CarouselSlider(
                  items: [
                    Text(
                      appLocalizations.noOfChannelsOne,
                      style: TextStyle(
                        fontSize: 25,
                        color: logicAnalyzerChannelsTextColor,
                      ),
                    ),
                    Text(
                      appLocalizations.noOfChannelsTwo,
                      style: TextStyle(
                        fontSize: 25,
                        color: logicAnalyzerChannelsTextColor,
                      ),
                    ),
                    Text(
                      appLocalizations.noOfChannelsThree,
                      style: TextStyle(
                        fontSize: 25,
                        color: logicAnalyzerChannelsTextColor,
                      ),
                    ),
                    Text(
                      appLocalizations.noOfChannelsFour,
                      style: TextStyle(
                        fontSize: 25,
                        color: logicAnalyzerChannelsTextColor,
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
                    onPageChanged: (index, reason) {
                      setState(() {
                        provider.channelMode = index + 1;
                      });
                    },
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
                                value: provider.channelSelectSpinner1,
                                isExpanded: true,
                                underline: Container(),
                                iconEnabledColor: logicAnalyzerTextColor,
                                style: TextStyle(
                                  color: logicAnalyzerTextColor,
                                  fontSize: 14,
                                ),
                                items: channelNames.map(
                                  (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  },
                                ).toList(),
                                onChanged: (value) => {
                                  setState(
                                    () {
                                      provider.channelSelectSpinner1 = value!;
                                    },
                                  ),
                                },
                              ),
                              Divider(
                                height: 1,
                                color: logicAnalyzerTextColor,
                              ),
                              DropdownButton(
                                dropdownColor: primaryRed,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                value: provider.edgeSelectSpinner1,
                                isExpanded: true,
                                underline: Container(),
                                iconEnabledColor: logicAnalyzerTextColor,
                                style: TextStyle(
                                  color: logicAnalyzerTextColor,
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
                                onChanged: (value) => {
                                  setState(
                                    () {
                                      provider.edgeSelectSpinner1 = value!;
                                    },
                                  ),
                                },
                              ),
                            ],
                          ),
                        ),
                        provider.channelMode > 1
                            ? Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
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
                                      value: provider.channelSelectSpinner2,
                                      isExpanded: true,
                                      underline: Container(),
                                      iconEnabledColor: logicAnalyzerTextColor,
                                      style: TextStyle(
                                        color: logicAnalyzerTextColor,
                                        fontSize: 14,
                                      ),
                                      items: channelNames.map(
                                        (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        },
                                      ).toList(),
                                      onChanged: (value) => {
                                        setState(
                                          () {
                                            provider.channelSelectSpinner2 =
                                                value!;
                                          },
                                        ),
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: logicAnalyzerTextColor,
                                    ),
                                    DropdownButton(
                                      dropdownColor: primaryRed,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      value: provider.edgeSelectSpinner2,
                                      isExpanded: true,
                                      underline: Container(),
                                      iconEnabledColor: logicAnalyzerTextColor,
                                      style: TextStyle(
                                        color: logicAnalyzerTextColor,
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
                                      onChanged: (value) => {
                                        setState(
                                          () {
                                            provider.edgeSelectSpinner2 =
                                                value!;
                                          },
                                        ),
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                        provider.channelMode > 2
                            ? Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
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
                                      value: provider.channelSelectSpinner3,
                                      isExpanded: true,
                                      underline: Container(),
                                      iconEnabledColor: logicAnalyzerTextColor,
                                      style: TextStyle(
                                        color: logicAnalyzerTextColor,
                                        fontSize: 14,
                                      ),
                                      items: channelNames.map(
                                        (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        },
                                      ).toList(),
                                      onChanged: (value) => {
                                        setState(
                                          () {
                                            provider.channelSelectSpinner3 =
                                                value!;
                                          },
                                        ),
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: logicAnalyzerTextColor,
                                    ),
                                    DropdownButton(
                                      dropdownColor: primaryRed,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      value: provider.edgeSelectSpinner3,
                                      isExpanded: true,
                                      underline: Container(),
                                      iconEnabledColor: logicAnalyzerTextColor,
                                      style: TextStyle(
                                        color: logicAnalyzerTextColor,
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
                                      onChanged: (value) => {
                                        setState(
                                          () {
                                            provider.edgeSelectSpinner3 =
                                                value!;
                                          },
                                        ),
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                        provider.channelMode > 3
                            ? Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
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
                                      value: provider.channelSelectSpinner4,
                                      isExpanded: true,
                                      underline: Container(),
                                      iconEnabledColor: logicAnalyzerTextColor,
                                      style: TextStyle(
                                        color: logicAnalyzerTextColor,
                                        fontSize: 14,
                                      ),
                                      items: channelNames.map(
                                        (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        },
                                      ).toList(),
                                      onChanged: (value) => {
                                        setState(
                                          () {
                                            provider.channelSelectSpinner4 =
                                                value!;
                                          },
                                        ),
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: logicAnalyzerTextColor,
                                    ),
                                    DropdownButton(
                                      dropdownColor: primaryRed,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      value: provider.edgeSelectSpinner4,
                                      isExpanded: true,
                                      underline: Container(),
                                      iconEnabledColor: logicAnalyzerTextColor,
                                      style: TextStyle(
                                        color: logicAnalyzerTextColor,
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
                                      onChanged: (value) => {
                                        setState(
                                          () {
                                            provider.edgeSelectSpinner4 =
                                                value!;
                                          },
                                        ),
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  fixedSize: const Size(200, 40),
                  backgroundColor: logicAnalyzerTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  appLocalizations.analyze,
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () => {
                  provider.analyze(),
                },
              )
            ],
          ),
        );
      },
    );
  }
}
