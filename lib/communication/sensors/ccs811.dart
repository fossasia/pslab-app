import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

class CCS811 {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  static const String tag = "CCS811";
  static const int address = 0x5A;

  static const int status = 0x00;
  static const int measMode = 0x01;
  static const int algResultData = 0x02;
  static const int rawData = 0x03;
  static const int envData = 0x05;
  static const int ntc = 0x06;
  static const int thresholds = 0x10;
  static const int baseline = 0x11;
  static const int hwId = 0x20;
  static const int hwVersion = 0x21;
  static const int fwBootVersion = 0x23;
  static const int fwAppVersion = 0x24;
  static const int errorId = 0xE0;
  static const int appStart = 0xF4;
  static const int swReset = 0xFF;

  static const int modeIdle = 0x00;
  static const int mode1s = 0x10;
  static const int mode10s = 0x20;
  static const int mode60s = 0x30;
  static const int mode250ms = 0x40;

  static const String name = "Air Quality CCS811";

  final I2C i2c;

  int _eCO2 = 0;
  int _tVOC = 0;

  CCS811._(this.i2c);

  static Future<CCS811> create(I2C i2c, ScienceLab scienceLab) async {
    final ccs811 = CCS811._(i2c);
    await ccs811._initialize(scienceLab);
    return ccs811;
  }

  Future<void> _initialize(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }

    try {
      int id = await _readRegisterByte(hwId);
      logger.d("CCS811 HW Info ID: 0x${id.toRadixString(16)}");
      if (id != 0x81) {
        throw Exception(
            "CCS811 Hardware ID mismatch. Expected 0x81, got 0x${id.toRadixString(16)}");
      }
    } catch (e) {
      logger.e("Error reading CCS811 HW_ID: $e");
      rethrow;
    }

    try {
      int stat = await _readRegisterByte(status);
      logger.d("CCS811 Status before start: 0x${stat.toRadixString(16)}");

      if ((stat & 0x10) == 0) {
        throw Exception("CCS811: No valid application firmware loaded.");
      }
      await i2c.write(address, [], appStart);
      await Future.delayed(const Duration(milliseconds: 100));

      stat = await _readRegisterByte(status);
      logger.d("CCS811 Status after start: 0x${stat.toRadixString(16)}");

      if ((stat & 0x80) == 0) {
        throw Exception("CCS811: Failed to transition to Application Mode.");
      }
    } catch (e) {
      logger.e("Error starting CCS811 application: $e");
      rethrow;
    }

    await setMode(mode1s);
  }

  Future<void> setMode(int mode) async {
    try {
      await i2c.write(address, [mode], measMode);
      await Future.delayed(const Duration(milliseconds: 20));
      logger.d("CCS811 Mode set to 0x${mode.toRadixString(16)}");
    } catch (e) {
      logger.e("Error setting CCS811 mode: $e");
      rethrow;
    }
  }

  Future<int> _readRegisterByte(int register) async {
    List<int> data = await i2c.readBulk(address, register, 1);
    if (data.isEmpty) {
      throw Exception(
          "Empty response from CCS811 register 0x${register.toRadixString(16)}");
    }
    return data[0];
  }

  Future<Map<String, int>> getRawData() async {
    try {
      int stat = await _readRegisterByte(status);
      if ((stat & 0x08) != 0) {
        List<int> data = await i2c.readBulk(address, algResultData, 8);

        if (data.length >= 4) {
          _eCO2 = ((data[0] & 0xFF) << 8) | (data[1] & 0xFF);
          _tVOC = ((data[2] & 0xFF) << 8) | (data[3] & 0xFF);
        }
      }
      return {
        'eCO2': _eCO2,
        'TVOC': _tVOC,
      };
    } catch (e) {
      logger.e("Error reading CCS811 data: $e");
      rethrow;
    }
  }
}
