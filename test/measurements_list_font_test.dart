import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/view/widgets/measurements_list.dart';

void main() {
  Future<double> pumpAndGetFontSize(
    WidgetTester tester, {
    required Size windowSize,
    required double boxWidth,
  }) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: boxWidth,
            child: const MeasurementsList(dataParamsChannels: ['CH1']),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.textContaining('Vpp:').first);
    return text.style!.fontSize!;
  }

  testWidgets(
    'measurement font size depends on the widget box, not the window',
    (tester) async {
      final fontSmallWindow = await pumpAndGetFontSize(
        tester,
        windowSize: const Size(800, 600),
        boxWidth: 200,
      );

      final fontLargeWindow = await pumpAndGetFontSize(
        tester,
        windowSize: const Size(2400, 1400),
        boxWidth: 200,
      );

      expect(fontSmallWindow, fontLargeWindow);
    },
  );
}
