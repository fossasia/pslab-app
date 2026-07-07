import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class MPU925X {
  static const String tag = "MPU925X";
  static const int address = 0x68;

  static const int ak8963Address = 0x0C;
  static const int ak8963Cntl = 0x0A;
  static const int intPinCfg = 0x37;

  static const int gyroConfig = 0x1B;
  static const int accelConfig = 0x1C;
  static const int dataStart = 0x3B;

  static const List<double> gyroScaling = [131.0, 65.5, 32.8, 16.4];
  static const List<double> accelScaling = [16384.0, 8192.0, 4096.0, 2048.0];

  int arIndex = 3;
  int grIndex = 3;

  final I2C i2c;

  MPU925X._(this.i2c);

  static Future<MPU925X> create(I2C i2c, ScienceLab scienceLab) async {
    final mpu = MPU925X._(i2c);
    await mpu._initialize(scienceLab);
    return mpu;
  }

  Future<void> _initialize(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }
    try {
      await i2c.write(address, [0], 0x6B);
      await setAccelerationRange(16);
      await setGyroRange(2000);
      await _initMagnetometer();
    } catch (e) {
      logger.e("Error initializing MPU925X: $e");
      rethrow;
    }
  }

  Future<void> _initMagnetometer() async {
    await i2c.write(address, [0x22], intPinCfg);
    await i2c.write(ak8963Address, [0], ak8963Cntl);
    await i2c.write(ak8963Address, [0x16], ak8963Cntl);
  }

  Future<void> setGyroRange(int range) async {
    List<int> validRanges = [250, 500, 1000, 2000];
    grIndex = validRanges.indexOf(range);
    if (grIndex == -1) grIndex = 3;
    await i2c.write(address, [grIndex << 3], gyroConfig);
  }

  Future<void> setAccelerationRange(int range) async {
    List<int> validRanges = [2, 4, 8, 16];
    arIndex = validRanges.indexOf(range);
    if (arIndex == -1) arIndex = 3;
    await i2c.write(address, [arIndex << 3], accelConfig);
  }

  int _toSigned16(int msb, int lsb) {
    int val = (msb << 8) | lsb;
    if (val >= 0x8000) val -= 0x10000;
    return val;
  }

  Future<String> whoAmIAK8963() async {
    await _initMagnetometer();
    List<int> vals = await i2c.readBulk(ak8963Address, 0x00, 1);
    if (vals.isNotEmpty) {
      int v = vals[0];
      if (v == 0x48) {
        return "AK8963 ${v.toRadixString(16)}";
      } else {
        return "AK8963 not found. returned ${v.toRadixString(16)}";
      }
    }
    return "AK8963 read failed";
  }

  Future<Map<String, double>> getRawData() async {
    try {
      List<int> data = await i2c.readBulk(address, dataStart, 14);
      if (data.length < 14) {
        throw Exception("Expected 14 bytes but got ${data.length}");
      }

      double ax = _toSigned16(data[0], data[1]) / accelScaling[arIndex];
      double ay = _toSigned16(data[2], data[3]) / accelScaling[arIndex];
      double az = _toSigned16(data[4], data[5]) / accelScaling[arIndex];

      double temp = _toSigned16(data[6], data[7]) / 340.0 + 36.53;

      double gx = _toSigned16(data[8], data[9]) / gyroScaling[grIndex];
      double gy = _toSigned16(data[10], data[11]) / gyroScaling[grIndex];
      double gz = _toSigned16(data[12], data[13]) / gyroScaling[grIndex];

      return {
        'ax': ax,
        'ay': ay,
        'az': az,
        'gx': gx,
        'gy': gy,
        'gz': gz,
        'temperature': temp,
      };
    } catch (e) {
      logger.e("Error reading MPU925X data: $e");
      rethrow;
    }
  }

  Future<List<double>?> getMagneticField() async {
    try {
      List<int> vals = await i2c.readBulk(ak8963Address, 0x03, 7);
      if (vals.length < 7) return null;

      int mx = _toSigned16(vals[0], vals[1]);
      int my = _toSigned16(vals[2], vals[3]);
      int mz = _toSigned16(vals[4], vals[5]);

      if ((vals[6] & 0x08) != 0) {
        return [mx / 65535.0, my / 65535.0, mz / 65535.0];
      } else {
        return null;
      }
    } catch (e) {
      logger.e("Error reading AK8963 data: $e");
      return null;
    }
  }
}
