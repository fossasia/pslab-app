import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

import '../others/oled_display.dart';
import '../l10n/app_localizations.dart';
import 'locator.dart';

class OledDisplayProvider extends ChangeNotifier {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  static const String lTag = "OLED_Provider";

  OLED? _display;
  I2C? _i2c;
  ScienceLab? _scienceLab;

  bool _isHardwareBusy = false;
  bool get isProcessing => _isHardwareBusy;

  List<int> frameBuffer = List.filled(1024, 0);
  List<int> shapePreviewBuffer = List.filled(1024, 0);
  List<int> textPreviewBuffer = List.filled(1024, 0);

  final List<List<int>> _undoStack = [];
  final List<List<int>> _redoStack = [];

  String activeTool = 'draw';
  int? _startX, _startY;
  int? _lastX, _lastY;

  bool _isDirty = false;
  Timer? _streamTimer;

  bool isLiveMode = true;

  bool isGifPlaying = false;
  List<List<int>> _gifFrames = [];
  int _currentGifFrame = 0;

  final bool _isRecording = false;
  bool get isRecording => _isRecording;
  final bool _isPlayingBack = false;
  bool get isPlayingBack => _isPlayingBack;

  final List<String> _shapeTools = [
    'line',
    'rect',
    'circle',
    'semi_circle',
    'triangle',
    'hexagon',
    'star',
    'ellipse',
    'diamond',
    'pentagon',
    'cross',
    'arrow',
    'check',
    'heart',
    'grid'
  ];

  Future<void> initializeDisplay({
    required Function(String) onError,
    required I2C? i2c,
    required ScienceLab? scienceLab,
    String selectedModelString = 'SH1106 128x64',
  }) async {
    try {
      _i2c = i2c;
      _scienceLab = scienceLab;

      if (_i2c == null || _scienceLab == null || !_scienceLab!.isConnected()) {
        onError(appLocalizations.pslabNotConnected);
        return;
      }

      await changeModel(selectedModelString);
      _startLiveStream();
    } catch (e) {
      logger.e("[$lTag] Initialization error: $e");
    }
  }

  List<List<dynamic>> generateExportData() {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final bufferHex =
        frameBuffer.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return [
      ['Timestamp', 'DateTime', 'FrameBufferHex'],
      [now.millisecondsSinceEpoch.toString(), dateFormat.format(now), bufferHex]
    ];
  }

  Future<void> loadImportedData(List<List<dynamic>> data) async {
    try {
      String? foundHex;
      for (var row in data) {
        for (var cell in row) {
          String cellStr = cell.toString();
          if (cellStr.length == 2048) {
            foundHex = cellStr;
            break;
          }
        }
        if (foundHex != null) break;
      }

      if (foundHex != null) {
        _saveState();
        List<int> loadedBuffer = List.filled(1024, 0);
        for (int i = 0; i < 1024; i++) {
          loadedBuffer[i] =
              int.parse(foundHex.substring(i * 2, i * 2 + 2), radix: 16);
        }
        frameBuffer = loadedBuffer;
        _isDirty = true;
        notifyListeners();

        logger.d("[$lTag] Successfully loaded canvas data!");
        if (isLiveMode) await syncManual();
      } else {
        logger.e(
            "[$lTag] Error: No valid 2048-char hex string found in the CSV data.");
      }
    } catch (e) {
      logger.e("[$lTag] Error parsing imported OLED data: $e");
    }
  }

  Future<void> changeModel(String selectedModelString) async {
    if (_i2c == null || _scienceLab == null) return;

    _isHardwareBusy = true;
    notifyListeners();

    OledModel model = OledModel.sh1106_128x64;
    if (selectedModelString.contains('SSD1306 128x32')) {
      model = OledModel.ssd1306_128x32;
    } else if (selectedModelString.contains('SSD1306 128x64')) {
      model = OledModel.ssd1306_128x64;
    }

    try {
      _display = await OLED.create(_i2c!, _scienceLab!, model);
      _isDirty = true;
    } catch (e) {
      logger.e("[$lTag] Failed to change model: $e");
    } finally {
      _isHardwareBusy = false;
      notifyListeners();
    }
  }

  void toggleLiveMode(bool value) {
    isLiveMode = value;
    notifyListeners();
    if (isLiveMode && _isDirty) syncManual();
  }

