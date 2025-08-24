import 'dart:math';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

class APDS9960 {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  static const String tag = "APDS9960";

  static const int address = 0x39;

  static const int enable = 0x80;
  static const int atime = 0x81;
  static const int pilt = 0x89;
  static const int pers = 0x8C;
  static const int control = 0x8F;
  static const int status = 0x93;
  static const int cdatal = 0x94;
  static const int pdata = 0x9C;
  static const int gpenth = 0xA0;
  static const int gexth = 0xA1;
  static const int gconf1 = 0xA2;
  static const int gconf2 = 0xA3;
  static const int gpulse = 0xA6;
  static const int gconf4 = 0xAB;
  static const int gflvl = 0xAE;
  static const int gstatus = 0xAF;
  static const int aiclear = 0xE7;
  static const int gfifoU = 0xFC;

  static const int bitMaskEnableEn = 0x01;
  static const int bitMaskEnableColor = 0x02;
  static const int bitMaskEnableProx = 0x04;
  static const int bitMaskEnableGesture = 0x40;
  static const int bitMaskStatusGint = 0x04;
  static const int bitMaskGstatusGfov = 0x02;
  static const int bitMaskGconf4GfifoCLr = 0x04;

  static const int bitPosPersPpers = 4;
  static const int bitMaskPersPpers = 0xF0;

  static const int bitPosControlAgain = 0;
  static const int bitMaskControlAgain = 3;

  final I2C i2c;

  List<int> colorData = [0, 0, 0, 0];
  double lux = 0.0;
  int proximity = 0;
  int gesture = 0;

  APDS9960._(this.i2c);

  static Future<APDS9960> create(I2C i2c, ScienceLab scienceLab) async {
    final apds9960 = APDS9960._(i2c);
    await apds9960._initialize(scienceLab);
    return apds9960;
  }

  Future<void> _initialize(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }

