import 'dart:math';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

class HMC5883L {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  static const String tag = "HMC5883L";
  static const int address = 0x1E;

  // Register addresses
  static const int configRegA = 0x00;
  static const int configRegB = 0x01;
  static const int modeReg = 0x02;
  static const int dataXMSB = 0x03;
  static const int dataXLSB = 0x04;
  static const int dataZMSB = 0x05;
  static const int dataZLSB = 0x06;
  static const int dataYMSB = 0x07;
  static const int dataYLSB = 0x08;
  static const int statusReg = 0x09;
  static const int idRegA = 0x0A;
  static const int idRegB = 0x0B;
  static const int idRegC = 0x0C;

  // Configuration values for Register A
  static const int samplesAverage1 = 0x00;
  static const int samplesAverage2 = 0x20;
  static const int samplesAverage4 = 0x40;
  static const int samplesAverage8 = 0x60;

  static const int dataRate0_75Hz = 0x00;
  static const int dataRate1_5Hz = 0x04;
  static const int dataRate3Hz = 0x08;
  static const int dataRate7_5Hz = 0x0C;
  static const int dataRate15Hz = 0x10;
  static const int dataRate30Hz = 0x14;
  static const int dataRate75Hz = 0x18;

  static const int measurementNormal = 0x00;
  static const int measurementPositiveBias = 0x01;
  static const int measurementNegativeBias = 0x02;

  // Configuration values for Register B (Gain)
  static const int gain1370 = 0x00; // ±0.88 Ga
  static const int gain1090 = 0x20; // ±1.3 Ga (default)
  static const int gain820 = 0x40;  // ±1.9 Ga
  static const int gain660 = 0x60;  // ±2.5 Ga
  static const int gain440 = 0x80;  // ±4.0 Ga
  static const int gain390 = 0xA0;  // ±4.7 Ga
  static const int gain330 = 0xC0;  // ±5.6 Ga
  static const int gain230 = 0xE0;  // ±8.1 Ga

  // Mode register values
  static const int modeContinuous = 0x00;
  static const int modeSingle = 0x01;
  static const int modeIdle = 0x02;

  // Gain scaling factors (LSB/Gauss)
  static const Map<int, double> gainScales = {
    gain1370: 1370,
    gain1090: 1090,
    gain820: 820,
    gain660: 660,
    gain440: 440,
    gain390: 390,
    gain330: 330,
    gain230: 230,
  };

  final I2C i2c;
  int currentGain = gain1090;
  double scale = 1090;

  double magneticX = 0.0;
  double magneticY = 0.0;
  double magneticZ = 0.0;

  double offsetX = 0.0;
  double offsetY = 0.0;
  double offsetZ = 0.0;

  HMC5883L._(this.i2c);

  static Future<HMC5883L> create(I2C i2c, ScienceLab scienceLab) async {
    final hmc5883l = HMC5883L._(i2c);
    await hmc5883l._initialize(scienceLab);
    return hmc5883l;
  }

  Future<void> _initialize(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }

