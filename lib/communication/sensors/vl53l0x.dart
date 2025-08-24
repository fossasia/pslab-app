import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class VL53L0X {
  static const String tag = "VL53L0X";
  static const int address = 0x29;
  static const int sysrangeStart = 0x00;
  static const int systemSequenceConfig = 0x01;
  static const int systemInterruptConfigGpio = 0x0A;
  static const int gpioHvMuxActiveHigh = 0x84;
  static const int systemInterruptClear = 0x0B;
  static const int resultInterruptStatus = 0x13;
  static const int resultRangeStatus = 0x14;
  static const int msrcConfigControl = 0x60;
  static const int globalConfigSpadEnablesRef0 = 0xB0;
  static const int globalConfigRefEnStartSelect = 0xB6;
  static const int dynamicSpadNumRequestedRefSpad = 0x4E;
  static const int dynamicSpadRefEnStartOffset = 0x4F;
  static const int disableSignalRateMsrc = 0x2;
  static const int disableSignalRatePreRange = 0x10;
  static const int maybeTimerReg = 0x83;
  static const int ioTimeout = 10;
  static const List<List<int>> spadConfig = [
    [0xFF, 0x01],
    [dynamicSpadRefEnStartOffset, 0x00],
    [dynamicSpadNumRequestedRefSpad, 0x2C],
    [0xFF, 0x00],
    [globalConfigRefEnStartSelect, 0xB4]
  ];
  static const List<List<int>> tuningConfig = [
    [0xFF, 0x01],
    [0x00, 0x00],
    [0xFF, 0x00],
    [0x09, 0x00],
    [0x10, 0x00],
    [0x11, 0x00],
    [0x24, 0x01],
    [0x25, 0xFF],
    [0x75, 0x00],
    [0xFF, 0x01],
    [0x4E, 0x2C],
    [0x48, 0x00],
    [0x30, 0x20],
    [0xFF, 0x00],
    [0x30, 0x09],
    [0x54, 0x00],
    [0x31, 0x04],
    [0x32, 0x03],
    [0x40, 0x83],
    [0x46, 0x25],
    [0x60, 0x00],
    [0x27, 0x00],
    [0x50, 0x06],
    [0x51, 0x00],
    [0x52, 0x96],
    [0x56, 0x08],
    [0x57, 0x30],
    [0x61, 0x00],
    [0x62, 0x00],
    [0x64, 0x00],
    [0x65, 0x00],
    [0x66, 0xA0],
    [0xFF, 0x01],
    [0x22, 0x32],
    [0x47, 0x14],
    [0x49, 0xFF],
    [0x4A, 0x00],
    [0xFF, 0x00],
    [0x7A, 0x0A],
    [0x7B, 0x00],
    [0x78, 0x21],
    [0xFF, 0x01],
    [0x23, 0x34],
    [0x42, 0x00],
    [0x44, 0xFF],
    [0x45, 0x26],
    [0x46, 0x05],
    [0x40, 0x40],
    [0x0E, 0x06],
    [0x20, 0x1A],
    [0x43, 0x40],
    [0xFF, 0x00],
    [0x34, 0x03],
    [0x35, 0x44],
    [0xFF, 0x01],
    [0x31, 0x04],
    [0x4B, 0x09],
    [0x4C, 0x05],
    [0x4D, 0x04],
    [0xFF, 0x00],
    [0x44, 0x00],
    [0x45, 0x20],
    [0x47, 0x08],
    [0x48, 0x28],
    [0x67, 0x00],
    [0x70, 0x04],
    [0x71, 0x01],
    [0x72, 0xFE],
    [0x76, 0x00],
    [0x77, 0x00],
    [0xFF, 0x01],
    [0x0D, 0x01],
    [0xFF, 0x00],
    [0x80, 0x01],
    [0x01, 0xF8],
    [0xFF, 0x01],
    [0x8E, 0x01],
    [0x00, 0x01],
    [0xFF, 0x00],
    [0x80, 0x00]
  ];
  static const List<List<int>> spad1 = [
    [0x80, 0x01],
    [0xFF, 0x01],
    [0x00, 0x00],
    [0xFF, 0x06]
  ];
  static const List<List<int>> spad2 = [
    [0xFF, 0x07],
    [0x81, 0x01],
    [0x80, 0x01],
    [0x94, 0x6B],
    [maybeTimerReg, 0x00]
  ];
  static const List<List<int>> spad3 = [
    [0x81, 0x00],
    [0xFF, 0x06]
  ];
  static const List<List<int>> spad4 = [
    [0xFF, 0x01],
    [0x00, 0x01],
    [0xFF, 0x00],
    [0x80, 0x00]
  ];
  final I2C i2c;
  late int stopByte;
  VL53L0X._(this.i2c);
  static Future<VL53L0X> create(I2C i2c, ScienceLab scienceLab) async {
    final vl53l0x = VL53L0X._(i2c);
    await vl53l0x._initialize(scienceLab);
    return vl53l0x;
  }

  Future<void> _initialize(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }
    try {
      List<List<int>> initSequence = [
        [0x88, 0x00],
        [0x80, 0x01],
        [0xFF, 0x01],
        [0x00, 0x00]
      ];
      for (List<int> regValPair in initSequence) {
        await i2c.write(address, [regValPair[1]], regValPair[0]);
      }
      stopByte = await i2c.readByte(address, 0x91);
      List<List<int>> postReadSequence = [
        [0x00, 0x01],
        [0xFF, 0x00],
        [0x80, 0x00]
      ];
      for (List<int> regValPair in postReadSequence) {
        await i2c.write(address, [regValPair[1]], regValPair[0]);
      }
      int configControl = await i2c.readByte(address, msrcConfigControl) |
          (disableSignalRateMsrc | disableSignalRatePreRange);
      await i2c.write(address, [configControl], msrcConfigControl);
      await i2c.write(address, [0xFF], systemSequenceConfig);
      await _spadConfig();
      for (List<int> regValPair in tuningConfig) {
        await i2c.write(address, [regValPair[1]], regValPair[0]);
      }
      await i2c.write(address, [0x04], systemInterruptConfigGpio);
      int gpioHvMux = await i2c.readByte(address, gpioHvMuxActiveHigh);
      await i2c.write(address, [gpioHvMux & ~0x10], gpioHvMuxActiveHigh);
      await i2c.write(address, [0x01], systemInterruptClear);
      await i2c.write(address, [0xE8], systemSequenceConfig);
      await i2c.write(address, [0x01], systemSequenceConfig);
      await _performSingleRefCalibration(0x40);
      await i2c.write(address, [0x01], systemSequenceConfig);
      await i2c.write(address, [0x02], systemSequenceConfig);
      await _performSingleRefCalibration(0x00);
      await i2c.write(address, [0xE8], systemSequenceConfig);
      logger.d("VL53L0X initialized successfully");
    } catch (e) {
      logger.e("Error initializing VL53L0X: $e");
      rethrow;
    }
  }

  Future<List<int>> _getSpadInfo() async {
    for (List<int> regValPair in spad1) {
      await i2c.write(address, [regValPair[1]], regValPair[0]);
    }
    int uu = await i2c.readByte(address, maybeTimerReg) | 0x04;
    await i2c.write(address, [uu], maybeTimerReg);
    for (List<int> regValPair in spad2) {
      await i2c.write(address, [regValPair[1]], regValPair[0]);
    }
    int start = DateTime.now().millisecondsSinceEpoch;
    while (await i2c.readByte(address, maybeTimerReg) == 0x00) {
      if (ioTimeout > 0 &&
          (DateTime.now().millisecondsSinceEpoch - start) / 1000.0 >=
              ioTimeout) {
        logger.e("Timeout waiting for VL53L0X!");
        break;
      }
    }
    await i2c.write(address, [0x01], maybeTimerReg);
    int tmp = await i2c.readByte(address, 0x92);
    int count = tmp & 0x7F;
    bool isAperture = ((tmp >> 7) & 0x01) == 1;
    for (List<int> regValPair in spad3) {
      await i2c.write(address, [regValPair[1]], regValPair[0]);
    }
    int vv = await i2c.readByte(address, maybeTimerReg) & ~0x04;
    await i2c.write(address, [vv], maybeTimerReg);
    for (List<int> regValPair in spad4) {
      await i2c.write(address, [regValPair[1]], regValPair[0]);
    }
    return [count, isAperture ? 1 : 0];
  }

  Future<void> _spadConfig() async {
    List<int> spadInfo = await _getSpadInfo();
    int spadCount = spadInfo[0];
    int spadIsAperture = spadInfo[1];
    await i2c.write(address, [0], globalConfigSpadEnablesRef0);
    List<int> spadMap =
        await i2c.readBulk(address, globalConfigSpadEnablesRef0, 6);
    for (List<int> regValPair in spadConfig) {
      await i2c.write(address, [regValPair[1]], regValPair[0]);
    }
    int firstSpadToEnable = (spadIsAperture == 1) ? 12 : 0;
    int spadsEnabled = 0;
    for (int i = 0; i < 48; i++) {
      int index = i ~/ 8;
      if (i < firstSpadToEnable || spadsEnabled == spadCount) {
        spadMap[index] = spadMap[index] & ~(1 << (i % 8));
      } else if (((spadMap[index] >> (i % 8)) & 0x1) > 0) {
        spadsEnabled++;
      }
    }
    await i2c.writeBulk(address, spadMap);
  }

  Future<void> _performSingleRefCalibration(int vhvInitByte) async {
    await i2c.write(address, [0x01 | vhvInitByte & 0xFF], sysrangeStart);
    int start = DateTime.now().millisecondsSinceEpoch;
    while ((await i2c.readByte(address, resultInterruptStatus) & 0x07) == 0) {
      if (ioTimeout > 0 &&
          (DateTime.now().millisecondsSinceEpoch - start) / 1000.0 >=
              ioTimeout) {
        logger.e("Timeout waiting for VL53L0X!");
        break;
      }
    }
    await i2c.write(address, [0x01], systemInterruptClear);
    await i2c.write(address, [0x00], sysrangeStart);
  }

  Future<int> getRaw() async {
    try {
      List<List<int>> startSequence = [
        [0x80, 0x01],
        [0xFF, 0x01],
        [0x00, 0x00],
        [0x91, stopByte],
        [0x00, 0x01],
        [0xFF, 0x00],
        [0x80, 0x00],
        [sysrangeStart, 0x01]
      ];
      for (List<int> regValPair in startSequence) {
        await i2c.write(address, [regValPair[1]], regValPair[0]);
      }
      int start = DateTime.now().millisecondsSinceEpoch;
      while ((await i2c.readByte(address, sysrangeStart) & 0x01) > 0) {
        if (ioTimeout > 0 &&
            (DateTime.now().millisecondsSinceEpoch - start) / 1000.0 >=
                ioTimeout) {
          logger.e("Timeout waiting for VL53L0X!");
          break;
        }
      }
      start = DateTime.now().millisecondsSinceEpoch;
      while ((await i2c.readByte(address, resultInterruptStatus) & 0x07) == 0) {
        if (ioTimeout > 0 &&
            (DateTime.now().millisecondsSinceEpoch - start) / 1000.0 >=
                ioTimeout) {
          logger.e("Timeout waiting for VL53L0X!");
          break;
        }
      }
      List<int> data = await i2c.readBulk(address, resultRangeStatus + 10, 2);
      await i2c.write(address, [0x01], systemInterruptClear);
      return ((data[0] & 0xFF) << 8) | (data[1] & 0xFF);
    } catch (e) {
      logger.e("Error reading VL53L0X raw data: $e");
      rethrow;
    }
  }

  Future<double> getDistance() async {
    int rawValue = await getRaw();
    return rawValue.toDouble();
  }
}
