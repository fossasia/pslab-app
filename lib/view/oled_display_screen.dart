import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';

import '../providers/oled_display_provider.dart';

class OledDisplayScreen extends StatefulWidget {
  const OledDisplayScreen({super.key});

  @override
  State<OledDisplayScreen> createState() => _OledDisplayScreenState();
}

class _OledDisplayScreenState extends State<OledDisplayScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  I2C? _i2c;
  ScienceLab? _scienceLab;
  late OledDisplayProvider _provider;
  final TextEditingController _textController = TextEditingController();

  bool _showGuide = false;
  String _selectedSize = 'SH1106 128x64';
  double _brightnessValue = 50.0;

  static const double _canvasScale = 2.8;
  static const double _displayWidth = 128;
  static const double _displayHeight = 64;

  @override
  void initState() {
    super.initState();
    _initializeScienceLab();
  }

  void _initializeScienceLab() async {
    try {
      _scienceLab = getIt.get<ScienceLab>();
      if (_scienceLab != null && _scienceLab!.isConnected()) {
        _i2c = I2C(_scienceLab!.mPacketHandler);
      }
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
    );
  }

  void _toggleRecording() {
    _provider.toggleRecording();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_provider.isRecording
            ? 'Recording Started...'
            : 'Recording Stopped.'),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getOledGuideContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.oledDisplayIntro,
      ),
      const InstrumentImage(
        imagePath: 'assets/images/oled_display.png',
      ),
      InstrumentIntroText(
        text: appLocalizations.oledDisplayConnection,
      ),
    ];
  }

  Widget _buildToolButton(IconData icon, String toolId, Color primaryColor,
      OledDisplayProvider provider,
      {String? tooltip}) {
    final isSelected = provider.activeTool == toolId;
    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: isSelected ? primaryColor : Colors.black54,
        style: IconButton.styleFrom(
          backgroundColor: isSelected
              ? primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => provider.setTool(toolId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    const Color primaryRed = Colors.red;

    return ChangeNotifierProvider(
      create: (context) {
        _provider = OledDisplayProvider()
          ..initializeDisplay(
            onError: (err) => logger.e(err),
            i2c: _i2c,
            scienceLab: _scienceLab,
            selectedModelString: _selectedSize,
          );
        return _provider;
      },
      child: Consumer<OledDisplayProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              CommonScaffold(
                title: appLocalizations.oledDisplayTitle,
                onOptionsPressed: _showOptionsMenu,
                onGuidePressed: () => setState(() => _showGuide = true),
                onRecordPressed: _toggleRecording,
                isRecording: provider.isRecording,
                isPlayingBack: provider.isPlayingBack,
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 78,
                        child: Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                  top: 4, bottom: 6, left: 10, right: 10),
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(width: 1.5, color: primaryRed),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.undo,
                                            color: Colors.black87),
                                        tooltip: 'Undo',
                                        onPressed: () {
                                          _textController.clear();
                                          provider.clearPreviews();
                                          provider.undo();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.redo,
                                            color: Colors.black87),
                                        tooltip: 'Redo',
                                        onPressed: () {
                                          _textController.clear();
                                          provider.clearPreviews();
                                          provider.redo();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: primaryRed),
                                        tooltip: 'Clear Canvas & OLED',
                                        onPressed: provider.isProcessing
                                            ? null
                                            : () async {
                                                _textController.clear();
                                                await provider.clearHardware();
                                              },
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Center(
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
                                      width: _displayWidth * _canvasScale,
                                      height: _displayHeight * _canvasScale,
                                      child: GestureDetector(
                                        onPanStart: (details) {
                                          int x = (details.localPosition.dx /
                                                  _canvasScale)
                                              .round();
                                          int y = (details.localPosition.dy /
                                                  _canvasScale)
                                              .round();
                                          provider.handlePanStart(x, y);
                                        },
                                        onPanUpdate: (details) {
                                          int x = (details.localPosition.dx /
                                                  _canvasScale)
                                              .round();
                                          int y = (details.localPosition.dy /
                                                  _canvasScale)
                                              .round();
                                          provider.handlePanUpdate(x, y);
                                        },
                                        onPanEnd: (_) =>
                                            provider.handlePanEnd(),
                                        child: CustomPaint(
                                          painter: OledBufferPainter(
                                            baseBuffer: provider.frameBuffer,
                                            shapeBuffer:
                                                provider.shapePreviewBuffer,
                                            textBuffer:
                                                provider.textPreviewBuffer,
                                            scale: _canvasScale,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextField(
                                    controller: _textController,
                                    enabled: !provider.isGifPlaying,
                                    cursorColor: primaryRed,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 15),
                                    onChanged: (val) {
                                      provider.renderTextToPreview(val);
                                    },
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                      filled: true,
                                      fillColor: provider.isGifPlaying
                                          ? Colors.grey[200]
                                          : Colors.white,
                                      prefixIcon: const Icon(Icons.text_fields,
                                          color: Colors.black54),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.send_rounded,
                                                color: provider.isGifPlaying
                                                    ? Colors.black26
                                                    : primaryRed,
                                                size: 24),
                                            onPressed: provider.isGifPlaying
                                                ? null
                                                : () async {
                                                    final text =
                                                        _textController.text;
                                                    if (text.isNotEmpty) {
                                                      provider
                                                          .renderTextToCanvas(
                                                              text);
                                                      _textController.clear();
                                                    }
                                                    FocusScope.of(context)
                                                        .unfocus();

                                                    if (!provider.isLiveMode) {
                                                      await provider
                                                          .syncManual();
                                                    }
                                                  },
                                            tooltip: provider.isLiveMode
                                                ? 'Stamp Text'
                                                : 'Stamp & Sync OLED',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                provider.isGifPlaying
                                                    ? Icons.stop_circle_outlined
                                                    : Icons.gif_box_rounded,
                                                color: provider.isGifPlaying
                                                    ? primaryRed
                                                    : Colors.black54,
                                                size: 30),
                                            onPressed: (provider.isProcessing &&
                                                    !provider.isGifPlaying)
                                                ? null
                                                : () {
                                                    if (provider.isGifPlaying) {
                                                      provider.stopGif();
                                                    } else {
                                                      provider.pickAndPlayGif();
                                                    }
                                                  },
                                            tooltip: provider.isGifPlaying
                                                ? 'Stop GIF'
                                                : 'Upload GIF',
                                          ),
                                        ],
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.black38, width: 1.2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: primaryRed, width: 2),
                                      ),
                                      hintText: provider.isGifPlaying
                                          ? 'GIF Playing...'
                                          : 'Type and press send icon to stamp...',
                                      hintStyle: const TextStyle(
                                          color: Colors.black38, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildToolButton(Icons.edit, 'draw',
                                              primaryRed, provider,
                                              tooltip: 'Pencil'),
                                          _buildToolButton(
                                              Icons.horizontal_rule,
                                              'line',
                                              primaryRed,
                                              provider,
                                              tooltip: 'Line'),
                                          _buildToolButton(Icons.crop_square,
                                              'rect', primaryRed, provider,
                                              tooltip: 'Rectangle'),
                                          _buildToolButton(
                                              Icons.circle_outlined,
                                              'circle',
                                              primaryRed,
                                              provider,
                                              tooltip: 'Circle'),
                                          _buildToolButton(Icons.change_history,
                                              'triangle', primaryRed, provider,
                                              tooltip: 'Triangle'),
                                          _buildToolButton(
                                              Icons.hexagon_outlined,
                                              'hexagon',
                                              primaryRed,
                                              provider,
                                              tooltip: 'Hexagon'),
                                          _buildToolButton(Icons.star_border,
                                              'star', primaryRed, provider,
                                              tooltip: 'Star'),
                                          Container(
                                              height: 28,
                                              width: 1.5,
                                              color: Colors.black26,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4)),
                                          _buildToolButton(
                                              Icons.cleaning_services_rounded,
                                              'erase',
                                              primaryRed,
                                              provider,
                                              tooltip: 'Eraser'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 4,
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  color: scaffoldBgColor,
                                  child: const Text('CANVAS',
                                      style: TextStyle(
                                          color: primaryRed,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1.2)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 22,
                        child: Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                  top: 6, bottom: 12, left: 10, right: 10),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(width: 1.5, color: primaryRed),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 0),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black26),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedSize,
                                            isDense: true,
                                            icon: const Icon(
                                                Icons.arrow_drop_down,
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
                                                  value: value,
                                                  child: Text(value));
                                            }).toList(),
                                            onChanged: (newValue) {
                                              if (newValue != null) {
                                                setState(() =>
                                                    _selectedSize = newValue);
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
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            activeTrackColor: primaryRed,
                                            inactiveTrackColor: Colors.black12,
                                            thumbColor: primaryRed,
                                            trackHeight: 3.0,
                                            thumbShape:
                                                const RoundSliderThumbShape(
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
                                              setState(() =>
                                                  _brightnessValue = value);
                                              provider.updateBrightness(value);
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 32,
                                        child: Text(
                                            '${_brightnessValue.toInt()}%',
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
                                      const Text("Live Render",
                                          style: TextStyle(
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
                                  color: scaffoldBgColor,
                                  child: const Text('CONFIGURE',
                                      style: TextStyle(
                                          color: primaryRed,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1.2)),
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
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.oledDisplayTitle,
                  content: _getOledGuideContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class OledBufferPainter extends CustomPainter {
  final List<int> baseBuffer;
  final List<int> shapeBuffer;
  final List<int> textBuffer;
  final double scale;
  final Paint _pixelPaint;

  OledBufferPainter({
    required this.baseBuffer,
    required this.shapeBuffer,
    required this.textBuffer,
    required this.scale,
  }) : _pixelPaint = Paint()..color = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    for (int y = 0; y < 64; y++) {
      int page = y ~/ 8;
      int bit = y % 8;
      for (int x = 0; x < 128; x++) {
        int index = (page * 128) + x;
        if (((baseBuffer[index] | shapeBuffer[index] | textBuffer[index]) &
                (1 << bit)) !=
            0) {
          canvas.drawRect(
              Rect.fromLTWH(x * scale, y * scale, scale, scale), _pixelPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant OledBufferPainter oldDelegate) => true;
}
