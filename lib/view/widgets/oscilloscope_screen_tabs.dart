import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class OscilloscopeScreenTabs extends StatefulWidget {
  final String channelParametersImage = 'assets/images/channel_parameters.gif';
  final String dataAnalysisImage = 'assets/images/data_analysis.png';
  final String timebaseTriggerImage = 'assets/images/timebase.png';
  final String xyPlotImage = 'assets/images/xymode.png';

  const OscilloscopeScreenTabs({super.key});

  @override
  State<StatefulWidget> createState() => _OscilloscopeTabsState();
}

class _OscilloscopeTabsState extends State<OscilloscopeScreenTabs> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  @override
  Widget build(BuildContext context) {
    OscilloscopeStateProvider oscilloscopeStateProvider =
        Provider.of<OscilloscopeStateProvider>(context);
    return Container(
      margin: const EdgeInsets.only(right: 5, bottom: 5),
      decoration: BoxDecoration(
        border: Border.all(width: 3, color: oscilloscopeTabBorderColor),
        color: oscilloscopeTabOuterBoxColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(
                  () {
                    oscilloscopeStateProvider.updateSelectedIndex(0);
                  },
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: oscilloscopeTabInnerBoxColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      margin: const EdgeInsets.all(4),
                      child: Image.asset(
                        widget.channelParametersImage,
                      ),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    color: oscilloscopeStateProvider.selectedIndex == 0
                        ? oscilloscopeOptionTitleColor
                        : Colors.transparent,
                    child: Text(
                      appLocalizations.channels,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
                        fontSize: 10,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(
                    color: oscilloscopeTabBorderColor,
                    height: 2,
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(
                  () {
                    oscilloscopeStateProvider.updateSelectedIndex(1);
                  },
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: oscilloscopeTabInnerBoxColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      margin: const EdgeInsets.all(4),
                      child: Image.asset(
                        widget.timebaseTriggerImage,
                      ),
                    ),
                  ),
                  Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 2),
                      color: oscilloscopeStateProvider.selectedIndex == 1
                          ? oscilloscopeOptionTitleColor
                          : Colors.transparent,
                      child: Text(
                        appLocalizations.timeBase,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: oscilloscopeOptionLabelColor,
                          fontSize: 10,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                  Divider(
                    color: oscilloscopeTabBorderColor,
                    height: 2,
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(
                  () {
                    oscilloscopeStateProvider.updateSelectedIndex(2);
                  },
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: oscilloscopeTabInnerBoxColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      margin: const EdgeInsets.all(4),
                      child: Image.asset(
                        widget.dataAnalysisImage,
                      ),
                    ),
                  ),
                  Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 2),
                      color: oscilloscopeStateProvider.selectedIndex == 2
                          ? oscilloscopeOptionTitleColor
                          : Colors.transparent,
                      child: Text(
                        appLocalizations.dataAnalysis,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: oscilloscopeOptionLabelColor,
                          fontSize: 10,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                  Divider(
                    color: oscilloscopeTabBorderColor,
                    height: 2,
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(
                  () {
                    oscilloscopeStateProvider.updateSelectedIndex(3);
                  },
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: oscilloscopeTabInnerBoxColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      margin: const EdgeInsets.all(4),
                      child: Image.asset(
                        widget.xyPlotImage,
                      ),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    color: oscilloscopeStateProvider.selectedIndex == 3
                        ? oscilloscopeOptionTitleColor
                        : Colors.transparent,
                    child: Text(
                      appLocalizations.xyPlot,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: oscilloscopeOptionLabelColor,
                        fontSize: 10,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
