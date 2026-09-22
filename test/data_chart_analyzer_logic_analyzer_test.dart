import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/others/data_chart_analyzer.dart';

void main() {
  final dataSets = [
    [const FlSpot(0, 0), const FlSpot(1, 1), const FlSpot(2, 0)],
    [const FlSpot(0, 1), const FlSpot(1, 0), const FlSpot(2, 1)],
  ];

  test('names Logic Analyzer series after their channels', () {
    final data = <List<dynamic>>[
      [
        'Timestamp',
        'DateTime',
        'Readings',
        'maxY',
        'minY',
        'Channels',
        'Edges',
        'Latitude',
        'Longitude'
      ],
      [
        '1000',
        'x',
        dataSets.toString(),
        '1.5',
        '-0.5',
        '[LA1, LA2]',
        '[EVERY EDGE, EVERY EDGE]',
        0,
        0
      ],
    ];

    expect(ScientificDataAnalyzer.analyze('logic analyzer', data).keys,
        ['LA1', 'LA2']);
  });

  test('still reads Oscilloscope channels from their column', () {
    final data = <List<dynamic>>[
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
      ['1000', 'x', dataSets.toString(), '[CH1, CH2]', 875, 16, 0, 0],
    ];

    expect(ScientificDataAnalyzer.analyze('oscilloscope', data).keys,
        ['CH1', 'CH2']);
  });
}
