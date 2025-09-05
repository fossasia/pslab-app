import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class ADS1115 {
  static const String tag = "ADS1115";
  static const int address = 0x48;

  static const int regPointerConvert = 0;
  static const int regPointerConfig = 1;
  static const int regPointerLowthresh = 2;
  static const int regPointerHithresh = 3;

  static const int regConfigOsSingle = 0x8000;
  static const int regConfigOsBusy = 0x0000;
  static const int regConfigOsNotbusy = 0x8000;

  static const int regConfigMuxSingle0 = 0x4000;
  static const int regConfigMuxSingle1 = 0x5000;
  static const int regConfigMuxSingle2 = 0x6000;
  static const int regConfigMuxSingle3 = 0x7000;
  static const int regConfigMuxDiff01 = 0x0000;
  static const int regConfigMuxDiff23 = 0x3000;

  static const int regConfigPga6144v = 0 << 9;
  static const int regConfigPga4096v = 1 << 9;
  static const int regConfigPga2048v = 2 << 9;
  static const int regConfigPga1024v = 3 << 9;
  static const int regConfigPga512v = 4 << 9;
  static const int regConfigPga256v = 5 << 9;

  static const int regConfigModeContin = 0 << 8;
  static const int regConfigModeSingle = 1 << 8;

  static const int regConfigDr8sps = 0 << 5;
  static const int regConfigDr16sps = 1 << 5;
  static const int regConfigDr32sps = 2 << 5;
  static const int regConfigDr64sps = 3 << 5;
  static const int regConfigDr128sps = 4 << 5;
  static const int regConfigDr250sps = 5 << 5;
  static const int regConfigDr475sps = 6 << 5;
  static const int regConfigDr860sps = 7 << 5;

  static const int regConfigCqueNone = 0x0003;
  static const int regConfigClatNonlat = 0x0000;
  static const int regConfigCpolActvlow = 0x0000;
  static const int regConfigCmodeTrad = 0x0000;

  final I2C i2c;

  String _channel = "UNI_0";
  String _gain = "GAIN_ONE";
  int _rate = 128;

  final Map<String, int> _gains = {
    "GAIN_TWOTHIRDS": regConfigPga6144v,
    "GAIN_ONE": regConfigPga4096v,
    "GAIN_TWO": regConfigPga2048v,
    "GAIN_FOUR": regConfigPga1024v,
    "GAIN_EIGHT": regConfigPga512v,
    "GAIN_SIXTEEN": regConfigPga256v,
  };

  final Map<String, double> _gainScaling = {
    "GAIN_TWOTHIRDS": 0.1875,
    "GAIN_ONE": 0.125,
    "GAIN_TWO": 0.0625,
    "GAIN_FOUR": 0.03125,
    "GAIN_EIGHT": 0.015625,
    "GAIN_SIXTEEN": 0.0078125,
  };

  final Map<String, String> _typeSelection = {
    "UNI_0": "0",
    "UNI_1": "1",
    "UNI_2": "2",
    "UNI_3": "3",
    "DIFF_01": "01",
    "DIFF_23": "23",
  };

  final Map<int, int> _sdrSelection = {
    8: regConfigDr8sps,
    16: regConfigDr16sps,
    32: regConfigDr32sps,
    64: regConfigDr64sps,
    128: regConfigDr128sps,
    250: regConfigDr250sps,
    475: regConfigDr475sps,
    860: regConfigDr860sps,
  };

  ADS1115._(this.i2c);

  static Future<ADS1115> create(I2C i2c, ScienceLab scienceLab) async {
    final ads1115 = ADS1115._(i2c);
    await ads1115._initialize(scienceLab);
    return ads1115;
  }

  Future<void> _initialize(ScienceLab scienceLab) async {
    if (!scienceLab.isConnected()) {
      throw Exception("ScienceLab not connected");
    }

    try {
      setGain("GAIN_ONE");
      setChannel("UNI_0");
      setDataRate(128);

      logger.d(
          "ADS1115 initialized with gain: $_gain, channel: $_channel, rate: $_rate");
    } catch (e) {
      logger.e("Error initializing ADS1115: $e");
      rethrow;
    }
  }

  Future<int> _readRegister(int register) async {
    try {
      List<int> data = await i2c.readBulk(address, register, 2);
      if (data.length < 2) {
        throw Exception(
            "Expected 2 bytes but got ${data.length} from register $register");
      }
      return ((data[0] & 0xFF) << 8) | (data[1] & 0xFF);
    } catch (e) {
      logger.e("Error reading register $register: $e");
      rethrow;
    }
  }

  Future<void> _writeRegister(int register, int value) async {
    try {
      await i2c.write(address, [(value >> 8) & 0xFF, value & 0xFF], register);
    } catch (e) {
      logger.e("Error writing register $register: $e");
      rethrow;
    }
  }

  void setGain(String gain) {
    if (_gains.containsKey(gain)) {
      _gain = gain;
    } else {
      logger.w("Invalid gain: $gain");
    }
  }

  void setChannel(String channel) {
    if (_typeSelection.containsKey(channel)) {
      _channel = channel;
    } else {
      logger.w("Invalid channel: $channel");
    }
  }

  void setDataRate(int rate) {
    if (_sdrSelection.containsKey(rate)) {
      _rate = rate;
    } else {
      logger.w("Invalid data rate: $rate");
    }
  }

  String get currentGain => _gain;
  String get currentChannel => _channel;
  int get currentRate => _rate;

  Future<double> _readADCSingleEnded(int chan) async {
    if (chan > 3) {
      return -1;
    }

    try {
      int config = regConfigCqueNone |
          regConfigClatNonlat |
          regConfigCpolActvlow |
          regConfigCmodeTrad |
          regConfigModeSingle |
          (_sdrSelection[_rate] ?? regConfigDr128sps);

      config = config | (_gains[_gain] ?? regConfigPga4096v);

      switch (chan) {
        case 0:
          config = config | regConfigMuxSingle0;
          break;
        case 1:
          config = config | regConfigMuxSingle1;
          break;
        case 2:
          config = config | regConfigMuxSingle2;
          break;
        case 3:
          config = config | regConfigMuxSingle3;
          break;
      }

      config = config | regConfigOsSingle;

      await _writeRegister(regPointerConfig, config);

      int delayMs = ((1.0 / _rate + 0.002) * 1000).round();
      await Future.delayed(Duration(milliseconds: delayMs));

      int rawValue = await _readRegister(regPointerConvert);

      if (rawValue >= 0x8000) {
        rawValue -= 0x10000;
      }

      return rawValue * (_gainScaling[_gain] ?? 0.125);
    } catch (e) {
      logger.e("Error reading ADC single ended: $e");
      rethrow;
    }
  }

  Future<double> _readADCDifferential(String chan) async {
    try {
      int config = regConfigCqueNone |
          regConfigClatNonlat |
          regConfigCpolActvlow |
          regConfigCmodeTrad |
          regConfigModeSingle |
          (_sdrSelection[_rate] ?? regConfigDr128sps);

      config = config | (_gains[_gain] ?? regConfigPga4096v);

      if (chan == "01") {
        config = config | regConfigMuxDiff01;
      } else if (chan == "23") {
        config = config | regConfigMuxDiff23;
      }

      config = config | regConfigOsSingle;

      await _writeRegister(regPointerConfig, config);

      int delayMs = ((1.0 / _rate + 0.002) * 1000).round();
      await Future.delayed(Duration(milliseconds: delayMs));

      int rawValue = await _readRegister(regPointerConvert);

      if (rawValue >= 0x8000) {
        rawValue -= 0x10000;
      }

      return rawValue * (_gainScaling[_gain] ?? 0.125);
    } catch (e) {
      logger.e("Error reading ADC differential: $e");
      rethrow;
    }
  }

  Future<int> getRaw() async {
    try {
      String? chan = _typeSelection[_channel];
      if (chan == null) {
        throw Exception("Invalid channel: $_channel");
      }

      double result;
      if (_channel.contains("UNI")) {
        result = await _readADCSingleEnded(int.parse(chan));
      } else if (_channel.contains("DIFF")) {
        result = await _readADCDifferential(chan);
      } else {
        throw Exception("Unknown channel type: $_channel");
      }

      return result.round();
    } catch (e) {
      logger.e("Error getting raw data: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRawData() async {
    try {
      int rawValue = await getRaw();
      return {
        'voltage': rawValue.toDouble(),
        'channel': _channel,
        'gain': _gain,
        'rate': _rate,
      };
    } catch (e) {
      logger.e("Error getting raw data: $e");
      rethrow;
    }
  }
}
