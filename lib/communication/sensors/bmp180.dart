import 'dart:math';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

class BMP180 {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  static const String tag = "BMP180";

  static const int address = 0x77;

  static const int ultraLowPower = 0;
  static const int standard = 1;
  static const int highRes = 2;
  static const int ultraHighRes = 3;

  static const int calAC1 = 0xAA;
  static const int calAC2 = 0xAC;
  static const int calAC3 = 0xAE;
  static const int calAC4 = 0xB0;
  static const int calAC5 = 0xB2;
  static const int calAC6 = 0xB4;
  static const int calB1 = 0xB6;
  static const int calB2 = 0xB8;
  static const int calMB = 0xBA;
  static const int calMC = 0xBC;
  static const int calMD = 0xBE;
  static const int control = 0xF4;
  static const int tempData = 0xF6;
  static const int pressData = 0xF6;

  static const int readTempCmd = 0x2E;
  static const int readPressureCmd = 0x34;

  int mode = highRes;
  int oversampling = highRes;

  static const int numPlots = 3;
  static const List<String> plotNames = ["Temperature", "Pressure", "Altitude"];
  static const String name = "Altimeter BMP180";

  final I2C i2c;
  late int ac1, ac2, ac3, ac4, ac5, ac6, b1, b2, mb, mc, md;
  double temperature = 0.0;
  double pressure = 0.0;

  static const double seaLevelPressure = 101325.0;

  BMP180._(this.i2c);

  static Future<BMP180> create(I2C i2c, ScienceLab scienceLab) async {
    final bmp180 = BMP180._(i2c);
    await bmp180._initializeCalibrationValues(scienceLab);
    return bmp180;
  }

  Future<void> _initializeCalibrationValues(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }

    try {
      ac1 = await readInt16(calAC1);
      ac2 = await readInt16(calAC2);
      ac3 = await readInt16(calAC3);
      ac4 = await readUInt16(calAC4);
      ac5 = await readUInt16(calAC5);
      ac6 = await readUInt16(calAC6);
      b1 = await readInt16(calB1);
      b2 = await readInt16(calB2);
      mb = await readInt16(calMB);
      mc = await readInt16(calMC);
      md = await readInt16(calMD);

      logger.d(
          "Calibration values: [$ac1, $ac2, $ac3, $ac4, $ac5, $ac6, $b1, $b2, $mb, $mc, $md]");
    } catch (e) {
      logger.e("Error initializing BMP180 calibration values: $e");
      rethrow;
    }
  }

  Future<int> readInt16(int registerAddress) async {
    try {
      List<int> data = await i2c.readBulk(address, registerAddress, 2);
      if (data.length < 2) {
        throw Exception(
            "Expected 2 bytes but got ${data.length} from register $registerAddress");
      }
      int value = ((data[0] & 0xFF) << 8) | (data[1] & 0xFF);
      if (value >= 0x8000) value -= 0x10000;
      return value;
    } catch (e) {
      logger.e("Error reading int16 from register $registerAddress: $e");
      rethrow;
    }
  }

  Future<int> readUInt16(int registerAddress) async {
    try {
      List<int> data = await i2c.readBulk(address, registerAddress, 2);
      if (data.length < 2) {
        throw Exception(
            "Expected 2 bytes but got ${data.length} from register $registerAddress");
      }
      return ((data[0] & 0xFF) << 8) | (data[1] & 0xFF);
    } catch (e) {
      logger.e("Error reading uint16 from register $registerAddress: $e");
      rethrow;
    }
  }

  Future<int> readRawTemperature() async {
    try {
      await i2c.write(address, [readTempCmd], control);
      await Future.delayed(const Duration(milliseconds: 5));
      int raw = await readUInt16(tempData);
      return raw;
    } catch (e) {
      logger.e("Error reading raw temperature: $e");
      rethrow;
    }
  }

  Future<double> readTemperature() async {
    try {
      int ut = await readRawTemperature();

      int x1 = ((ut - ac6) * ac5) >> 15;
      int x2 = (mc << 11) ~/ (x1 + md);
      int b5 = x1 + x2;
      temperature = ((b5 + 8) >> 4) / 10.0;

      return temperature;
    } catch (e) {
      logger.e("Error reading temperature: $e");
      rethrow;
    }
  }

  void setOversampling(int num) {
    oversampling = num;
  }

  Future<int> readRawPressure() async {
    try {
      List<int> delays = [5, 8, 14, 26];
      int safeOversampling = oversampling.clamp(0, 3);
      await i2c.write(address, [readPressureCmd + (mode << 6)], control);
      await Future.delayed(Duration(milliseconds: delays[safeOversampling]));

      int msb = await i2c.readByte(address, pressData) & 0xFF;
      int lsb = await i2c.readByte(address, pressData + 1) & 0xFF;
      int xlsb = await i2c.readByte(address, pressData + 2) & 0xFF;

      return ((msb << 16) + (lsb << 8) + xlsb) >> (8 - mode);
    } catch (e) {
      logger.e("Error reading raw pressure: $e");
      rethrow;
    }
  }

  Future<double> readPressure() async {
    try {
      int ut = await readRawTemperature();
      int up = await readRawPressure();

      int x1 = ((ut - ac6) * ac5) >> 15;
      int x2 = (mc << 11) ~/ (x1 + md);
      int b5 = x1 + x2;

      int b6 = b5 - 4000;
      x1 = (b2 * (b6 * b6) >> 12) >> 11;
      x2 = (ac2 * b6) >> 11;
      int x3 = x1 + x2;
      int b3 = (((ac1 * 4 + x3) << mode) + 2) ~/ 4;

      x1 = (ac3 * b6) >> 13;
      x2 = (b1 * ((b6 * b6) >> 12)) >> 16;
      x3 = ((x1 + x2) + 2) >> 2;
      int b4 = (ac4 * (x3 + 32768)) >> 15;
      int b7 = (up - b3) * (50000 >> mode);

      int p;
      if (b7 < 0x80000000) {
        p = (b7 * 2) ~/ b4;
      } else {
        p = (b7 ~/ b4) * 2;
      }

      x1 = (p >> 8) * (p >> 8);
      x1 = (x1 * 3038) >> 16;
      x2 = (-7357 * p) >> 16;
      pressure = (p + ((x1 + x2 + 3791) >> 4)).toDouble();

      return pressure;
    } catch (e) {
      logger.e("Error reading pressure: $e");
      rethrow;
    }
  }

  double altitude() {
    return 44330.0 * (1 - pow(pressure / seaLevelPressure, 1 / 5.255));
  }

  double seaLevel(double pressure, double altitude) {
    return pressure / pow(1 - (altitude / 44330.0), 5.255);
  }

  Future<Map<String, double>> getRawData() async {
    try {
      temperature = await readTemperature();
      pressure = await readPressure();
      double alt = altitude();

      return {
        'temperature': temperature,
        'pressure': pressure,
        'altitude': alt,
      };
    } catch (e) {
      logger.e("Error getting raw data: $e");
      rethrow;
    }
  }
}
