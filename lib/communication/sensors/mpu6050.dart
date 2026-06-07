import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class MPU6050 {
  static const String tag = "MPU6050";
  static const int address = 0x68;

  static const int gyroConfig = 0x1B;
  static const int accelConfig = 0x1C;
  static const int dataStart = 0x3B;

  static const List<double> gyroScaling = [131.0, 65.5, 32.8, 16.4];
  static const List<double> accelScaling = [16384.0, 8192.0, 4096.0, 2048.0];

  int arIndex = 3;
  int grIndex = 3;

  final I2C i2c;

  MPU6050._(this.i2c);

  static Future<MPU6050> create(I2C i2c, ScienceLab scienceLab) async {
    final mpu = MPU6050._(i2c);
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
    } catch (e) {
      logger.e("Error initializing MPU6050: $e");
      rethrow;
    }
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
      logger.e("Error reading MPU6050 data: $e");
      rethrow;
    }
  }
}
