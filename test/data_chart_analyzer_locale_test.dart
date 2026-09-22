import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/others/data_chart_analyzer.dart';

void main() {
  final accelerometer = <List<dynamic>>[
    [
      'Timestamp',
      'DateTime',
      'ReadingsX',
      'ReadingsY',
      'ReadingsZ',
      'Latitude',
      'Longitude'
    ],
    ['1000', 'x', '1', '2', '3', 0, 0],
    ['2000', 'x', '2', '3', '4', 0, 0],
  ];
  final compass = <List<dynamic>>[
    [
      'Timestamp',
      'DateTime',
      'Bx',
      'By',
      'Bz',
      'Degree',
      'Latitude',
      'Longitude'
    ],
    ['1000', 'x', '1', '2', '3', '90', 0, 0],
    ['2000', 'x', '2', '3', '4', '91', 0, 0],
  ];
  final oscilloscope = <List<dynamic>>[
    [
      'Timestamp',
      'DateTime',
      'Readings',
      'Channels',
      'XAxisScale',
      'YAxisScale',
      'Latitude',
      'Longitude'
    ],
    [
      '1000',
      'x',
      '[[FlSpot(0.0, 1.0), FlSpot(1.0, 2.0)]]',
      '[CH1]',
      875,
      16,
      0,
      0
    ],
  ];

  // English, Italian and Hindi folder names for each instrument.
  for (final name in ['accelerometer', 'accelerometro', 'एक्सेलेरोमीटर']) {
    test('analyzes every accelerometer axis for "$name"', () {
      expect(ScientificDataAnalyzer.analyze(name, accelerometer).keys,
          ['ReadingsX', 'ReadingsY', 'ReadingsZ']);
    });
  }

  for (final name in ['compass', 'bussola', 'कंपास']) {
    test('analyzes every compass column for "$name"', () {
      expect(ScientificDataAnalyzer.analyze(name, compass).keys,
          ['Bx', 'By', 'Bz', 'Degree']);
    });
  }

  for (final name in ['oscilloscope', 'oscilloscopio', 'מתנד']) {
    test('parses oscilloscope channels for "$name"', () {
      expect(ScientificDataAnalyzer.analyze(name, oscilloscope).keys, ['CH1']);
    });
  }

  test('falls back to the name for files without a known header', () {
    final barometer = <List<dynamic>>[
      ['Timestamp', 'DateTime', 'RawPressure', 'RawTemperature'],
      ['1000', 'x', '20.5', '25.0'],
      ['2000', 'x', '21.0', '25.5'],
    ];
    expect(ScientificDataAnalyzer.analyze('barometer', barometer).keys,
        ['RawPressure', 'RawTemperature']);
  });

  test('resolves the instrument key from the headers', () {
    expect(ScientificDataAnalyzer.instrumentKey('accelerometro', accelerometer),
        'accelerometer');
    expect(
        ScientificDataAnalyzer.instrumentKey('Sound Meter', []), 'sound meter');
  });
}