    try {
      await enableProximity(false);
      await enableGesture(false);
      await enableColor(false);

      await setProximityInterruptThreshold([0, 0, 0]);
      await i2c.write(address, [0], gpenth);
      await i2c.write(address, [0], gexth);
      await i2c.write(address, [0], gconf1);
      await i2c.write(address, [0], gconf2);
      await i2c.write(address, [0], gconf4);
      await i2c.write(address, [0], gpulse);
      await i2c.write(address, [255], atime);
      await i2c.write(address, [0], control);

      await clearInterrupt();

      await setBit(gconf4, bitMaskGconf4GfifoCLr, true);

      await i2c.write(address, [0], enable);
      await Future.delayed(const Duration(milliseconds: 25));

      await _enable(true);
      await Future.delayed(const Duration(milliseconds: 10));

      await setProximityInterruptThreshold([0, 5, 4]);
      await i2c.write(address, [0x05], gpenth);
      await i2c.write(address, [0x1E], gexth);
      await i2c.write(address, [0x82], gconf1);
      await i2c.write(address, [0x41], gconf2);
      await i2c.write(address, [0x85], gpulse);
      await setColorIntegrationTime(256);
      await setColorGain(1);

      logger.d("APDS9960 initialized successfully");
    } catch (e) {
      logger.e("Error initializing APDS9960: $e");
      rethrow;
    }
  }

  Future<void> _enable(bool value) async {
    await setBit(enable, bitMaskEnableEn, value);
  }

  Future<void> enableProximity(bool value) async {
    await setBit(enable, bitMaskEnableProx, value);
  }

  Future<void> enableGesture(bool value) async {
    await setBit(enable, bitMaskEnableGesture, value);
  }

  Future<void> enableColor(bool value) async {
    await setBit(enable, bitMaskEnableColor, value);
  }

  Future<void> setProximityInterruptThreshold(List<int> settingArray) async {
    if (settingArray.isNotEmpty &&
        settingArray[0] >= 0 &&
        settingArray[0] <= 255) {
      await i2c.write(address, [settingArray[0]], pilt);
    }
    if (settingArray.length > 1 &&
        settingArray[1] >= 0 &&
        settingArray[1] <= 255) {
      await i2c.write(address, [settingArray[1]], pilt);
    }
    int persist = 4;
    if (settingArray.length > 2 &&
        settingArray[2] >= 0 &&
        settingArray[2] <= 15) {
      persist = min(settingArray[2], 15);
      await setBits(pers, bitPosPersPpers, bitMaskPersPpers, persist);
    }
  }

  Future<void> clearInterrupt() async {
    await i2c.write(address, [], aiclear);
  }

  Future<void> setColorIntegrationTime(int value) async {
    await i2c.write(address, [256 - value], atime);
  }

  Future<void> setColorGain(int value) async {
    await setBits(control, bitPosControlAgain, bitMaskControlAgain, value);
  }

  Future<int> getProximity() async {
    try {
      List<int> data = await i2c.readBulk(address, pdata, 1);
      proximity = data[0] & 0xFF;
      return proximity;
    } catch (e) {
      logger.e("Error reading proximity: $e");
      rethrow;
    }
  }

  Future<List<int>> getColorData() async {
    try {
      colorData = [
        await _colorData16(cdatal + 2),
        await _colorData16(cdatal + 4),
        await _colorData16(cdatal + 6),
        await _colorData16(cdatal),
      ];
      return colorData;
    } catch (e) {
      logger.e("Error reading color data: $e");
      rethrow;
    }
  }

  Future<double> getLux() async {
    try {
      await getColorData();
      lux = (-0.32466 * colorData[0]) +
          (1.57837 * colorData[1]) +
          (-0.73191 * colorData[2]);
      return lux;
    } catch (e) {
      logger.e("Error calculating lux: $e");
      rethrow;
    }
  }

  Future<int> getGesture() async {
    try {
      if (await getBit(gstatus, bitMaskGstatusGfov)) {
        await setBit(gconf4, bitMaskGconf4GfifoCLr, true);
        int waitCycles = 0;
        while (!(await getBit(status, bitMaskStatusGint)) && waitCycles <= 30) {
          await Future.delayed(const Duration(milliseconds: 3));
          waitCycles++;
        }
      }

      List<List<int>> frame = [];
      List<int> datasetsAvailableData = await i2c.readBulk(address, gflvl, 1);
      int datasetsAvailable = datasetsAvailableData[0] & 0xFF;

      if (await getBit(status, bitMaskStatusGint) && datasetsAvailable > 0) {
        while (true) {
          List<int> datasetCountData = await i2c.readBulk(address, gflvl, 1);
          int datasetCount = datasetCountData[0] & 0xFF;
          if (datasetCount == 0) break;

          List<int> buffer =
              await i2c.readBulk(address, gfifoU, min(128, datasetCount * 4));

          for (int i = 0; i < datasetCount; i++) {
            List<int> bufferDataset = [];
            for (int j = 0; j < 4; j++) {
              bufferDataset.add(buffer[i * 4 + j] & 0xFF);
            }

            bool fullySaturated = bufferDataset.every((val) => val == 255);
            bool fullyZero = bufferDataset.every((val) => val == 0);
            bool highCount = bufferDataset.every((val) => val >= 30);

            if (!fullySaturated && !fullyZero && highCount) {
              if (frame.length < 2) {
                frame.add(bufferDataset);
              } else {
                frame[1] = bufferDataset;
              }
            }
          }
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }

      if (frame.length < 2) {
        gesture = 0;
        return gesture;
      }

      List<int> frame0 = frame[0];
      List<int> frame1 = frame[1];

      int frUd = _calcDelta(frame0[0], frame0[1]);
      int frLr = _calcDelta(frame0[2], frame0[3]);
      int lrUd = _calcDelta(frame1[0], frame1[1]);
      int lrLr = _calcDelta(frame1[2], frame1[3]);

      int deltaUd = lrUd - frUd;
      int deltaLr = lrLr - frLr;

      int stateUd = _getState(deltaUd);
      int stateLr = _getState(deltaLr);

      gesture = _determineGesture(stateUd, stateLr, deltaUd, deltaLr);
      return gesture;
    } catch (e) {
      logger.e("Error reading gesture: $e");
      rethrow;
    }
  }

  int _calcDelta(int a, int b) {
    if (a + b == 0) return 0;
    return ((a - b) * 100) ~/ (a + b);
  }

  int _getState(int delta) {
    if (delta >= 30) return 1;
    if (delta <= -30) return -1;
    return 0;
  }

  int _determineGesture(int stateUd, int stateLr, int deltaUd, int deltaLr) {
    if (stateUd == -1 && stateLr == 0) return 1;
    if (stateUd == 1 && stateLr == 0) return 2;
    if (stateUd == 0 && stateLr == -1) return 3;
    if (stateUd == 0 && stateLr == 1) return 4;

    bool udDominant = deltaUd.abs() > deltaLr.abs();
    if (stateUd == -1 && stateLr == 1) return udDominant ? 1 : 4;
    if (stateUd == 1 && stateLr == -1) return udDominant ? 2 : 3;
    if (stateUd == -1 && stateLr == -1) return udDominant ? 1 : 3;
    if (stateUd == 1 && stateLr == 1) return udDominant ? 2 : 4;
    return 0;
  }

  Future<bool> getBit(int register, int mask) async {
    try {
      List<int> data = await i2c.readBulk(address, register, 1);
      return ((data[0] & 0xFF) & mask) != 0;
    } catch (e) {
      logger.e("Error reading bit from register $register: $e");
      rethrow;
    }
  }

  Future<void> setBit(int register, int mask, bool value) async {
    try {
      List<int> data = await i2c.readBulk(address, register, 1);
      int currentValue = data[0] & 0xFF;
      if (value) {
        currentValue |= mask;
      } else {
        currentValue &= ~mask;
      }
      await i2c.write(address, [currentValue], register);
    } catch (e) {
      logger.e("Error setting bit in register $register: $e");
      rethrow;
    }
  }

  Future<void> setBits(int register, int pos, int mask, int value) async {
    try {
      List<int> data = await i2c.readBulk(address, register, 1);
      int currentValue = data[0] & 0xFF;
      currentValue = (currentValue & ~mask) | (value << pos);
      await i2c.write(address, [currentValue], register);
    } catch (e) {
      logger.e("Error setting bits in register $register: $e");
      rethrow;
    }
  }

  Future<int> _colorData16(int register) async {
    try {
      List<int> data = await i2c.readBulk(address, register, 2);
      return ((data[1] & 0xFF) << 8) | (data[0] & 0xFF);
    } catch (e) {
      logger.e("Error reading 16-bit color data from register $register: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRawData(int mode) async {
    try {
      Map<String, dynamic> data = {};

      if (mode == 0) {
        await enableGesture(false);
        await enableColor(true);
        await enableProximity(true);

        data['colorData'] = await getColorData();
        data['lux'] = await getLux();
        data['proximity'] = await getProximity();
      } else {
        await enableColor(false);
        await enableGesture(true);
        await enableProximity(true);

        data['gesture'] = await getGesture();
      }

      return data;
    } catch (e) {
      logger.e("Error getting raw data: $e");
      rethrow;
    }
  }

  String getGestureString(int gestureValue) {
    switch (gestureValue) {
      case 1:
        return 'Up';
      case 2:
        return 'Down';
      case 3:
        return 'Left';
      case 4:
        return 'Right';
      default:
        return '';
    }
  }
}
