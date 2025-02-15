class OscillscopeAxesScale {
  late double _yAxisScale;
  late double _yAxisScaleMin;
  late double _yAxisScaleMax;
  late double _xAxisScale;

  OscillscopeAxesScale() {
    _yAxisScale = 16;
    _yAxisScaleMin = -16;
    _yAxisScaleMax = 16;
    _xAxisScale = 875;
  }

  double get yAxisScale => _yAxisScale;
  double get yAxisScaleMin => _yAxisScaleMin;
  double get yAxisScaleMax => _yAxisScaleMax;
  double get xAxisScale => _xAxisScale;

  void setYAxisScale(double value) {
    _yAxisScale = value;
    _yAxisScaleMax = value;
    _yAxisScaleMin = -value;
  }

  void setYAxisScaleMin(double value) {
    _yAxisScaleMin = value;
  }

  void setYAxisScaleMax(double value) {
    _yAxisScaleMax = value;
  }

  void setXAxisScale(double value) {
    _xAxisScale = value;
  }

  double getTimebaseInterval() {
    switch (_xAxisScale) {
      case 875.00:
        return 100;
      case 1000.00:
        return 0.2;
      case 2000.00:
        return 0.3;
      case 4000.00:
        return 0.7;
      case 8000.00:
        return 1;
      case 25600.00:
        return 4;
      case 38400.00:
        return 10;
      case 51200.00:
        return 10;
      case 102400.00:
        return 20;
      default:
        return _xAxisScale / 5000;
    }
  }
}
