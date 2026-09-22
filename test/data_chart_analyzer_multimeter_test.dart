import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/others/data_chart_analyzer.dart';

void main() {
  test('analyzes the Multimeter reading column', () {
    final data = <List<dynamic>>[
      ['multimeter', '2026-09-22', '10:00:00', 2000],
      [
        'Timestamp',
        'DateTime',
        'Mode',
        'Reading',
        'Unit',
        'Latitude',
        'Longitude'
      ],
      ['1000', 'x', '0', '3.30', 'V', 0, 0],
      ['2000', 'x', '0', '1.20', 'V', 0, 0],
      ['3000', 'x', '0', '2.10', 'V', 0, 0],
    ];

    final results = ScientificDataAnalyzer.analyze('multimeter', data);

    expect(results.keys, ['Reading']);
    expect(results['Reading']!.max, 3.30);
    expect(results['Reading']!.min, 1.20);
    expect(results['Reading']!.mean, closeTo(2.2, 1e-9));
  });
}
