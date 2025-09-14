import 'package:pslab/communication/peripherals/i2c.dart';

class BH1750 {
  final String tag = "BH1750";

  final int powerOn = 0x01;
  final int reset = 0x07;
  final int res1000mLx = 0x10;
  final int res500mLx = 0x11;
  final int res4000mLx = 0x13;

  final I2C i2c;

  final List<int> gainChoices = [0x11, 0x10, 0x13];
  final List<String> gainLiteralChoices = ["500mLx", "1000mLx", "4000mLx"];
  int gain = 0;
  final List<double> scaling = [2, 1, 0.25];

  static const int numPlots = 1;
  static const List<String> plotNames = ["Lux"];
  final int address = 0x23;
  final String name = "Luminosity";

  BH1750(this.i2c) {
    init();
  }

  void init() {
    i2c.writeBulk(address, [res500mLx]);
  }

  void setRange(String g) {
    int gainIndex = gainLiteralChoices.indexOf(g);
    if (gainIndex >= 0) {
      i2c.writeBulk(address, [gainChoices[gainIndex]]);
    }
  }

  Future<List<int>> getVals(int numBytes) async {
    return await i2c.simpleRead(address, numBytes);
  }

  Future<double> getRaw() async {
    List<int> vals = await getVals(2);
    if (vals.length == 3) {
      return ((vals[0] << 8) | vals[1]) / 1.2;
    } else {
      return 0.0;
    }
  }
}
