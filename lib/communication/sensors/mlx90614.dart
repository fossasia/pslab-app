import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/others/logger_service.dart';

class MLX90614 {
  static const String tag = "MLX90614";

  static const int address = 0x5A;
  static const int objTempRegister = 0x07;
  static const int ambTempRegister = 0x06;

  final I2C i2c;
  double objectTemperature = 0.0;
  double ambientTemperature = 0.0;

  MLX90614._(this.i2c);

  static Future<MLX90614> create(I2C i2c, ScienceLab scienceLab) async {
    final mlx = MLX90614._(i2c);
    await mlx._init(scienceLab);
    return mlx;
  }

  Future<void> _init(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception(appLocalizations.notConnected);
    }
    try {
      await i2c.config(100000);
    } catch (e) {
      logger.e("Error initializing MLX90614: $e");
      rethrow;
    }
  }

  Future<double?> _readTemp(int register) async {
    try {
      List<int> vals = await i2c.readBulk(address, register, 3);

      if (vals.length >= 2) {
        int lsb = vals[0];
        int msb = vals[1];

        return ((((msb & 0x007F) << 8) + lsb) * 0.02) - 0.01 - 273.15;
      }
      return null;
    } catch (e) {
      logger.e("Error reading from MLX90614 register $register: $e");
      rethrow;
    }
  }

  Future<Map<String, double>> getRawData() async {
    try {
      double? objTemp = await _readTemp(objTempRegister);
      double? ambTemp = await _readTemp(ambTempRegister);

      objectTemperature = objTemp ?? objectTemperature;
      ambientTemperature = ambTemp ?? ambientTemperature;

      return {
        'objectTemperature': objectTemperature,
        'ambientTemperature': ambientTemperature,
      };
    } catch (e) {
      logger.e("Error getting raw data: $e");
      rethrow;
    }
  }
}
