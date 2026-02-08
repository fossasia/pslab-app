import '../peripherals/i2c.dart';

class MLX90614 {
  final I2C i2c;
  // The default I2C address for MLX90614 is 0x5A
  static const int address = 0x5A;

  // Register addresses
  static const int ambientTempReg = 0x06;
  static const int objectTempReg = 0x07;

  MLX90614(this.i2c);

  /// Reads the Ambient (Room) Temperature
  Future<double> getAmbientTemperature() async {
    return _readTemperature(ambientTempReg);
  }

  /// Reads the Object (Target) Temperature
  Future<double> getObjectTemperature() async {
    return _readTemperature(objectTempReg);
  }

  /// Helper function to handle the math
  Future<double> _readTemperature(int reg) async {
    // Read 2 bytes from the specific register
    List<int> data = await i2c.readBulk(address, reg, 2);

    if (data.length < 2) {
      throw Exception("Failed to read temperature from MLX90614");
    }

    // MLX90614 sends LSB first, then MSB.
    int lsb = data[0];
    int msb = data[1];

    // Combine the bytes: (MSB << 8) | LSB
    // We apply the mask 0x7FFF to ignore the error flag (Bit 15)
    // ensuring we only process valid temperature data bits.
    int rawValue = ((msb << 8) | lsb) & 0x7FFF;

    // Formula from datasheet:
    // The sensor returns temperature in Kelvin * 50.
    // Multiply by 0.02 to get Kelvin.
    // Subtract 273.15 to convert Kelvin to Celsius.
    double tempCelsius = (rawValue * 0.02) - 273.15;

    return tempCelsius;
  }
}