    try {
      final idA = await i2c.readByte(address, idRegA);
      final idB = await i2c.readByte(address, idRegB);
      final idC = await i2c.readByte(address, idRegC);

      logger.d("HMC5883L IDs: A=0x${idA.toRadixString(16)}, "
          "B=0x${idB.toRadixString(16)}, C=0x${idC.toRadixString(16)}");

      if (idA != 0x48 || idB != 0x34 || idC != 0x33) {
        logger.w("HMC5883L ID mismatch, but continuing initialization");
      }

      await configure();
      logger.d("HMC5883L initialized successfully");
    } catch (e) {
      logger.e("Error initializing HMC5883L: $e");
      rethrow;
    }
  }

  /// Configure the HMC5883L sensor
  Future<void> configure({
    int samplesAverage = samplesAverage8,
    int dataRate = dataRate15Hz,
    int measurementMode = measurementNormal,
    int gain = gain1090,
    int mode = modeContinuous,
  }) async {
    try {
      int configA = samplesAverage | dataRate | measurementMode;
      await i2c.write(address, [configA], configRegA);

      await i2c.write(address, [gain], configRegB);
      currentGain = gain;
      scale = gainScales[gain] ?? 1090;

      await i2c.write(address, [mode], modeReg);

      await Future.delayed(const Duration(milliseconds: 10));

      logger.d("HMC5883L configured: gain=$gain, scale=$scale, mode=$mode");
    } catch (e) {
      logger.e("Error configuring HMC5883L: $e");
      rethrow;
    }
  }

  /// Read raw magnetic field data
  Future<Map<String, int>> readRawData() async {
    try {
      List<int> data = await i2c.readBulk(address, dataXMSB, 6);

      if (data.length < 6) {
        throw Exception(
            "Expected 6 bytes but got ${data.length} from HMC5883L");
      }

      int xRaw = _toSignedInt16((data[0] << 8) | data[1]);
      int zRaw = _toSignedInt16((data[2] << 8) | data[3]);
      int yRaw = _toSignedInt16((data[4] << 8) | data[5]);

      return {
        'x': xRaw,
        'y': yRaw,
        'z': zRaw,
      };
    } catch (e) {
      logger.e("Error reading raw data from HMC5883L: $e");
      rethrow;
    }
  }

  /// Read magnetic field data in microTesla (µT)
  /// Optionally accepts pre-read rawData to avoid redundant I2C reads
  Future<Map<String, double>> readMagneticField({Map<String, int>? rawData}) async {
    try {
      final data = rawData ?? await readRawData();

      magneticX = (data['x']! / scale) * 100.0 - offsetX;
      magneticY = (data['y']! / scale) * 100.0 - offsetY;
      magneticZ = (data['z']! / scale) * 100.0 - offsetZ;

      return {
        'x': magneticX,
        'y': magneticY,
        'z': magneticZ,
      };
    } catch (e) {
      logger.e("Error reading magnetic field: $e");
      rethrow;
    }
  }

  /// Calculate heading angle (0-360 degrees)
  /// Assumes the sensor is level (parallel to ground)
  /// Optionally accepts pre-computed magneticField to avoid redundant I2C reads
  Future<double> readHeading({Map<String, double>? magneticField}) async {
    try {
      final field = magneticField ?? await readMagneticField();

      double heading = atan2(field['y']!, field['x']!);

      double headingDegrees = heading * (180.0 / pi);

      if (headingDegrees < 0) {
        headingDegrees += 360;
      }

      return headingDegrees;
    } catch (e) {
      logger.e("Error calculating heading: $e");
      rethrow;
    }
  }

  /// Calculate total magnetic field magnitude
  /// Optionally accepts pre-computed magneticField to avoid redundant I2C reads
  Future<double> readMagnitude({Map<String, double>? magneticField}) async {
    try {
      final field = magneticField ?? await readMagneticField();
      return sqrt(field['x']! * field['x']! +
          field['y']! * field['y']! +
          field['z']! * field['z']!);
    } catch (e) {
      logger.e("Error calculating magnitude: $e");
      rethrow;
    }
  }

  void setCalibrationOffsets(double minX, double maxX, double minY,
      double maxY, double minZ, double maxZ) {
    offsetX = (minX + maxX) / 2.0;
    offsetY = (minY + maxY) / 2.0;
    offsetZ = (minZ + maxZ) / 2.0;

    logger.d("HMC5883L calibration offsets set: "
        "X=$offsetX, Y=$offsetY, Z=$offsetZ");
  }

  Future<Map<String, dynamic>> getAllData() async {
    try {
      // Perform single I2C read
      final rawData = await readRawData();
      
      // Reuse raw data for magnetic field calculation
      final magneticField = await readMagneticField(rawData: rawData);
      
      // Reuse magnetic field for heading and magnitude calculations
      final heading = await readHeading(magneticField: magneticField);
      final magnitude = await readMagnitude(magneticField: magneticField);

      return {
        'raw_x': rawData['x'],
        'raw_y': rawData['y'],
        'raw_z': rawData['z'],
        'magnetic_x': magneticX,
        'magnetic_y': magneticY,
        'magnetic_z': magneticZ,
        'heading': heading,
        'magnitude': magnitude,
      };
    } catch (e) {
      logger.e("Error getting all data: $e");
      rethrow;
    }
  }

  /// Read status register
  Future<int> readStatus() async {
    try {
      return await i2c.readByte(address, statusReg);
    } catch (e) {
      logger.e("Error reading status: $e");
      rethrow;
    }
  }

  /// Check if data is ready
  Future<bool> isDataReady() async {
    try {
      final status = await readStatus();
      return (status & 0x01) != 0;
    } catch (e) {
      logger.e("Error checking data ready: $e");
      return false;
    }
  }

  int _toSignedInt16(int value) {
    if (value > 32767) {
      return value - 65536;
    }
    return value;
  }

  Future<void> setGain(int gain) async {
    if (!gainScales.containsKey(gain)) {
      throw Exception("Invalid gain value: $gain");
    }
    await configure(gain: gain);
  }

  /// Set measurement mode
  Future<void> setMode(int mode) async {
    try {
      await i2c.write(address, [mode], modeReg);
    } catch (e) {
      logger.e("Error setting mode: $e");
      rethrow;
    }
  }
}
