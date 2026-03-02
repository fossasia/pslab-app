import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/others/logger_service.dart';

/// MLX90614 non-contact infrared temperature sensor.
///
/// Communicates over SMBus (subset of I2C) at address 0x5A.
/// Measures both object (target) and ambient (sensor body) temperature.
class MLX90614 {
  static const String tag = "MLX90614";

  static const int address = 0x5A;

  static const int _objectTempRegister = 0x07;
  static const int _ambientTempRegister = 0x06;

  static const int numPlots = 2;
  static const List<String> plotNames = ["Object Temp", "Ambient Temp"];
  static const String name = "IR Temperature MLX90614";

  final I2C i2c;

  MLX90614._(this.i2c);

  static Future<MLX90614> create(I2C i2c) async {
    final sensor = MLX90614._(i2c);
    logger.i("$tag initialized at address 0x${address.toRadixString(16)}");
    return sensor;
  }

  /// Read raw temperature from the given register.
  ///
  /// The MLX90614 returns 3 bytes: LSB, MSB, and PEC (error-checking byte).
  /// Temperature in Kelvin = raw_value * 0.02.
  /// Temperature in Celsius = Kelvin - 273.15.
  Future<double> _readTemperature(int register) async {
    try {
      List<int> data = await i2c.readBulk(address, register, 3);
      if (data.length < 3) {
        throw Exception(
          "$tag: Expected 3 bytes but got ${data.length} from register 0x${register.toRadixString(16)}",
        );
      }

      int lsb = data[0] & 0xFF;
      int msb = data[1] & 0xFF;
      int rawValue = (msb << 8) | lsb;

      double tempCelsius = rawValue * 0.02 - 273.15;

      return tempCelsius;
    } catch (e) {
      logger.e(
        "$tag: Error reading temperature from register "
        "0x${register.toRadixString(16)}: $e",
      );
      rethrow;
    }
  }

  /// Read the object (target) temperature in degrees Celsius.
  Future<double> readObjectTemperature() async {
    return _readTemperature(_objectTempRegister);
  }

  /// Read the ambient (sensor body) temperature in degrees Celsius.
  Future<double> readAmbientTemperature() async {
    return _readTemperature(_ambientTempRegister);
  }

  /// Read both temperatures and return as a map.
  Future<Map<String, double>> getRawData() async {
    try {
      double objectTemp = await readObjectTemperature();
      double ambientTemp = await readAmbientTemperature();

      return {
        'objectTemperature': objectTemp,
        'ambientTemperature': ambientTemp,
      };
    } catch (e) {
      logger.e("$tag: Error getting raw data: $e");
      rethrow;
    }
  }
}
