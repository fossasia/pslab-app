import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/power_source_config_provider.dart';
import 'package:pslab/providers/power_source_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/power_source_config_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/export_helper.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/power_source_knob.dart';

class PowerSourceScreen extends StatefulWidget {
  final String icRecord = 'assets/icons/ic_record_white.png';
  final String powerSourceCircuit =
      'assets/images/guide_images/power_source_guide.png';
  final List<List<dynamic>>? playbackData;

  const PowerSourceScreen({super.key, this.playbackData});

  @override
  State<StatefulWidget> createState() => _PowerSourceScreenState();
}

class _PowerSourceScreenState extends State<PowerSourceScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  late PowerSourceStateProvider _provider;
  late PowerSourceConfigProvider? _configProvider;
  bool _showGuide = false;
  Future<void>? _recordingStartFuture;
  final TextEditingController _pv1Controller = TextEditingController();
  final TextEditingController _pv2Controller = TextEditingController();
  final TextEditingController _pv3Controller = TextEditingController();
  final TextEditingController _pcsController = TextEditingController();
  final TextEditingController _psuController = TextEditingController();
  final FocusNode _pv1Focus = FocusNode();
  final FocusNode _pv2Focus = FocusNode();
  final FocusNode _pv3Focus = FocusNode();
  final FocusNode _pcsFocus = FocusNode();
  final FocusNode _psuFocus = FocusNode();

  final FocusNode _keyboardFocusNode = FocusNode();
  Pin? _hoveredPin;

  bool get _anyFieldFocused =>
      _pv1Focus.hasFocus ||
      _pv2Focus.hasFocus ||
      _pv3Focus.hasFocus ||
      _pcsFocus.hasFocus ||
      _psuFocus.hasFocus;

  static const double _scrollStepUnit = 50.0;
  final Map<Pin, double> _scrollAccumulators = {};

  void _handlePointerScroll(
    PointerSignalEvent event,
    Pin pin,
    double step,
    Future<void> Function(double) onValueChanged,
  ) {
    if (event is! PointerScrollEvent) return;
    if (_anyFieldFocused) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      final double accumulated =
          (_scrollAccumulators[pin] ?? 0) + event.scrollDelta.dy;
      final int steps = (accumulated / _scrollStepUnit).truncate();
      if (steps == 0) {
        _scrollAccumulators[pin] = accumulated;
        return;
      }
      _scrollAccumulators[pin] = accumulated - steps * _scrollStepUnit;

      onValueChanged(_provider.getValue(pin) - steps * step);
    });
  }

  void _onFieldFocusChange() {
    if (mounted) setState(() {});
  }

  KeyEventResult _handleArrowKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final Pin? pin = _hoveredPin;
    if (pin == null || _anyFieldFocused) return KeyEventResult.ignored;

    double delta;
    if ([LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowRight]
        .contains(event.logicalKey)) {
      delta = _provider.step;
    } else if ([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowLeft]
        .contains(event.logicalKey)) {
      delta = -_provider.step;
    } else {
      return KeyEventResult.ignored;
    }

    _provider.setValue(_provider.getValue(pin) + delta, pin);
    return KeyEventResult.handled;
  }

  @override
  void initState() {
    _provider = PowerSourceStateProvider();
    _configProvider = PowerSourceConfigProvider();
    _provider.setConfigProvider(_configProvider!);

    for (final focusNode in [
      _pv1Focus,
      _pv2Focus,
      _pv3Focus,
      _pcsFocus,
      _psuFocus,
    ]) {
      focusNode.addListener(_onFieldFocusChange);
    }

    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.playbackData != null) {
        _provider.startPlayback(widget.playbackData!);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    for (final focusNode in [
      _pv1Focus,
      _pv2Focus,
      _pv3Focus,
      _pcsFocus,
      _psuFocus,
    ]) {
      focusNode.removeListener(_onFieldFocusChange);
      focusNode.dispose();
    }
    _pv1Controller.dispose();
    _pv2Controller.dispose();
    _pv3Controller.dispose();
    _pcsController.dispose();
    _psuController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getPowerSourceContent() {
    if (_provider.isLabrador) {
      return [
        InstrumentIntroText(text: appLocalizations.labradorPowerSourceIntro),
        InstrumentBulletPoint(
            text: appLocalizations.labradorPowerSourceBulletPoint1),
        InstrumentBulletPoint(
            text: appLocalizations.labradorPowerSourceBulletPoint2),
        InstrumentBulletPoint(
            text: appLocalizations.labradorPowerSourceBulletPoint3),
        const InstrumentCompatibilitySection(
          pslabRequired: false,
        ),
      ];
    }
    return [
      InstrumentIntroText(text: appLocalizations.powerSourceIntro),
      InstrumentImage(imagePath: widget.powerSourceCircuit),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint3),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint4),
      const InstrumentCompatibilitySection(
        pslabRequired: true,
      ),
    ];
  }

  void _showOptionsMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        0,
        0,
        MediaQuery.of(context).size.height,
      ),
      items: [
        PopupMenuItem(
          value: 'show_logged_data',
          child: Text(appLocalizations.showLoggedData),
        ),
        PopupMenuItem(
          value: 'power_source_config',
          child: Text(appLocalizations.powerSourceConfigs),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'power_source_config':
            _navigateToConfig();
            break;
        }
      }
    });
  }

  void _navigateToConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangeNotifierProvider<PowerSourceConfigProvider>.value(
          value: _configProvider!,
          child: const PowerSourceConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.powerSource.toLowerCase()],
          appBarName: appLocalizations.powerSource,
          instrumentIcons: [instrumentIcons[5]],
        ),
      ),
    );
  }

  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
  }

  Future<void> _toggleRecording() async {
    if (_provider.isRecording) {
      await _saveRecording();
    } else {
      final startFuture = _provider.startRecording();
      _recordingStartFuture = startFuture;

      late bool hasStarted;
      try {
        hasStarted = await startFuture;
      } finally {
        if (identical(_recordingStartFuture, startFuture)) {
          _recordingStartFuture = null;
        }
      }
      if (!mounted) return;
      if (hasStarted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appLocalizations.recordingStarted}...',
              style: TextStyle(color: snackBarContentColor),
            ),
            backgroundColor: snackBarBackgroundColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appLocalizations.notConnected,
              style: TextStyle(color: snackBarContentColor),
            ),
            backgroundColor: snackBarBackgroundColor,
          ),
        );
      }
    }
  }

  Future<void> _saveRecording() async {
    final data = _provider.stopRecording();
    await ExportHelper.handleSaveData(
      context: context,
      instrumentName: appLocalizations.powerSource.toLowerCase(),
      data: data,
    );
  }

  Future<void> _handleBackPressed() async {
    final startFuture = _recordingStartFuture;
    if (startFuture != null) {
      try {
        await startFuture;
      } catch (_) {
        return;
      }
    }
    if (!mounted) return;
    if (_provider.isRecording) {
      await _saveRecording();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _buildPowerCard({
    required String label,
    required double value,
    required String suffix,
    required double maxValue,
    required Pin pin,
    required Future<void> Function(double) onValueChanged,
    required PowerSourceStateProvider provider,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    final String expectedText = value.toStringAsFixed(2);
    if (!focusNode.hasFocus && controller.text != expectedText) {
      controller.text = expectedText;
      controller.selection =
          TextSelection.collapsed(offset: expectedText.length);
    }
    return MouseRegion(
      onEnter: (_) {
        _hoveredPin = pin;
        if (!_anyFieldFocused) _keyboardFocusNode.requestFocus();
      },
      onExit: (_) {
        if (_hoveredPin == pin) _hoveredPin = null;
      },
      child: Listener(
        onPointerSignal: (event) =>
            _handlePointerScroll(event, pin, provider.step, onValueChanged),
        child: Card(
          color: scaffoldBackgroundColor,
          child: Row(
            children: [
              Expanded(
                flex: 45,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        controller: controller,
                        focusNode: focusNode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                        onSubmitted: (v) async =>
                            await onValueChanged(double.tryParse(v) ?? 0),
                        onTapOutside: (_) => focusNode.unfocus(),
                        decoration: InputDecoration(
                          suffixText: suffix,
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: powerSourceBorderLightRed),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: powerSourceBorderLightRed),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: 50,
                              width: 55,
                              child: IconButton.filled(
                                icon: const Icon(Icons.arrow_drop_up),
                                iconSize: 36,
                                tooltip: appLocalizations.increaseValue,
                                color: scaffoldBackgroundColor,
                                onPressed: () async {
                                  await onValueChanged(value + provider.step);
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: primaryRed,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 50,
                              width: 55,
                              child: IconButton.filled(
                                icon: const Icon(Icons.arrow_drop_down),
                                tooltip: appLocalizations.decreaseValue,
                                iconSize: 36,
                                color: scaffoldBackgroundColor,
                                onPressed: () async {
                                  await onValueChanged(value - provider.step);
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: primaryRed,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 55,
                child: PowerSourceKnob(
                  maxValue: maxValue,
                  pin: pin,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabradorVerticalBoxes(
      PowerSourceStateProvider provider, BoxConstraints constraints) {
    final double value = provider.voltagePSU;
    final String expectedText = value.toStringAsFixed(2);
    if (!_psuFocus.hasFocus && _psuController.text != expectedText) {
      _psuController.text = expectedText;
      _psuController.selection =
          TextSelection.collapsed(offset: expectedText.length);
    }

    final double contentWidth = constraints.maxWidth < 650
        ? double.infinity
        : (constraints.maxWidth * 0.55).clamp(460.0, 620.0);

    return MouseRegion(
      onEnter: (_) {
        _hoveredPin = Pin.psu;
        if (!_anyFieldFocused) _keyboardFocusNode.requestFocus();
      },
      onExit: (_) {
        if (_hoveredPin == Pin.psu) _hoveredPin = null;
      },
      child: Listener(
        onPointerSignal: (event) => _handlePointerScroll(
          event,
          Pin.psu,
          provider.step,
          provider.setPSU,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Box 1: Input, Plus/Minus Stepper Buttons, Presets
                  Card(
                    color: scaffoldBackgroundColor,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: primaryRed,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appLocalizations.psuLabelRange,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  controller: _psuController,
                                  focusNode: _psuFocus,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSubmitted: (v) async => await provider
                                      .setPSU(double.tryParse(v) ?? value),
                                  onTapOutside: (_) => _psuFocus.unfocus(),
                                  decoration: InputDecoration(
                                    suffixText: ' V',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: powerSourceBorderLightRed),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: primaryRed, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 48,
                                width: 52,
                                child: IconButton.filled(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  iconSize: 34,
                                  tooltip: appLocalizations.decreaseValue,
                                  color: scaffoldBackgroundColor,
                                  onPressed: () async {
                                    await provider
                                        .setPSU(value - provider.step);
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: primaryRed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 48,
                                width: 52,
                                child: IconButton.filled(
                                  icon: const Icon(Icons.arrow_drop_up),
                                  iconSize: 34,
                                  tooltip: appLocalizations.increaseValue,
                                  color: scaffoldBackgroundColor,
                                  onPressed: () async {
                                    await provider
                                        .setPSU(value + provider.step);
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: primaryRed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [4.5, 5.0, 6.0, 7.5, 9.0, 12.0].map((v) {
                              final isSelected = (value - v).abs() < 0.05;
                              return InkWell(
                                onTap: () => provider.setPSU(v),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryRed
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryRed
                                          : powerSourceBorderLightRed,
                                    ),
                                  ),
                                  child: Text(
                                    '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)}V',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Box 2: Rotary Dialer with Primary Red Border
                  Card(
                    color: scaffoldBackgroundColor,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: primaryRed,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PowerSourceKnob(
                            maxValue: 750,
                            pin: Pin.psu,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                appLocalizations.psuMinVoltage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                appLocalizations.psuMaxVoltage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _provider),
      ],
      child: Consumer<PowerSourceStateProvider>(
        builder: (context, provider, _) {
          final powerSourceCards = [
            _buildPowerCard(
              label: appLocalizations.pinPV1,
              value: provider.voltagePV1,
              suffix: ' V',
              onValueChanged: provider.setPV1,
              provider: provider,
              maxValue: 1000,
              pin: Pin.pv1,
              controller: _pv1Controller,
              focusNode: _pv1Focus,
            ),
            _buildPowerCard(
              label: appLocalizations.pinPV2,
              value: provider.voltagePV2,
              suffix: ' V',
              onValueChanged: provider.setPV2,
              provider: provider,
              maxValue: 660,
              pin: Pin.pv2,
              controller: _pv2Controller,
              focusNode: _pv2Focus,
            ),
            _buildPowerCard(
              label: appLocalizations.pinPV3,
              value: provider.voltagePV3,
              suffix: ' V',
              onValueChanged: provider.setPV3,
              provider: provider,
              maxValue: 330,
              pin: Pin.pv3,
              controller: _pv3Controller,
              focusNode: _pv3Focus,
            ),
            _buildPowerCard(
              label: appLocalizations.pinPCS,
              value: provider.currentPCS,
              suffix: ' mA',
              onValueChanged: provider.setPCS,
              provider: provider,
              maxValue: 330,
              pin: Pin.pcs,
              controller: _pcsController,
              focusNode: _pcsFocus,
            ),
          ];

          return Stack(
            children: [
              CommonScaffold(
                title: appLocalizations.powerSourceTitle,
                key: const Key(powerSourceScreenTitleKey),
                onOptionsPressed:
                    provider.isPlayingBack ? null : _showOptionsMenu,
                onGuidePressed: _showInstrumentGuide,
                onRecordPressed:
                    provider.isPlayingBack ? null : _toggleRecording,
                onBackPressed: _handleBackPressed,
                isRecording: provider.isRecording,
                isPlayingBack: provider.isPlayingBack,
                isPlaybackPaused: provider.isPlaybackPaused,
                onPlaybackPauseResume: provider.isPlayingBack
                    ? (provider.isPlaybackPaused
                        ? _provider.resumePlayback
                        : _provider.pausePlayback)
                    : null,
                onPlaybackStop: provider.isPlayingBack
                    ? () async {
                        await _provider.stopPlayback();
                      }
                    : null,
                body: Focus(
                  focusNode: _keyboardFocusNode,
                  autofocus: true,
                  skipTraversal: true,
                  onKeyEvent: _handleArrowKey,
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (provider.isLabrador) {
                          return _buildLabradorVerticalBoxes(
                              provider, constraints);
                        }
                        final double rowHeight =
                            (constraints.maxHeight / 2).clamp(260.0, 480.0);
                        return constraints.maxWidth < 600
                            ? ListView(
                                children: powerSourceCards,
                              )
                            : GridView(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: rowHeight,
                                ),
                                children: powerSourceCards,
                              );
                      },
                    ),
                  ),
                ),
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.powerSource,
                  content: _getPowerSourceContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }
}