  void _startLiveStream() {
    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (isLiveMode &&
          _isDirty &&
          !_isHardwareBusy &&
          !isGifPlaying &&
          _display != null) {
        await _flushBufferToHardware();
      }
    });
  }

  Future<void> syncManual() async {
    if (_isHardwareBusy || _display == null) return;
    await _flushBufferToHardware();
  }

  Future<void> _flushBufferToHardware() async {
    _isHardwareBusy = true;
    _isDirty = false;
    notifyListeners();

    try {
      List<int> merged = List.filled(1024, 0);
      for (int i = 0; i < 1024; i++) {
        merged[i] =
            frameBuffer[i] | shapePreviewBuffer[i] | textPreviewBuffer[i];
      }
      await _display!.sendFrameBuffer(merged);
    } catch (e) {
      _isDirty = true;
    } finally {
      _isHardwareBusy = false;
      notifyListeners();
    }
  }

  Future<void> clearHardware() async {
    if (_isHardwareBusy) return;

    _saveState();
    frameBuffer = List.filled(1024, 0);
    shapePreviewBuffer = List.filled(1024, 0);
    textPreviewBuffer = List.filled(1024, 0);
    _isDirty = true;
    notifyListeners();

    if (_display == null) return;

    _isHardwareBusy = true;
    notifyListeners();

    try {
      await _display!.clearDisplay();
      _isDirty = false;
    } catch (e) {
      logger.e("[$lTag] Clear error: $e");
    } finally {
      _isHardwareBusy = false;
      notifyListeners();
    }
  }

  void _saveState() {
    _undoStack.add(List.from(frameBuffer));
    if (_undoStack.length > 20) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.from(frameBuffer));
    frameBuffer = List.from(_undoStack.removeLast());
    _isDirty = true;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.from(frameBuffer));
    frameBuffer = List.from(_redoStack.removeLast());
    _isDirty = true;
    notifyListeners();
  }

  void clearPreviews() {
    shapePreviewBuffer = List.filled(1024, 0);
    textPreviewBuffer = List.filled(1024, 0);
    _isDirty = true;
    notifyListeners();
  }

  void setTool(String tool) {
    activeTool = tool;
    notifyListeners();
  }

  void handlePanStart(int x, int y) {
    _saveState();
    _startX = x;
    _startY = y;
    _lastX = x;
    _lastY = y;
    if (activeTool == 'draw' || activeTool == 'erase') {
      _alterPixel(frameBuffer, x, y, activeTool == 'draw');
    }
  }

  void handlePanUpdate(int x, int y) {
    if (_startX == null || _startY == null) return;

    if (activeTool == 'draw' || activeTool == 'erase') {
      _drawLine(frameBuffer, _lastX!, _lastY!, x, y, activeTool == 'draw');
      _lastX = x;
      _lastY = y;
    } else {
      shapePreviewBuffer = List.filled(1024, 0);
      int radius = math
          .sqrt(math.pow(x - _startX!, 2) + math.pow(y - _startY!, 2))
          .round();

      switch (activeTool) {
        case 'line':
          _drawLine(shapePreviewBuffer, _startX!, _startY!, x, y, true);
          break;
        case 'rect':
          _drawRect(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
        case 'circle':
          _drawCircle(shapePreviewBuffer, _startX!, _startY!, radius);
          break;
        case 'semi_circle':
          _drawCircle(shapePreviewBuffer, _startX!, _startY!, radius,
              semi: true);
          break;
        case 'triangle':
          _drawTriangle(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
        case 'hexagon':
          _drawPolygon(shapePreviewBuffer, _startX!, _startY!, radius, 6);
          break;
        case 'pentagon':
          _drawPolygon(shapePreviewBuffer, _startX!, _startY!, radius, 5);
          break;
        case 'star':
          _drawStar(shapePreviewBuffer, _startX!, _startY!, radius);
          break;
        case 'ellipse':
          _drawEllipse(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
        case 'diamond':
          _drawDiamond(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
        case 'cross':
          _drawCross(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
        case 'arrow':
          _drawArrow(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
        case 'check':
          _drawCheck(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
        case 'heart':
          _drawHeart(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
        case 'grid':
          _drawGrid(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
      }
      _isDirty = true;
      notifyListeners();
    }
  }

  void handlePanEnd() {
    if (_shapeTools.contains(activeTool)) {
      for (int i = 0; i < 1024; i++) {
        frameBuffer[i] |= shapePreviewBuffer[i];
      }
      shapePreviewBuffer = List.filled(1024, 0);
      _isDirty = true;
      notifyListeners();
    }
    _startX = null;
    _startY = null;
  }

  void _alterPixel(List<int> buffer, int x, int y, bool isDraw) {
    if (x < 0 || x >= 128 || y < 0 || y >= 64) return;
    int index = ((y ~/ 8) * 128) + x;
    int bit = y % 8;
    if (isDraw) {
      buffer[index] |= (1 << bit);
    } else {
      buffer[index] &= ~(1 << bit);
    }
    _isDirty = true;
    notifyListeners();
  }

  void _drawLine(
      List<int> buffer, int x0, int y0, int x1, int y1, bool isDraw) {
    int dx = (x1 - x0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int dy = -(y1 - y0).abs();
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    while (true) {
      _alterPixel(buffer, x0, y0, isDraw);
      if (x0 == x1 && y0 == y1) break;
      int e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }
    }
  }

  void _drawRect(List<int> buffer, int x0, int y0, int x1, int y1) {
    _drawLine(buffer, x0, y0, x1, y0, true);
    _drawLine(buffer, x1, y0, x1, y1, true);
    _drawLine(buffer, x1, y1, x0, y1, true);
    _drawLine(buffer, x0, y1, x0, y0, true);
  }

  void _drawCircle(List<int> buffer, int xc, int yc, int r,
      {bool semi = false}) {
    int x = 0, y = r;
    int d = 3 - 2 * r;
    while (y >= x) {
      if (!semi) {
        _alterPixel(buffer, xc + x, yc + y, true);
        _alterPixel(buffer, xc - x, yc + y, true);
        _alterPixel(buffer, xc + y, yc + x, true);
        _alterPixel(buffer, xc - y, yc + x, true);
      }
      _alterPixel(buffer, xc + x, yc - y, true);
      _alterPixel(buffer, xc - x, yc - y, true);
      _alterPixel(buffer, xc + y, yc - x, true);
      _alterPixel(buffer, xc - y, yc - x, true);
      x++;
      if (d > 0) {
        y--;
        d = d + 4 * (x - y) + 10;
      } else {
        d = d + 4 * x + 6;
      }
    }
    if (semi) {
      _drawLine(buffer, xc - r, yc, xc + r, yc, true);
    }
  }

  void _drawEllipse(List<int> buffer, int x1, int y1, int x2, int y2) {
    int a = (x2 - x1).abs() ~/ 2;
    int b = (y2 - y1).abs() ~/ 2;
    int xc = x1 + (x2 - x1) ~/ 2;
    int yc = y1 + (y2 - y1) ~/ 2;
    List<math.Point<int>> pts = [];
    for (int i = 0; i < 32; i++) {
      double angle = 2 * math.pi * i / 32;
      pts.add(math.Point((xc + a * math.cos(angle)).round(),
          (yc + b * math.sin(angle)).round()));
    }
    for (int i = 0; i < 32; i++) {
      _drawLine(buffer, pts[i].x, pts[i].y, pts[(i + 1) % 32].x,
          pts[(i + 1) % 32].y, true);
    }
  }

  void _drawTriangle(List<int> buffer, int x0, int y0, int x1, int y1) {
    int topX = (x0 + x1) ~/ 2;
    _drawLine(buffer, topX, y0, x0, y1, true);
    _drawLine(buffer, x0, y1, x1, y1, true);
    _drawLine(buffer, x1, y1, topX, y0, true);
  }

  void _drawPolygon(List<int> buffer, int xc, int yc, int r, int sides) {
    List<math.Point<int>> pts = [];
    for (int i = 0; i < sides; i++) {
      double angle = -math.pi / 2 + (i * 2 * math.pi / sides);
      pts.add(math.Point((xc + r * math.cos(angle)).round(),
          (yc + r * math.sin(angle)).round()));
    }
    for (int i = 0; i < sides; i++) {
      _drawLine(buffer, pts[i].x, pts[i].y, pts[(i + 1) % sides].x,
          pts[(i + 1) % sides].y, true);
    }
  }

  void _drawStar(List<int> buffer, int xc, int yc, int r) {
    List<math.Point<int>> pts = [];
    for (int i = 0; i < 5; i++) {
      double angle = i * 2 * math.pi / 5 - math.pi / 2;
      pts.add(math.Point((xc + r * math.cos(angle)).round(),
          (yc + r * math.sin(angle)).round()));
    }
    _drawLine(buffer, pts[0].x, pts[0].y, pts[2].x, pts[2].y, true);
    _drawLine(buffer, pts[2].x, pts[2].y, pts[4].x, pts[4].y, true);
    _drawLine(buffer, pts[4].x, pts[4].y, pts[1].x, pts[1].y, true);
    _drawLine(buffer, pts[1].x, pts[1].y, pts[3].x, pts[3].y, true);
    _drawLine(buffer, pts[3].x, pts[3].y, pts[0].x, pts[0].y, true);
  }

  void _drawDiamond(List<int> buffer, int x1, int y1, int x2, int y2) {
    int midX = (x1 + x2) ~/ 2;
    int midY = (y1 + y2) ~/ 2;
    _drawLine(buffer, midX, y1, x2, midY, true);
    _drawLine(buffer, x2, midY, midX, y2, true);
    _drawLine(buffer, midX, y2, x1, midY, true);
    _drawLine(buffer, x1, midY, midX, y1, true);
  }

  void _drawCross(List<int> buffer, int x1, int y1, int x2, int y2) {
    int midX = (x1 + x2) ~/ 2;
    int midY = (y1 + y2) ~/ 2;
    _drawLine(buffer, midX, y1, midX, y2, true);
    _drawLine(buffer, x1, midY, x2, midY, true);
  }

  void _drawArrow(List<int> buffer, int x1, int y1, int x2, int y2) {
    _drawLine(buffer, x1, y1, x2, y2, true);
    double angle = math.atan2(y2 - y1, x2 - x1);
    int headlen = 10;
    _drawLine(
        buffer,
        x2,
        y2,
        (x2 - headlen * math.cos(angle - math.pi / 6)).round(),
        (y2 - headlen * math.sin(angle - math.pi / 6)).round(),
        true);
    _drawLine(
        buffer,
        x2,
        y2,
        (x2 - headlen * math.cos(angle + math.pi / 6)).round(),
        (y2 - headlen * math.sin(angle + math.pi / 6)).round(),
        true);
  }

  void _drawCheck(List<int> buffer, int x1, int y1, int x2, int y2) {
    int midX = x1 + (x2 - x1) ~/ 3;
    int midY = math.max(y1, y2);
    _drawLine(buffer, x1, y1 + (y2 - y1) ~/ 2, midX, midY, true);
    _drawLine(buffer, midX, midY, x2, math.min(y1, y2), true);
  }

  void _drawGrid(List<int> buffer, int x1, int y1, int x2, int y2) {
    int left = math.min(x1, x2);
    int right = math.max(x1, x2);
    int top = math.min(y1, y2);
    int bottom = math.max(y1, y2);
    int steps = 4;
    for (int i = 0; i <= steps; i++) {
      int x = left + (right - left) * i ~/ steps;
      _drawLine(buffer, x, top, x, bottom, true);
      int y = top + (bottom - top) * i ~/ steps;
      _drawLine(buffer, left, y, right, y, true);
    }
  }

  void _drawHeart(List<int> buffer, int x1, int y1, int x2, int y2) {
    int cx = x1 + (x2 - x1) ~/ 2;
    int cy = y1 + (y2 - y1) ~/ 2;
    int w = (x2 - x1).abs();
    int h = (y2 - y1).abs();
    List<math.Point<int>> pts = [];
    for (int i = 0; i < 32; i++) {
      double t = i * 2 * math.pi / 32;
      num hx = 16 * math.pow(math.sin(t), 3);
      double hy = -(13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t));
      pts.add(
          math.Point((cx + hx * w / 32).round(), (cy + hy * h / 32).round()));
    }
    for (int i = 0; i < 32; i++) {
      _drawLine(buffer, pts[i].x, pts[i].y, pts[(i + 1) % 32].x,
          pts[(i + 1) % 32].y, true);
    }
  }

  Future<void> renderTextToPreview(String text) async {
    if (text.isEmpty) {
      textPreviewBuffer = List.filled(1024, 0);
      _isDirty = true;
      notifyListeners();
      return;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 64));

    final paint = Paint()..color = Colors.black;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 64), paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.0,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout(maxWidth: 128);
    textPainter.paint(canvas, const Offset(0, 0));

    final picture = recorder.endRecording();
    final image = await picture.toImage(128, 64);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) return;

    List<int> newBuffer = List.filled(1024, 0);
    for (int y = 0; y < 64; y++) {
      for (int x = 0; x < 128; x++) {
        int offset = (y * 128 + x) * 4;
        int r = byteData.getUint8(offset);
        if (r > 127) {
          newBuffer[((y ~/ 8) * 128) + x] |= (1 << (y % 8));
        }
      }
    }

    textPreviewBuffer = newBuffer;
    _isDirty = true;
    notifyListeners();
  }

  void renderTextToCanvas(String text) {
    if (text.isEmpty) return;
    _saveState();

    for (int i = 0; i < 1024; i++) {
      frameBuffer[i] |= textPreviewBuffer[i];
    }
    textPreviewBuffer = List.filled(1024, 0);
    _isDirty = true;
    notifyListeners();
  }

  static List<List<int>> _decodeAndProcessGif(Uint8List fileBytes) {
    img.Image? gifImage = img.decodeGif(fileBytes);
    List<List<int>> frames = [];
    if (gifImage != null && gifImage.frames.isNotEmpty) {
      for (img.Image frame in gifImage.frames) {
        img.Image resized = img.copyResize(frame, width: 128, height: 64);
        List<int> oledBuffer = List.filled(1024, 0);
        for (int y = 0; y < 64; y++) {
          for (int x = 0; x < 128; x++) {
            img.Pixel p = resized.getPixel(x, y);
            num luminance = p.r * 0.299 + p.g * 0.587 + p.b * 0.114;
            if (luminance > 128) {
              oledBuffer[((y ~/ 8) * 128) + x] |= (1 << (y % 8));
            }
          }
        }
        frames.add(oledBuffer);
      }
    }
    return frames;
  }

  Future<void> _playGifLoop() async {
    while (isGifPlaying) {
      DateTime startTime = DateTime.now();

      frameBuffer = _gifFrames[_currentGifFrame];
      _isDirty = true;
      notifyListeners();

      await _flushBufferToHardware();

      if (!isGifPlaying) break;

      _currentGifFrame++;
      if (_currentGifFrame >= _gifFrames.length) _currentGifFrame = 0;

      int elapsed = DateTime.now().difference(startTime).inMilliseconds;
      int remaining = 100 - elapsed;

      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      } else {
        await Future.delayed(Duration.zero);
      }
    }
  }

  Future<void> pickAndPlayGif() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      stopGif();
      _isHardwareBusy = true;
      notifyListeners();

      Uint8List fileBytes = await pickedFile.readAsBytes();
      _gifFrames = await compute(_decodeAndProcessGif, fileBytes);

      if (_gifFrames.isNotEmpty) {
        _currentGifFrame = 0;
        isGifPlaying = true;
        isLiveMode = true;
        _playGifLoop();
      }
    } catch (e) {
      logger.e("[$lTag] Error parsing GIF: $e");
    } finally {
      _isHardwareBusy = false;
      notifyListeners();
    }
  }

  void stopGif() {
    if (!isGifPlaying) return;
    isGifPlaying = false;
    notifyListeners();
  }

  Future<void> updateBrightness(double percentage) async {
    if (_display == null) return;
    int contrast = (percentage * 2.55).toInt();
    try {
      await _display!.i2c.write(0x3C, [0x81, contrast], 0x00);
    } catch (e) {
      logger.e("[$lTag] Brightness fail: $e");
    }
  }

  void clearLocalCanvas() {
    _saveState();
    frameBuffer = List.filled(1024, 0);
    shapePreviewBuffer = List.filled(1024, 0);
    textPreviewBuffer = List.filled(1024, 0);
    _isDirty = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    isGifPlaying = false;
    super.dispose();
  }
}
