import 'dart:async';
import '../peripherals/i2c.dart';

class SHT21 {
  // SHT21 Default I2C Address
  static const int addr = 0x40;

  // The I2C helper instance (passed in from the main app)
  final I2C i2c;

  // Constructor: Ask for the I2C object instead of trying to create a new empty one
  SHT21(this.i2c);

  // Commands (No Hold Master Mode)
  static const int _triggerTempMeasure = 0xF3;
  static const int _triggerHumMeasure = 0xF5;

  /// Read Temperature in Celsius
  Future<double> getTemperature() async {
    // 1. Send the "Measure" command
    // We use writeBulk because it sends the bytes directly to the address
    await i2c.writeBulk(addr, [_triggerTempMeasure]);

    // 2. Wait for measurement (Datasheet max ~85ms)
    await Future.delayed(Duration(milliseconds: 100));

    // 3. Read 3 bytes (MSB, LSB, Checksum)
    // simpleRead automatically handles the "Start Condition" + "Read" logic
    List<int> data = await i2c.simpleRead(addr, 3);

    if (data.length < 2) return 0.0;

    // 4. Combine bytes & clear status bits
    int rawValue = (data[0] << 8) | (data[1] & 0xFC);

    // 5. Calculate Formula
    return -46.85 + 175.72 * (rawValue / 65536.0);
  }

  /// Read Humidity in %RH
  Future<double> getHumidity() async {
    // 1. Send Measure Command
    await i2c.writeBulk(addr, [_triggerHumMeasure]);

    // 2. Wait
    await Future.delayed(Duration(milliseconds: 100));

    // 3. Read
    List<int> data = await i2c.simpleRead(addr, 3);
    if (data.length < 2) return 0.0;

    int rawValue = (data[0] << 8) | (data[1] & 0xFC);

    // 4. Calculate
    return -6.0 + 125.0 * (rawValue / 65536.0);
  }
}
