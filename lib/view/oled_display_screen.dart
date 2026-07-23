import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/export_helper.dart';
import 'package:pslab/view/widgets/guide_widget.dart';

import '../constants.dart';
import '../providers/oled_display_provider.dart';
import 'logged_data_screen.dart';

import 'widgets/oled_control_panel.dart';

class OledDisplayScreen extends StatefulWidget {
  final List<List<dynamic>>? importedData;

  const OledDisplayScreen({super.key, this.importedData});

  @override
  State<OledDisplayScreen> createState() => _OledDisplayScreenState();
}

class _OledDisplayScreenState extends State<OledDisplayScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  I2C? _i2c;
  ScienceLab? _scienceLab;
  late OledDisplayProvider _provider;

  bool _showGuide = false;
  String _selectedSize = 'SH1106 128x64';
  double _brightnessValue = 50.0;

  static const double _displayWidth = 128;

  @override
  void initState() {
    super.initState();
    _provider = OledDisplayProvider();
    _initializeScienceLab();

    if (widget.importedData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _provider.loadImportedData(widget.importedData!);
      });
    }
  }

  void _initializeScienceLab() async {
    try {
      _scienceLab = getIt.get<ScienceLab>();
      if (_scienceLab != null && _scienceLab!.isConnected()) {
        _i2c = I2C(_scienceLab!.mPacketHandler);
      }
      _provider.initializeDisplay(
        onError: (err) => logger.e(err),
        i2c: _i2c,
        scienceLab: _scienceLab,
        selectedModelString: _selectedSize,
      );
    } catch (e) {
      logger.e('Error initializing ScienceLab: $e');
    }
  }

  void _showOptionsMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width, 0, 0,
          MediaQuery.of(context).size.height),
      items: [
        PopupMenuItem(
            value: 'show_logged_data',
            child: Text(appLocalizations.showLoggedData)),
      ],
      elevation: 8,
    ).then((value) async {
      if (!mounted) return;
      if (value == 'show_logged_data') {
        final List<List<dynamic>>? data = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoggedDataScreen(
              instrumentNames: [
                appLocalizations.oledDisplayTitle.toLowerCase()
              ],
              appBarName: appLocalizations.showLoggedData,
              instrumentIcons: [instrumentIcons[15]],
            ),
          ),
        );
        if (data != null) {
          await _provider.loadImportedData(data);
        }
      }
    });
  }

  void _toggleRecording() async {
    final exportData = _provider.generateExportData();
    await ExportHelper.handleSaveData(
      context: context,
      instrumentName: appLocalizations.oledDisplayTitle.toLowerCase(),
      data: exportData,
    );
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getOledGuideContent() {
    return [
      InstrumentIntroText(text: appLocalizations.oledDisplayIntro),
      const InstrumentImage(imagePath: 'assets/images/oled_display.png'),
      InstrumentIntroText(text: appLocalizations.oledDisplayConnection),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Colors.red;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Stack(
        children: [
          CommonScaffold(
            title: appLocalizations.oledDisplayTitle,
            onOptionsPressed: _showOptionsMenu,
            onGuidePressed: () => setState(() => _showGuide = true),
            onRecordPressed: _toggleRecording,
            isRecording: _provider.isRecording,
            isPlayingBack: _provider.isPlayingBack,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Consumer<OledDisplayProvider>(
                            builder: (context, provider, child) {
                          return Container(
                            margin: const EdgeInsets.only(
                                top: 6, bottom: 6, left: 10, right: 10),
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                            decoration: BoxDecoration(
                              border: Border.all(width: 1.5, color: primaryRed),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!provider.isGameMode) ...[
                                      IconButton(
                                        icon: const Icon(Icons.undo,
                                            color: Colors.black87),
                                        tooltip: appLocalizations.undo,
                                        onPressed: () {
                                          provider.clearPreviews();
                                          provider.undo();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.redo,
                                            color: Colors.black87),
                                        tooltip: appLocalizations.redo,
                                        onPressed: () {
                                          provider.clearPreviews();
                                          provider.redo();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: primaryRed),
                                        tooltip: appLocalizations.clearCanvas,
                                        onPressed: provider.isProcessing
                                            ? null
                                            : () async {
                                                await provider.clearHardware();
                                              },
                                      ),
                                    ],
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: provider.isGameMode
                                            ? primaryRed.withValues(alpha: 0.15)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                            provider.isGameMode
                                                ? Icons.close
                                                : Icons.sports_esports,
                                            color: primaryRed),
                                        tooltip: "Toggle Game Mode",
                                        onPressed: () =>
                                            provider.toggleGameMode(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 380),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        border: Border.all(
                                            color: Colors.black, width: 4),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6,
                                              offset: Offset(0, 3))
                                        ],
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 128 / 64,
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            double dynamicScale =
                                                constraints.maxWidth /
                                                    _displayWidth;

                                            return GestureDetector(
                                              onPanStart: (details) {
                                                int x =
                                                    (details.localPosition.dx /
                                                            dynamicScale)
                                                        .round();
                                                int y =
                                                    (details.localPosition.dy /
                                                            dynamicScale)
                                                        .round();
                                                provider.handlePanStart(x, y);
                                              },
                                              onPanUpdate: (details) {
                                                int x =
                                                    (details.localPosition.dx /
                                                            dynamicScale)
                                                        .round();
                                                int y =
                                                    (details.localPosition.dy /
                                                            dynamicScale)
                                                        .round();
                                                provider.handlePanUpdate(x, y);
                                              },
                                              onPanEnd: (_) =>
                                                  provider.handlePanEnd(),
                                              child:
                                                  Consumer<OledDisplayProvider>(
                                                      builder: (context,
                                                          paintProvider,
                                                          child) {
                                                List<int> mergedBuffer =
                                                    List.filled(1024, 0);
                                                for (int i = 0; i < 1024; i++) {
                                                  mergedBuffer[
                                                      i] = paintProvider
                                                          .frameBuffer[i] |
                                                      paintProvider
                                                              .shapePreviewBuffer[
                                                          i] |
                                                      paintProvider
                                                          .textPreviewBuffer[i];
                                                }
                                                return ClipRect(
                                                  child: CustomPaint(
                                                    painter: OledBufferPainter(
                                                      buffer: mergedBuffer,
                                                      scale: dynamicScale,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const OledControlPanel(),
                                const Spacer(),
                              ],
                            ),
                          );
                        }),
                        Consumer<OledDisplayProvider>(
                            builder: (context, provider, _) {
                          return Positioned(
                            left: 0,
                            right: 0,
                            top: 4,
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                color: Colors.white,
                                child: Text(
                                    provider.isGameMode
                                        ? "Game"
                                        : appLocalizations.canvas,
                                    style: const TextStyle(
                                        color: primaryRed,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 1.5)),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Consumer<OledDisplayProvider>(
                      builder: (context, provider, child) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                              top: 4, bottom: 12, left: 10, right: 10),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1.5, color: primaryRed),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 0),
                                    decoration: BoxDecoration(
                                        border:
                                            Border.all(color: Colors.black26),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedSize,
                                        isDense: true,
                                        icon: const Icon(Icons.arrow_drop_down,
                                            color: primaryRed),
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                        items: [
                                          'SH1106 128x64',
                                          'SSD1306 128x64',
                                          'SSD1306 128x32'
                                        ].map((String value) {
                                          return DropdownMenuItem<String>(
                                              value: value, child: Text(value));
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(
                                                () => _selectedSize = newValue);
                                            provider.changeModel(newValue);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.lightbulb_outline,
                                      size: 20, color: Colors.black54),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: primaryRed,
                                        inactiveTrackColor: Colors.black12,
                                        thumbColor: primaryRed,
                                        trackHeight: 3.0,
                                        thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 6.0),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                                overlayRadius: 14.0),
                                      ),
                                      child: Slider(
                                        value: _brightnessValue,
                                        min: 0,
                                        max: 100,
                                        onChanged: (value) {
                                          setState(
                                              () => _brightnessValue = value);
                                          provider.updateBrightness(value);
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Text('${_brightnessValue.toInt()}%',
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87)),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: provider.isLiveMode,
                                      activeThumbColor: Colors.black,
                                      onChanged: (val) =>
                                          provider.toggleLiveMode(val),
                                    ),
                                  ),
                                  Text(appLocalizations.liveRender,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black87)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: -2,
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              color: Colors.white,
                              child: const Text("CONFIGURE",
                                  style: TextStyle(
                                      color: primaryRed,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      letterSpacing: 1.5)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          if (_showGuide)
            InstrumentOverviewDrawer(
              instrumentName: appLocalizations.oledDisplayTitle,
              content: _getOledGuideContent(),
              onHide: _hideInstrumentGuide,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class OledBufferPainter extends CustomPainter {
  final List<int> buffer;
  final double scale;

  OledBufferPainter({
    required this.buffer,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    List<Offset> points = [];

    for (int y = 0; y < 64; y++) {
      int page = y ~/ 8;
      int bit = y % 8;
      for (int x = 0; x < 128; x++) {
        int index = (page * 128) + x;
        if ((buffer[index] & (1 << bit)) != 0) {
          points.add(
              Offset((x * scale) + (scale / 2), (y * scale) + (scale / 2)));
        }
      }
    }

    final pointPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = scale
      ..strokeCap = StrokeCap.square;

    canvas.drawPoints(PointMode.points, points, pointPaint);
  }

  @override
  bool shouldRepaint(covariant OledBufferPainter oldDelegate) => true;
}