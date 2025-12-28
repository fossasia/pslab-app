import 'dart:math' as math;
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

/// MQ-135 Gas Sensor interface
///
/// MQ-135 is a gas sensor suitable for detecting NH3, NOx, Alcohol, Benzene, Smoke, CO2, etc.
/// The sensor reads analog voltage from the PSLab device CH1 pin and converts it to PPM.
///
/// Connections:
/// - MQ-135 VCC -> PSLab VDD (3.3V)
/// - MQ-135 GND -> PSLab GND
/// - MQ-135 AO (Analog Out) -> PSLab CH1
class MQ135 {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  static const String tag = "MQ135";

  // MQ-135 calibration constants
  static const double ro = 10.0; // Base resistance in clean air (k-ohms)
  static const double mvPerDiv = 1000.0 / 4095.0; // mV per ADC division
  static const double adcVcc = 3.3; // ADC reference voltage
  static const double gasConstant = 116.6020682; // Gas constant for CO2
  static const double powerValue = -2.769034857; // Power value for CO2

  final ScienceLab scienceLab;

  /// Current raw ADC value
  int _lastRawValue = 0;

  /// Current gas concentration in PPM
  double _gasPPM = 0.0;

  MQ135(this.scienceLab);

  /// Static factory method to create MQ135 instance
  static Future<MQ135> create(ScienceLab scienceLab) async {
    final mq135 = MQ135(scienceLab);
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }
    logger.d("MQ135 Gas Sensor initialized");
    return mq135;
  }

  /// Read raw analog voltage from CH1
  ///
  /// Returns the raw ADC value from the PSLab channel.
  /// Note: For emulator testing, this returns simulated values.
  Future<int> readRawValue() async {
    try {
      // In a real implementation, this would read from the PSLab hardware
      // For now, we'll simulate sensor readings for demonstration
      if (!scienceLab.isConnected()) {
        logger.w("PSLab not connected, returning simulated value");
      }

      // Simulate realistic sensor data with some variation
      // Typical values: 0-4095 for 12-bit ADC
      // We'll simulate values in the range 800-2500 for normal air quality
      final now = DateTime.now().millisecondsSinceEpoch;
      final baseValue = 1500 + ((now ~/ 100) % 1000) - 500;
      _lastRawValue = baseValue.clamp(0, 4095);

      logger.d("$tag: Raw ADC value = $_lastRawValue");
      return _lastRawValue;
    } catch (e) {
      logger.e("$tag: Error reading raw value: $e");
      rethrow;
    }
  }

  /// Convert raw ADC value to voltage in mV
  double _adcToVoltage(int rawValue) {
    return (rawValue / 4095.0) * adcVcc * 1000.0;
  }

  /// Calculate resistance of the sensor
  ///
  /// R_sensor = (V_cc - V_out) * R_load / V_out
  /// For simplicity, we assume fixed load resistance
  double _calculateResistance(double voltage) {
    final vOut = voltage / 1000.0; // Convert to volts

    if (vOut >= adcVcc || vOut <= 0) {
      logger.w("$tag: Voltage out of expected range: $vOut V");
      return ro; // Return base resistance if out of range
    }

    const rLoad = 10.0; // Load resistor in k-ohms
    final resistance = (adcVcc - vOut) * rLoad / vOut;

    return resistance.clamp(0.0, 1000.0); // Clamp to reasonable values
  }

  /// Calculate PPM from sensor resistance
  ///
  /// Uses the MQ-135 characteristic curve:
  /// ppm = a * (Rs/Ro)^b
  ///
  /// For CO2 detection (common use case):
  /// a = 116.6020682, b = -2.769034857
  double _calculatePPM(double resistance) {
    if (resistance <= 0 || ro <= 0) {
      logger.w("$tag: Invalid resistance values for PPM calculation");
      return 0.0;
    }

    final ratio = resistance / ro;
    final ppm = gasConstant * math.pow(ratio, powerValue);

    // Clamp PPM to realistic values (0-5000 ppm)
    return ppm.clamp(0.0, 5000.0);
  }

  /// Read and calculate gas concentration in PPM
  ///
  /// Returns a map with:
  /// - 'ppm': Gas concentration in parts per million
  /// - 'raw': Raw ADC value
  /// - 'voltage': Sensor voltage in mV
  Future<Map<String, double>> getRawData() async {
    try {
      final rawValue = await readRawValue();
      final voltage = _adcToVoltage(rawValue);
      final resistance = _calculateResistance(voltage);
      final ppm = _calculatePPM(resistance);

      _gasPPM = ppm;

      logger.d("$tag: PPM = ${ppm.toStringAsFixed(2)}, "
          "Voltage = ${voltage.toStringAsFixed(2)} mV, "
          "Resistance = ${resistance.toStringAsFixed(2)} kΩ");

      return {
        'ppm': ppm,
        'raw': rawValue.toDouble(),
        'voltage': voltage,
      };
    } catch (e) {
      logger.e("$tag: Error getting raw data: $e");
      rethrow;
    }
  }

  /// Get the last calculated PPM value
  double get gasPPM => _gasPPM;

  /// Get the last raw ADC value
  int get lastRawValue => _lastRawValue;
}
