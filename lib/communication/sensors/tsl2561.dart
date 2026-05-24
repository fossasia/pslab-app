import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class TSL2561 {
  static const String tag = "TSL2561";

  static const List<int> addresses = [0x39, 0x29, 0x49];

  static const int commandBit = 0x80;
  static const int wordBit = 0x20;

  static const int controlPowerOn = 0x03;
  static const int controlPowerOff = 0x00;

  static const int registerControl = 0x00;
  static const int registerTiming = 0x01;
  static const int registerId = 0x0A;
  static const int registerChan0Low = 0x0C;
  static const int registerChan1Low = 0x0E;

  static const int integrationTime13Ms = 0x00;
  static const int integrationTime101Ms = 0x01;
  static const int integrationTime402Ms = 0x02;

  static const int gain0X = 0x00;
  static const int gain16X = 0x10;

  final I2C i2c;
  int? _address;
  int _timing = integrationTime13Ms;
  int _gain = gain16X;

  double fullSpectrum = 0.0;
  double infrared = 0.0;
  double visible = 0.0;

  TSL2561._(this.i2c);

  static Future<TSL2561> create(I2C i2c, ScienceLab scienceLab) async {
    final tsl2561 = TSL2561._(i2c);
    await tsl2561._initializeSensor(scienceLab);
    return tsl2561;
  }

  Future<void> _initializeSensor(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }

    bool sensorFound = false;

    try {
      for (int addr in addresses) {
        _address = addr;
        await disable();

        logger.d("$tag: Checking address 0x${addr.toRadixString(16)}");

        List<int> idData = await i2c.readBulk(addr, registerId | commandBit, 1);

        if (idData.isNotEmpty) {
          int id = idData[0];
          logger.d(
              "$tag: RAW ID READ at 0x${addr.toRadixString(16)} is: 0x${id.toRadixString(16)} (Decimal: $id)");

          if (id != 255) {
            logger.d("$tag: Sensor accepted at 0x${addr.toRadixString(16)}!");
            sensorFound = true;
            break;
          }
        }
      }

      if (!sensorFound) {
        throw Exception(
            'TSL2561 sensor not found on I2C bus. Check SDA/SCL wiring.');
      }

      await enable();
      await Future.delayed(const Duration(milliseconds: 15));
      await setGainAndTiming(_gain, _timing);
    } catch (e) {
      logger.e("Error initializing TSL2561: $e");
      rethrow;
    }
  }

  Future<void> enable() async {
    if (_address == null) return;
    await i2c.write(_address!, [controlPowerOn], commandBit | registerControl);
  }

  Future<void> disable() async {
    if (_address == null) return;
    await i2c.write(_address!, [controlPowerOff], commandBit | registerControl);
  }

  Future<void> setGainAndTiming(int gain, int timing) async {
    if (_address == null) return;
    _gain = gain;
    _timing = timing;
    await i2c.write(_address!, [_gain | _timing], commandBit | registerTiming);
  }

  Future<Map<String, double>> getRawData() async {
    if (_address == null) throw Exception("Sensor not initialized");

    try {
      List<int> infraList = await i2c.readBulk(
          _address!, commandBit | wordBit | registerChan1Low, 2);
      List<int> fullList = await i2c.readBulk(
          _address!, commandBit | wordBit | registerChan0Low, 2);

      if (infraList.length >= 2 && fullList.length >= 2) {
        int fullInt = ((fullList[1] & 0xFF) << 8) | (fullList[0] & 0xFF);
        int infraInt = ((infraList[1] & 0xFF) << 8) | (infraList[0] & 0xFF);

        fullSpectrum = fullInt.toDouble();
        infrared = infraInt.toDouble();
        visible = (fullInt - infraInt).toDouble();

        return {
          'full': fullSpectrum,
          'infrared': infrared,
          'visible': visible,
        };
      } else {
        throw Exception("Incomplete data received from TSL2561");
      }
    } catch (e) {
      logger.e("Error getting raw data: $e");
      rethrow;
    }
  }
}
