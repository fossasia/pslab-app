import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
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
  final List<List<int>> _gifFrames = [];
  int _currentGifFrame = 0;
  Timer? _gifPlaybackTimer;

  bool _isRecording = false;
  bool get isRecording => _isRecording;
  final bool _isPlayingBack = false;
  bool get isPlayingBack => _isPlayingBack;

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
      if (isLiveMode && _isDirty && !_isHardwareBusy && _display != null) {
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
    if (_isHardwareBusy || _display == null) return;
    _saveState();
    frameBuffer = List.filled(1024, 0);
    shapePreviewBuffer = List.filled(1024, 0);
    textPreviewBuffer = List.filled(1024, 0);
    _isDirty = true;
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
        case 'triangle':
          _drawTriangle(shapePreviewBuffer, _startX!, _startY!, x, y);
          break;
        case 'hexagon':
          _drawHexagon(shapePreviewBuffer, _startX!, _startY!, radius);
          break;
        case 'star':
          _drawStar(shapePreviewBuffer, _startX!, _startY!, radius);
          break;
      }
      _isDirty = true;
      notifyListeners();
    }
  }

  void handlePanEnd() {
    if (['line', 'rect', 'circle', 'triangle', 'hexagon', 'star']
        .contains(activeTool)) {
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

  void _drawCircle(List<int> buffer, int xc, int yc, int r) {
    int x = 0, y = r;
    int d = 3 - 2 * r;
    while (y >= x) {
      _alterPixel(buffer, xc + x, yc + y, true);
      _alterPixel(buffer, xc - x, yc + y, true);
      _alterPixel(buffer, xc + x, yc - y, true);
      _alterPixel(buffer, xc - x, yc - y, true);
      _alterPixel(buffer, xc + y, yc + x, true);
      _alterPixel(buffer, xc - y, yc + x, true);
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
  }

  void _drawTriangle(List<int> buffer, int x0, int y0, int x1, int y1) {
    int topX = (x0 + x1) ~/ 2;
    _drawLine(buffer, topX, y0, x0, y1, true);
    _drawLine(buffer, x0, y1, x1, y1, true);
    _drawLine(buffer, x1, y1, topX, y0, true);
  }

  void _drawHexagon(List<int> buffer, int xc, int yc, int r) {
    List<math.Point<int>> vertices = [];
    for (int i = 0; i < 6; i++) {
      double angle = 2 * math.pi / 6 * i;
      vertices.add(math.Point((xc + r * math.cos(angle)).round(),
          (yc + r * math.sin(angle)).round()));
    }
    for (int i = 0; i < 6; i++) {
      _drawLine(buffer, vertices[i].x, vertices[i].y, vertices[(i + 1) % 6].x,
          vertices[(i + 1) % 6].y, true);
    }
  }

  void _drawStar(List<int> buffer, int xc, int yc, int r) {
    List<math.Point<int>> vertices = [];
    for (int i = 0; i < 5; i++) {
      double angle = i * 2 * math.pi / 5 - math.pi / 2;
      vertices.add(math.Point((xc + r * math.cos(angle)).round(),
          (yc + r * math.sin(angle)).round()));
    }
    _drawLine(buffer, vertices[0].x, vertices[0].y, vertices[2].x,
        vertices[2].y, true);
    _drawLine(buffer, vertices[2].x, vertices[2].y, vertices[4].x,
        vertices[4].y, true);
    _drawLine(buffer, vertices[4].x, vertices[4].y, vertices[1].x,
        vertices[1].y, true);
    _drawLine(buffer, vertices[1].x, vertices[1].y, vertices[3].x,
        vertices[3].y, true);
    _drawLine(buffer, vertices[3].x, vertices[3].y, vertices[0].x,
        vertices[0].y, true);
  }

  void renderTextToPreview(String text) {
    textPreviewBuffer = List.filled(1024, 0);
    if (text.isEmpty) {
      _isDirty = true;
      notifyListeners();
      return;
    }

    int currentX = 0;
    int page = 0;

    for (int i = 0; i < text.length; i++) {
      if (currentX > 120) {
        currentX = 0;
        page++;
        if (page > 7) break;
      }
      List<int> charBytes = _getCharBytes(text.codeUnitAt(i));
      for (int b = 0; b < 5; b++) {
        textPreviewBuffer[(page * 128) + currentX + b] |= charBytes[b];
      }
      currentX += 6;
    }
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
      img.Image? gifImage = img.decodeGif(fileBytes);

      if (gifImage != null && gifImage.frames.isNotEmpty) {
        _gifFrames.clear();

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
          _gifFrames.add(oledBuffer);
        }

        _currentGifFrame = 0;
        isGifPlaying = true;
        isLiveMode = true;

        _gifPlaybackTimer =
            Timer.periodic(const Duration(milliseconds: 100), (timer) {
          frameBuffer = _gifFrames[_currentGifFrame];
          _isDirty = true;
          notifyListeners();

          _currentGifFrame++;
          if (_currentGifFrame >= _gifFrames.length) _currentGifFrame = 0;
        });
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
    _gifPlaybackTimer?.cancel();
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

  void toggleRecording() {
    _isRecording = !_isRecording;
    notifyListeners();
  }

  List<int> _getCharBytes(int ascii) {
    if (ascii < 32 || ascii > 126) return [0, 0, 0, 0, 0];
    int idx = ascii - 32;
    if (idx >= _font5x8.length) return [0, 0, 0, 0, 0];
    return List<int>.from(_font5x8[idx]);
  }

  static const List<List<int>> _font5x8 = [
    [0x00, 0x00, 0x00, 0x00, 0x00],
    [0x00, 0x00, 0x4f, 0x00, 0x00],
    [0x00, 0x07, 0x00, 0x07, 0x00],
    [0x14, 0x7f, 0x14, 0x7f, 0x14],
    [0x24, 0x2a, 0x7f, 0x2a, 0x12],
    [0x23, 0x13, 0x08, 0x64, 0x62],
    [0x36, 0x49, 0x55, 0x22, 0x50],
    [0x00, 0x05, 0x03, 0x00, 0x00],
    [0x00, 0x1c, 0x22, 0x41, 0x00],
    [0x00, 0x41, 0x22, 0x1c, 0x00],
    [0x14, 0x08, 0x3e, 0x08, 0x14],
    [0x08, 0x08, 0x3e, 0x08, 0x08],
    [0x00, 0x50, 0x30, 0x00, 0x00],
    [0x08, 0x08, 0x08, 0x08, 0x08],
    [0x00, 0x60, 0x60, 0x00, 0x00],
    [0x20, 0x10, 0x08, 0x04, 0x02],
    [0x3e, 0x51, 0x49, 0x45, 0x3e],
    [0x00, 0x42, 0x7f, 0x40, 0x00],
    [0x42, 0x61, 0x51, 0x49, 0x46],
    [0x21, 0x41, 0x45, 0x4b, 0x31],
    [0x18, 0x14, 0x12, 0x7f, 0x10],
    [0x27, 0x45, 0x45, 0x45, 0x39],
    [0x3c, 0x4a, 0x49, 0x49, 0x30],
    [0x01, 0x71, 0x09, 0x05, 0x03],
    [0x36, 0x49, 0x49, 0x49, 0x36],
    [0x06, 0x49, 0x49, 0x29, 0x1e],
    [0x00, 0x36, 0x36, 0x00, 0x00],
    [0x00, 0x56, 0x36, 0x00, 0x00],
    [0x08, 0x14, 0x22, 0x41, 0x00],
    [0x14, 0x14, 0x14, 0x14, 0x14],
    [0x00, 0x41, 0x22, 0x14, 0x08],
    [0x02, 0x01, 0x51, 0x09, 0x06],
    [0x32, 0x49, 0x79, 0x41, 0x3e],
    [0x7e, 0x11, 0x11, 0x11, 0x7e],
    [0x7f, 0x49, 0x49, 0x49, 0x36],
    [0x3e, 0x41, 0x41, 0x41, 0x22],
    [0x7f, 0x41, 0x41, 0x22, 0x1c],
    [0x7f, 0x49, 0x49, 0x49, 0x41],
    [0x7f, 0x09, 0x09, 0x09, 0x01],
    [0x3e, 0x41, 0x49, 0x49, 0x7a],
    [0x7f, 0x08, 0x08, 0x08, 0x7f],
    [0x00, 0x41, 0x7f, 0x41, 0x00],
    [0x20, 0x40, 0x41, 0x3f, 0x01],
    [0x7f, 0x08, 0x14, 0x22, 0x41],
    [0x7f, 0x40, 0x40, 0x40, 0x40],
    [0x7f, 0x02, 0x0c, 0x02, 0x7f],
    [0x7f, 0x04, 0x08, 0x10, 0x7f],
    [0x3e, 0x41, 0x41, 0x41, 0x3e],
    [0x7f, 0x09, 0x09, 0x09, 0x06],
    [0x3e, 0x41, 0x51, 0x21, 0x5e],
    [0x7f, 0x09, 0x19, 0x29, 0x46],
    [0x46, 0x49, 0x49, 0x49, 0x31],
    [0x01, 0x01, 0x7f, 0x01, 0x01],
    [0x3f, 0x40, 0x40, 0x40, 0x3f],
    [0x1f, 0x20, 0x40, 0x20, 0x1f],
    [0x3f, 0x40, 0x38, 0x40, 0x3f],
    [0x63, 0x14, 0x08, 0x14, 0x63],
    [0x07, 0x08, 0x70, 0x08, 0x07],
    [0x61, 0x51, 0x49, 0x45, 0x43],
    [0x00, 0x7f, 0x41, 0x41, 0x00],
    [0x02, 0x04, 0x08, 0x10, 0x20],
    [0x00, 0x41, 0x41, 0x7f, 0x00],
    [0x04, 0x02, 0x01, 0x02, 0x04],
    [0x40, 0x40, 0x40, 0x40, 0x40],
    [0x00, 0x01, 0x02, 0x04, 0x00],
    [0x20, 0x54, 0x54, 0x54, 0x78],
    [0x7f, 0x48, 0x44, 0x44, 0x38],
    [0x38, 0x44, 0x44, 0x44, 0x20],
    [0x38, 0x44, 0x44, 0x48, 0x7f],
    [0x38, 0x54, 0x54, 0x54, 0x18],
    [0x08, 0x7e, 0x09, 0x01, 0x02],
    [0x0c, 0x52, 0x52, 0x52, 0x3e],
    [0x7f, 0x08, 0x04, 0x04, 0x78],
    [0x00, 0x44, 0x7d, 0x40, 0x00],
    [0x20, 0x40, 0x44, 0x3d, 0x00],
    [0x7f, 0x10, 0x28, 0x44, 0x00],
    [0x00, 0x41, 0x7f, 0x40, 0x00],
    [0x7c, 0x04, 0x18, 0x04, 0x78],
    [0x7c, 0x08, 0x04, 0x04, 0x78],
    [0x38, 0x44, 0x44, 0x44, 0x38],
    [0x7c, 0x14, 0x14, 0x14, 0x08],
    [0x08, 0x14, 0x14, 0x18, 0x7c],
    [0x7c, 0x08, 0x04, 0x04, 0x08],
    [0x48, 0x54, 0x54, 0x54, 0x20],
    [0x04, 0x3f, 0x44, 0x40, 0x20],
    [0x3c, 0x40, 0x40, 0x20, 0x7c],
    [0x1c, 0x20, 0x40, 0x20, 0x1c],
    [0x3c, 0x40, 0x30, 0x40, 0x3c],
    [0x44, 0x28, 0x10, 0x28, 0x44],
    [0x0c, 0x50, 0x50, 0x50, 0x3c],
    [0x44, 0x64, 0x54, 0x4c, 0x44],
    [0x00, 0x08, 0x36, 0x41, 0x00],
    [0x00, 0x00, 0x7f, 0x00, 0x00],
    [0x00, 0x41, 0x36, 0x08, 0x00],
    [0x10, 0x08, 0x08, 0x10, 0x08]
  ];

  @override
  void dispose() {
    _streamTimer?.cancel();
    _gifPlaybackTimer?.cancel();
    super.dispose();
  }
}
