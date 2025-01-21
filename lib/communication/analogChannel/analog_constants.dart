class AnalogConstants {
  List<double> gains = [1, 2, 4, 5, 8, 10, 16, 32, 1 / 11];
  List<String> allAnalogChannels = [
    'CH1',
    'CH2',
    'CH3',
    'MIC',
    'CAP',
    'RES',
    'VOL',
  ];
  List<String> biPolars = [
    'CH1',
    'CH2',
    'CH3',
    'MIC',
  ];
  Map<String, List<double>> inputRanges = {};
  Map<String, int> picADCMultiplex = {};

  AnalogConstants() {
    inputRanges = {
      "CH1": [16.5, -16.5],
      "CH2": [16.5, -16.5],
      "CH3": [-3.3, 3.3],
      "MIC": [-3.3, 3.3],
      "CAP": [0, 3.3],
      "RES": [0, 3.3],
      "VOL": [0, 3.3],
    };

    picADCMultiplex = {
      "CH1": 3,
      "CH2": 0,
      "CH3": 1,
      "MIC": 2,
      "AN4": 4,
      "RES": 7,
      "CAP": 5,
      "VOL": 8,
    };
  }
}
