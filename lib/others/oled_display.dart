import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

enum OledModel {
  sh1106_128x64,
  ssd1306_128x64,
  ssd1306_128x32,
}

class OLED {
  static const String tag = "OLED_Hardware";
  static const int address = 0x3C;

  static const int _commandMode = 0x00;
  static const int _dataMode = 0x40;

  final I2C i2c;
  final OledModel model;

  late final int _pages;
  late final int _columnOffset;

  List<int> _lastBuffer = List.filled(1024, -1);

  bool _isBusy = false;

  OLED._(this.i2c, this.model) {
    _pages = (model == OledModel.ssd1306_128x32) ? 4 : 8;
    _columnOffset = (model == OledModel.sh1106_128x64) ? 2 : 0;
  }

  static Future<OLED> create(
      I2C i2c, ScienceLab scienceLab, OledModel model) async {
    final display = OLED._(i2c, model);
    await display._initialize(scienceLab);
    return display;
  }

  Future<void> _initialize(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) throw Exception("ScienceLab device absent");

    try {
      await i2c.config(400000);

      List<int> initSequence = [
        0xAE,
        0xD5,
        0x80,
        0xA8,
        _pages == 4 ? 0x1F : 0x3F,
        0xD3,
        0x00,
        0x40,
      ];

      if (model == OledModel.sh1106_128x64) {
        initSequence.addAll([0xAD, 0x8B]);
      } else {
        initSequence.addAll([0x8D, 0x14]);
      }

      initSequence.addAll([
        0x20,
        0x02,
        0xA1,
        0xC8,
        0xDA,
        _pages == 4 ? 0x02 : 0x12,
        0x81,
        0x7F,
        0xD9,
        model == OledModel.sh1106_128x64 ? 0x1F : 0xF1,
        0xDB,
        0x40,
        0xA4,
        0xA6,
        0xAF
      ]);

      for (int cmd in initSequence) {
        await i2c.write(address, [cmd], _commandMode);
      }

      await Future.delayed(const Duration(milliseconds: 50));
      await clearDisplay();
    } catch (e) {
      logger.e("[$tag] Fatal initialization error: $e");
      rethrow;
    }
  }

  Future<void> _setPosition(int column, int page) async {
    int physicalColumn = column + _columnOffset;
    await i2c.write(address, [0xB0 + page], _commandMode);
    await i2c.write(address, [physicalColumn & 0x0F], _commandMode);
    await i2c.write(address, [0x10 | (physicalColumn >> 4)], _commandMode);
  }

  Future<void> clearDisplay() async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      for (int page = 0; page < _pages; page++) {
        await _setPosition(0, page);

        await i2c.write(address, List.filled(128, 0x00), _dataMode);
      }

      _lastBuffer = List.filled(1024, 0);
    } catch (e) {
      logger.e("[$tag] Error during clearDisplay: $e");
    } finally {
      _isBusy = false;
    }
  }

  Future<void> sendFrameBuffer(List<int> buffer) async {
    if (buffer.length != 1024) return;

    if (_isBusy) return;
    _isBusy = true;

    try {
      for (int page = 0; page < _pages; page++) {
        int startIdx = page * 128;
        int firstCol = -1;
        int lastCol = -1;

        for (int i = 0; i < 128; i++) {
          if (buffer[startIdx + i] != _lastBuffer[startIdx + i]) {
            if (firstCol == -1) firstCol = i;
            lastCol = i;
          }
        }

        if (firstCol != -1) {
          int length = lastCol - firstCol + 1;

          try {
            await _setPosition(firstCol, page);

            List<int> bytes = buffer.sublist(
                startIdx + firstCol, startIdx + firstCol + length);
            await i2c.write(address, bytes, _dataMode);
          } catch (e) {
            _lastBuffer = List.filled(1024, -1);
            _isBusy = false;
            return;
          }

          for (int i = firstCol; i <= lastCol; i++) {
            _lastBuffer[startIdx + i] = buffer[startIdx + i];
          }
        }
      }
    } catch (e) {
      _lastBuffer = List.filled(1024, -1);
    } finally {
      _isBusy = false;
    }
  }
}
