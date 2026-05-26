import 'dart:async';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/others/logger_service.dart';

class SHT21 {
  final I2C i2c;
  static const int address = 0x40;
  static const String _tag = "SHT21";

  static const int tempHoldCmd = 0xE3;
  static const int humidityHoldCmd = 0xE5;

  SHT21(this.i2c);

  Future<bool> checkConnection() async {
    try {
      await i2c.writeBulk(address, [0xFE]);
      await Future.delayed(const Duration(milliseconds: 50));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<double> getTemperature() async {
    List<int> data = await i2c.readBulk(address, tempHoldCmd, 3);
    logger.d("$_tag RAW TEMP: $data");

    if (data.length < 3 || !_verifyChecksum(data)) {
      throw Exception("Temp Checksum Failed");
    }

    int rawValue = ((data[0] & 0xFF) << 8) | (data[1] & 0xFC);
    return -46.85 + 175.72 * (rawValue / 65536.0);
  }

  Future<double> getHumidity() async {
    List<int> data = await i2c.readBulk(address, humidityHoldCmd, 3);
    logger.w("$_tag RAW HUMIDITY: $data");

    if (data.length < 3 || !_verifyChecksum(data)) {
      throw Exception("Humidity Checksum Failed");
    }

    int rawValue = ((data[0] & 0xFF) << 8) | (data[1] & 0xFC);
    return -6.0 + 125.0 * (rawValue / 65536.0);
  }

  bool _verifyChecksum(List<int> data) {
    const int polynomial = 0x31;
    int crc = 0;
    for (int i = 0; i < 2; i++) {
      crc ^= data[i];
      for (int bit = 8; bit > 0; bit--) {
        if ((crc & 0x80) != 0) {
          crc = (crc << 1) ^ polynomial;
        } else {
          crc = crc << 1;
        }
      }
    }
    return (crc & 0xFF) == (data[2] & 0xFF);
  }
}
