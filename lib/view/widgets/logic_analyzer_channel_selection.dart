import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/logic_analyzer_state_provider.dart';
import 'package:pslab/theme/colors.dart';

enum _LAControlType { channelCount, channel, edge }

class _HoveredControl {
  const _HoveredControl(this.type, this.index);

  final _LAControlType type;

  final int index;

  @override
  bool operator ==(Object other) =>
      other is _HoveredControl && other.type == type && other.index == index;

  @override
  int get hashCode => Object.hash(type, index);
}

class LogicAnalyzerChannelSelection extends StatefulWidget {
  const LogicAnalyzerChannelSelection({super.key});

  @override
  State<StatefulWidget> createState() => _LogicAnalyzerChannelSelectionState();
}

class _LogicAnalyzerChannelSelectionState
    extends State<LogicAnalyzerChannelSelection> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  late List<String> channelNames;
  late List<String> analysisOptions;

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final FocusNode _keyboardFocusNode = FocusNode(debugLabel: 'LAKeyboard');
  _HoveredControl? _hoveredControl;

  final Map<_HoveredControl, GlobalKey> _controlKeys = {};
  GlobalKey _keyFor(_HoveredControl control) =>
      _controlKeys.putIfAbsent(control, () => GlobalKey());

  static const Duration _scrollThrottle = Duration(milliseconds: 60);
  DateTime _lastScrollStep = DateTime.fromMillisecondsSinceEpoch(0);

  static const int _minChannels = 1;
  static const int _maxChannels = 4;

  bool get _usesPointer =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

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
      appLocalizations.analysisOptionEveryEdge.toUpperCase(),
      appLocalizations.analysisOptionEveryFallingEdge.toUpperCase(),
      appLocalizations.analysisOptionEveryRisingEdge.toUpperCase(),
      appLocalizations.analysisOptionEveryFourthRisingEdge.toUpperCase(),
      appLocalizations.analysisOptionDisabled.toUpperCase(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  String _channelValue(LogicAnalyzerStateProvider provider, int index) {
    switch (index) {
      case 0:
        return provider.channelSelectSpinner1;
      case 1:
        return provider.channelSelectSpinner2;
      case 2:
        return provider.channelSelectSpinner3;
      default:
        return provider.channelSelectSpinner4;
    }
  }

  void _setChannelValue(
      LogicAnalyzerStateProvider provider, int index, String value) {
    switch (index) {
      case 0:
        provider.channelSelectSpinner1 = value;
        break;
      case 1:
        provider.channelSelectSpinner2 = value;
        break;
      case 2:
        provider.channelSelectSpinner3 = value;
        break;
      default:
        provider.channelSelectSpinner4 = value;
        break;
    }
  }

  String _edgeValue(LogicAnalyzerStateProvider provider, int index) {
    switch (index) {
      case 0:
        return provider.edgeSelectSpinner1;
      case 1:
        return provider.edgeSelectSpinner2;
      case 2:
        return provider.edgeSelectSpinner3;
      default:
        return provider.edgeSelectSpinner4;
    }
  }

  void _setEdgeValue(
      LogicAnalyzerStateProvider provider, int index, String value) {
    switch (index) {
      case 0:
        provider.edgeSelectSpinner1 = value;
        break;
      case 1:
        provider.edgeSelectSpinner2 = value;
        break;
      case 2:
        provider.edgeSelectSpinner3 = value;
        break;
      default:
        provider.edgeSelectSpinner4 = value;
        break;
    }
  }

  void _applyStep(
    LogicAnalyzerStateProvider provider,
    _HoveredControl control,
    int step,
  ) {
    if (provider.isPlayingBack) return;
    switch (control.type) {
      case _LAControlType.channelCount:
        final int target =
            (provider.channelMode + step).clamp(_minChannels, _maxChannels);
        if (target != provider.channelMode) {
          _carouselController.animateToPage(target - 1);
        }
        break;
      case _LAControlType.channel:
        if (control.index >= provider.channelMode) return;
        final int current =
            channelNames.indexOf(_channelValue(provider, control.index));
        final int next = (current + step).clamp(0, channelNames.length - 1);
        if (next != current) {
          setState(() {
            _setChannelValue(provider, control.index, channelNames[next]);
          });
        }
        break;
      case _LAControlType.edge:
        if (control.index >= provider.channelMode) return;
        final int current =
            analysisOptions.indexOf(_edgeValue(provider, control.index));
        final int next = (current + step).clamp(0, analysisOptions.length - 1);
        if (next != current) {
          setState(() {
            _setEdgeValue(provider, control.index, analysisOptions[next]);
          });
        }
        break;
    }
  }

  void _handlePointerScroll(
    PointerSignalEvent event,
    LogicAnalyzerStateProvider provider,
    _HoveredControl control,
  ) {
    if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) return;
    if (provider.isPlayingBack) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      final DateTime now = DateTime.now();
      if (now.difference(_lastScrollStep) < _scrollThrottle) return;
      _lastScrollStep = now;
      _applyStep(provider, control, event.scrollDelta.dy < 0 ? 1 : -1);
    });
  }

  KeyEventResult _handleKey(
      LogicAnalyzerStateProvider provider, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (provider.isPlayingBack) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      provider.analyze();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveActive(provider.channelMode, 1);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveActive(provider.channelMode, -1);
      return KeyEventResult.handled;
    }

    final _HoveredControl? control = _hoveredControl;
    if (control == null) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _applyStep(provider, control, 1);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _applyStep(provider, control, -1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  List<_HoveredControl> _orderedControls(int channelMode) {
    final controls = <_HoveredControl>[
      const _HoveredControl(_LAControlType.channelCount, 0),
    ];
    for (int i = 0; i < channelMode; i++) {
      controls.add(_HoveredControl(_LAControlType.channel, i));
      controls.add(_HoveredControl(_LAControlType.edge, i));
    }
    return controls;
  }

  void _moveActive(int channelMode, int delta) {
    final controls = _orderedControls(channelMode);
    int index;
    final int current =
        _hoveredControl == null ? -1 : controls.indexOf(_hoveredControl!);
    if (current == -1) {
      index = delta > 0 ? 0 : controls.length - 1;
    } else {
      index = (current + delta).clamp(0, controls.length - 1);
    }
    final next = controls[index];
    setState(() => _hoveredControl = next);

    if (next.type != _LAControlType.channelCount) {
      final ctx = _controlKeys[next]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 200),
          alignment: 0.5,
        );
      }
    }
  }

  bool _isHovered(_HoveredControl control) => _hoveredControl == control;

  void _setHovered(_HoveredControl? control) {
    if (_hoveredControl == control) return;
    setState(() => _hoveredControl = control);
    if (control != null && !_keyboardFocusNode.hasFocus) {
      _keyboardFocusNode.requestFocus();
    }
  }

  Widget _interactiveControl({
    required LogicAnalyzerStateProvider provider,
    required _HoveredControl control,
    required Widget child,
  }) {
    return Listener(
      key: _keyFor(control),
      onPointerSignal: (event) =>
          _handlePointerScroll(event, provider, control),
      child: MouseRegion(
        onEnter: (_) => _setHovered(control),
        onExit: (_) {
          if (_isHovered(control)) _setHovered(null);
        },
        child: child,
      ),
    );
  }

  Widget _hoverHighlight({required bool hovered, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hovered ? logicAnalyzerTextColor : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: child,
    );
  }

  Widget _buildDropdown({
    required String value,
    required ValueChanged<String>? onChanged,
    required List<String> items,
  }) {
    return DropdownButton<String>(
      dropdownColor: primaryRed,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      value: value,
      isExpanded: true,
      underline: Container(),
      iconEnabledColor: logicAnalyzerTextColor,
      disabledHint: Text(
        value,
        style: TextStyle(color: logicAnalyzerTextColor, fontSize: 14),
      ),
      style: TextStyle(
        color: logicAnalyzerTextColor,
        fontSize: 14,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged == null
          ? null
          : (newValue) => setState(() => onChanged(newValue!)),
    );
  }

  Widget _buildChannelBlock(LogicAnalyzerStateProvider provider, int index) {
    final channelControl = _HoveredControl(_LAControlType.channel, index);
    final edgeControl = _HoveredControl(_LAControlType.edge, index);
    return Container(
      margin: EdgeInsets.only(top: index == 0 ? 0 : 10),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: primaryRed,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _interactiveControl(
            provider: provider,
            control: channelControl,
            child: _hoverHighlight(
              hovered: _isHovered(channelControl),
              child: _buildDropdown(
                value: _channelValue(provider, index),
                items: channelNames,
                onChanged: provider.isPlayingBack
                    ? null
                    : (value) => _setChannelValue(provider, index, value),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: logicAnalyzerTextColor,
          ),
          _interactiveControl(
            provider: provider,
            control: edgeControl,
            child: _hoverHighlight(
              hovered: _isHovered(edgeControl),
              child: _buildDropdown(
                value: _edgeValue(provider, index),
                items: analysisOptions,
                onChanged: provider.isPlayingBack
                    ? null
                    : (value) => _setEdgeValue(provider, index, value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCount(LogicAnalyzerStateProvider provider) {
    const control = _HoveredControl(_LAControlType.channelCount, 0);
    return _interactiveControl(
      provider: provider,
      control: control,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(top: 10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: logicAnalyzerTextColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _isHovered(control) ? primaryRed : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: CarouselSlider(
          carouselController: _carouselController,
          items: [
            appLocalizations.noOfChannelsOne,
            appLocalizations.noOfChannelsTwo,
            appLocalizations.noOfChannelsThree,
            appLocalizations.noOfChannelsFour,
          ]
              .map(
                (label) => Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 25,
                      color: logicAnalyzerChannelsTextColor,
                    ),
                  ),
                ),
              )
              .toList(),
          options: CarouselOptions(
            height: 40,
            enableInfiniteScroll: false,
            initialPage: provider.channelMode - 1,
            viewportFraction: 0.4,
            enlargeCenterPage: true,
            enlargeFactor: 0.4,
            scrollPhysics: (_usesPointer || provider.isPlayingBack)
                ? const NeverScrollableScrollPhysics()
                : null,
            onPageChanged: (index, reason) {
              if (provider.isPlayingBack) return;
              setState(() {
                provider.channelMode = index + 1;
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LogicAnalyzerStateProvider>(
      builder: (context, provider, _) {
        return Focus(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: (node, event) => _handleKey(provider, event),
          child: Container(
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
                _buildChannelCount(provider),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, right: 5),
                    child: ScrollConfiguration(
                      behavior: ScrollBehavior(),
                      child: ListView(
                        children: [
                          for (int i = 0; i < provider.channelMode; i++)
                            _buildChannelBlock(provider, i),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!provider.isPlayingBack)
                  TextButton(
                    style: TextButton.styleFrom(
                      fixedSize: const Size(double.maxFinite, 40),
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
                      appLocalizations.analyze.toUpperCase(),
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
          ),
        );
      },
    );
  }
}
