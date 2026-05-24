import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const int _tabCount = 4;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (!mounted) return false;
    final BuildContext? focusContext =
        FocusManager.instance.primaryFocus?.context;
    if (focusContext != null && focusContext.widget is EditableText) {
      return false;
    }
    final bool isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    final bool isArrow = event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown;
    if (!isEnter && !isArrow) return false;

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return true;
    }

    final OscilloscopeStateProvider provider =
        context.read<OscilloscopeStateProvider>();
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _cycleTab(provider, -1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _cycleTab(provider, 1);
      return true;
    }
    if (isEnter) {
      if (event is KeyRepeatEvent) return true;
      FocusManager.instance.primaryFocus?.unfocus();
      if (provider.isPlayingBack) {
        if (provider.isPlaybackPaused) {
          provider.resumePlayback();
        } else {
          provider.pausePlayback();
        }
      } else {
        provider.toggleRunning();
      }
      return true;
    }
    return false;
  }

  void _cycleTab(OscilloscopeStateProvider provider, int delta) {
    final int next = (provider.selectedIndex + delta + _tabCount) % _tabCount;
    provider.updateSelectedIndex(next);
  }

  void _selectTab(OscilloscopeStateProvider provider, int index) {
    provider.updateSelectedIndex(index);
  }

  Border _tabBorder(OscilloscopeStateProvider provider, int index) {
    return Border.all(
      width: 1,
      color: provider.selectedIndex == index
          ? oscilloscopeOptionTitleColor
          : Colors.transparent,
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        icon: Icon(icon, color: oscilloscopeOptionLabelColor),
        onPressed: onPressed,
      ),
    );
  }

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
          _arrowButton(
            icon: Icons.keyboard_arrow_up,
            tooltip: appLocalizations.previousTab,
            onPressed: () => _cycleTab(oscilloscopeStateProvider, -1),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _selectTab(oscilloscopeStateProvider, 0),
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
                          border: _tabBorder(oscilloscopeStateProvider, 0),
                        ),
                        margin: const EdgeInsets.all(4),
                        child: Image.asset(
                          widget.channelParametersImage,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 2),
                      color: oscilloscopeStateProvider.selectedIndex == 0
                          ? oscilloscopeOptionTitleColor
                          : Colors.transparent,
                      child: Text(
                        appLocalizations.channels,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: oscilloscopeOptionLabelColor,
                          fontSize: 9.5,
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
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _selectTab(oscilloscopeStateProvider, 1),
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
                          border: _tabBorder(oscilloscopeStateProvider, 1),
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
                            fontSize: 9.5,
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
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _selectTab(oscilloscopeStateProvider, 2),
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
                          border: _tabBorder(oscilloscopeStateProvider, 2),
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
                            fontSize: 9.5,
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
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _selectTab(oscilloscopeStateProvider, 3),
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
                          border: _tabBorder(oscilloscopeStateProvider, 3),
                        ),
                        margin: const EdgeInsets.all(4),
                        child: Image.asset(
                          widget.xyPlotImage,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 2),
                      color: oscilloscopeStateProvider.selectedIndex == 3
                          ? oscilloscopeOptionTitleColor
                          : Colors.transparent,
                      child: Text(
                        appLocalizations.xyPlot,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: oscilloscopeOptionLabelColor,
                          fontSize: 9.5,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _arrowButton(
            icon: Icons.keyboard_arrow_down,
            tooltip: appLocalizations.nextTab,
            onPressed: () => _cycleTab(oscilloscopeStateProvider, 1),
          ),
        ],
      ),
    );
  }
}
