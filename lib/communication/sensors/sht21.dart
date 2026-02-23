import 'dart:async';
import '../peripherals/i2c.dart';

class SHT21 {
  final I2C i2c;
  static const int address = 0x40;

  // Commands (Use Hold Master Mode for readBulk compatibility)
  static const int tempHoldCmd = 0xE3;
  static const int humidityHoldCmd = 0xE5;

  SHT21(this.i2c);

  Future<double> getTemperature() async {
    // FIX: Use readBulk to handle the Write -> Restart -> Read sequence automatically.
    // This avoids the argument errors with .write() and .read()
    List<int> data = await i2c.readBulk(address, tempHoldCmd, 3);

    if (data.length < 2) {
      throw Exception("Failed to read temperature from SHT21");
    }

    // Mask out status bits (last 2 bits) using & 0xFC
    int rawValue = (data[0] << 8) | (data[1] & 0xFC);

    // Formula: T = -46.85 + 175.72 * (S_T / 2^16)
    return -46.85 + 175.72 * (rawValue / 65536.0);
  }

  Future<double> getHumidity() async {
    // FIX: Use readBulk here too
    List<int> data = await i2c.readBulk(address, humidityHoldCmd, 3);

    if (data.length < 2) {
      throw Exception("Failed to read humidity from SHT21");
    }

    // Mask out status bits
    int rawValue = (data[0] << 8) | (data[1] & 0xFC);

    // Formula: RH = -6 + 125 * (S_RH / 2^16)
    return -6.0 + 125.0 * (rawValue / 65536.0);
  }
}
