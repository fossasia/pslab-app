import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

class MAX30102 {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  static const String tag = "MAX30102";

  static const int address = 0x57;

  static const int intStatus1 = 0x00;
  static const int intStatus2 = 0x01;
  static const int intEnable1 = 0x02;
  static const int intEnable2 = 0x03;
  static const int fifoWritePtr = 0x04;
  static const int overflowCounter = 0x05;
  static const int fifoReadPtr = 0x06;
  static const int fifoData = 0x07;
  static const int fifoConfig = 0x08;
  static const int modeConfig = 0x09;
  static const int spo2Config = 0x0A;
  static const int led1Pa = 0x0C;
  static const int led2Pa = 0x0D;

  static const int numPlots = 2;
  static const List<String> plotNames = ["Red Absorptance", "IR Absorptance"];

  final I2C i2c;
  int redValue = 0;
  int irValue = 0;

  MAX30102._(this.i2c);

  static Future<MAX30102> create(I2C i2c, ScienceLab scienceLab) async {
    final max30102 = MAX30102._(i2c);
    await max30102._initializeSensor(scienceLab);
    return max30102;
  }

  Future<void> _initializeSensor(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }

    try {
      await i2c.write(address, [0x40], modeConfig);
      await Future.delayed(const Duration(milliseconds: 100));

      await i2c.write(address, [0x03], modeConfig);

      await i2c.write(address, [0x27], spo2Config);

      await i2c.write(address, [0x24], led1Pa);
      await i2c.write(address, [0x24], led2Pa);

      logger.d("MAX30102 Initialized successfully");
    } catch (e) {
      logger.e("Error initializing MAX30102 sensor registers: $e");
      rethrow;
    }
  }

  Future<void> readRawFifo() async {
    try {
      List<int> data = await i2c.readBulk(address, fifoData, 6);

      if (data.length < 6) {
        throw Exception(
            "Expected 6 bytes but got ${data.length} from FIFO data register");
      }
      redValue = ((data[0] << 16) | (data[1] << 8) | data[2]) & 0x03FFFF;
      irValue = ((data[3] << 16) | (data[4] << 8) | data[5]) & 0x03FFFF;
    } catch (e) {
      logger.e("Error reading raw FIFO data: $e");
      rethrow;
    }
  }

  Future<Map<String, double>> getRawData() async {
    try {
      await readRawFifo();

      return {
        'red': redValue.toDouble(),
        'ir': irValue.toDouble(),
      };
    } catch (e) {
      logger.e("Error getting raw map data: $e");
      rethrow;
    }
  }
}
