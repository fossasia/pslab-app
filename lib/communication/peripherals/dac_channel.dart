import 'package:data/polynomial.dart';
import 'package:data/type.dart';

class DACChannel {
  late String name;
  late int channum;
  late int offset;
  late List<double> range;
  late double slope;
  late double intercept;
  late Polynomial vToCode;
  late Polynomial codeToV;
  late int channelCode;
  late String calibrationEnabled;

  DACChannel(this.name, List<double> span, this.channum, this.channelCode) {
    range = span;
    slope = span[1] - span[0];
    intercept = span[0];
    vToCode = Polynomial.fromCoefficients(
        DataType.float, [3300.0 / slope, -3300.0 * intercept / slope]);
    codeToV = Polynomial.fromCoefficients(
        DataType.float, [slope / 3300.0, intercept]);
    calibrationEnabled = "false";
    offset = 0;
  }
}
