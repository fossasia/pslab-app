import 'dart:async';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class CCS811 {
  static const String tag = "CCS811";
  static const int address = 0x5A;

  static const int algResultData = 0x02;
  static const int hwId = 0x20;
  static const int fwBootVersion = 0x23;
  static const int fwAppVersion = 0x24;
  static const int measMode = 0x01;
  static const int hwVersion = 0x21;
  static const int appStart = 0xF4;

  static const int driveMode1Sec = 0x01;

  final I2C i2c;

  CCS811._(this.i2c);

  static Future<CCS811> create(I2C i2c, ScienceLab scienceLab) async {
    final ccs811 = CCS811._(i2c);
    if (scienceLab.isConnected()) {
      await ccs811._initialize();
    }
    return ccs811;
  }

  Future<void> _initialize() async {
    try {
      await _fetchID();
      await _appStart();
      await Future.delayed(const Duration(milliseconds: 100));
      await _disableInterrupt();
      await _setMeasMode();
    } catch (e) {
      logger.e("$tag Error initializing: $e");
      rethrow;
    }
  }

  Future<void> _setMeasMode() async {
    int config = (1 << 2) | (driveMode1Sec << 4);
    await i2c.write(address, [config], measMode);
  }

  Future<void> _disableInterrupt() async {
    int config = (1 << 2) | (3 << 4);
    await i2c.write(address, [config], measMode);
  }

  Future<void> _fetchID() async {
    try {
      List<int> hwIdData = await i2c.readBulk(address, hwId, 1);
      await Future.delayed(const Duration(milliseconds: 20));

      List<int> hwVerData = await i2c.readBulk(address, hwVersion, 1);
      await Future.delayed(const Duration(milliseconds: 20));

      List<int> bootVerData = await i2c.readBulk(address, fwBootVersion, 2);
      await Future.delayed(const Duration(milliseconds: 20));

      List<int> appVerData = await i2c.readBulk(address, fwAppVersion, 2);
      await Future.delayed(const Duration(milliseconds: 20));

      if (hwIdData.isNotEmpty) {
        logger.d("$tag Hardware ID: ${hwIdData[0] & 0xFF}");
      }
      if (hwVerData.isNotEmpty) {
        logger.d("$tag Hardware Version: ${hwVerData[0] & 0xFF}");
      }
      if (bootVerData.length >= 2) {
        logger
            .d("$tag Boot Version: ${(bootVerData[0] << 8) | bootVerData[1]}");
      }
      if (appVerData.length >= 2) {
        logger.d("$tag App Version: ${(appVerData[0] << 8) | appVerData[1]}");
      }
    } catch (e) {
      logger.e("$tag Error fetching IDs: $e");
    }
  }

  Future<void> _appStart() async {
    await i2c.write(address, [], appStart);
  }

  String _decodeError(int error) {
    String e = "";
    if ((error & 1) > 0) e += ", Invalid register address ID";
    if ((error & (1 << 1)) > 0) e += ", Invalid mailbox ID";
    if ((error & (1 << 2)) > 0) e += ", Unsupported mode to MEAS_MODE";
    if ((error & (1 << 3)) > 0) {
      e += ", Resistance measurement max range reached";
    }
    if ((error & (1 << 4)) > 0) e += ", Heater current out of range";
    if ((error & (1 << 5)) > 0) e += ", Heater voltage applied incorrectly";

    return e.isNotEmpty ? "Error: ${e.substring(2)}" : "Unknown error";
  }

  Future<Map<String, int>> getRawData() async {
    try {
      List<int> data = await i2c.readBulk(address, algResultData, 8);
      if (data.length < 8) {
        throw Exception("Expected 8 bytes but got ${data.length}");
      }

      int eCO2 = ((data[0] & 0xFF) << 8) | (data[1] & 0xFF);
      int tvoc = ((data[2] & 0xFF) << 8) | (data[3] & 0xFF);
      int errorId = data[5] & 0xFF;

      if (errorId > 0) {
        logger.e("$tag ${_decodeError(errorId)}");
      }

      return {
        'eCO2': eCO2,
        'TVOC': tvoc,
      };
    } catch (e) {
      logger.e("$tag Error getting raw data: $e");
      rethrow;
    }
  }
}
