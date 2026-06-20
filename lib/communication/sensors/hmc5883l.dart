import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class HMC5883L {
  static const String tag = "HMC5883L";

  final I2C i2c;

  HMC5883L._(this.i2c);

  static Future<HMC5883L> create(I2C i2c, ScienceLab scienceLab) async {
    final sensor = HMC5883L._(i2c);
    await sensor._init(scienceLab);
    return sensor;
  }

  Future<void> _openMPUBypass() async {
    try {
      await i2c.write(104, [0x00], 0x6B);
      await Future.delayed(const Duration(milliseconds: 50));
      await i2c.write(104, [0x00], 0x6A);
      await Future.delayed(const Duration(milliseconds: 50));
      await i2c.write(104, [0x02], 0x37);
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      logger.i(e);
    }
  }

  Future<void> _init(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) return;

    logger.i("$tag: Initializing Universal Compass Driver...");
    await _openMPUBypass();

    try {
      await i2c.write(30, [0x70], 0x00);
      await i2c.write(30, [0x20], 0x01);
      await i2c.write(30, [0x00], 0x02);
    } catch (_) {}

    try {
      await i2c.write(13, [0x01], 0x0B);
      await i2c.write(13, [0x15], 0x09);
    } catch (_) {}

    try {
      await i2c.write(44, [0x05], 0x29);
      await i2c.write(44, [0x01], 0x0A);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<List<double>> getRaw() async {
    try {
      await _openMPUBypass();

      List<int> data;

      data = await i2c.readBulk(30, 0x03, 6);
      if (data.length >= 6 && !data.take(6).every((b) => b == 255)) {
        int x = _convertBytesToInt(data[0], data[1]);
        int z = _convertBytesToInt(data[2], data[3]);
        int y = _convertBytesToInt(data[4], data[5]);
        return [x / 1090.0, y / 1090.0, z / 1090.0];
      }

      data = await i2c.readBulk(13, 0x00, 6);
      if (data.length >= 6 && !data.take(6).every((b) => b == 255)) {
        int x = _convertBytesToInt(data[1], data[0]);
        int y = _convertBytesToInt(data[3], data[2]);
        int z = _convertBytesToInt(data[5], data[4]);
        return [x / 3000.0, y / 3000.0, z / 3000.0];
      }

      data = await i2c.readBulk(44, 0x01, 6);
      if (data.length >= 6 && !data.take(6).every((b) => b == 255)) {
        int x = _convertBytesToInt(data[1], data[0]);
        int y = _convertBytesToInt(data[3], data[2]);
        int z = _convertBytesToInt(data[5], data[4]);
        return [x / 3000.0, y / 3000.0, z / 3000.0];
      }

      return [0.0, 0.0, 0.0];
    } catch (e) {
      logger.e("$tag: Error reading data: $e");
      return [0.0, 0.0, 0.0];
    }
  }

  int _convertBytesToInt(int msb, int lsb) {
    int value = ((msb & 0xFF) << 8) | (lsb & 0xFF);
    if (value >= 0x8000) value -= 0x10000;
    return value;
  }
}
