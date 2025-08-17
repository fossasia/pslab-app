// ignore_for_file: avoid_print

import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final deviceName = Platform.environment['DEVICE_NAME'] ?? 'unknown_device';
  final formattedDeviceName = deviceName.replaceAll(RegExp(r'\s+'), '_');
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes,
        [Map<String, Object?>? args]) async {
      final filePath = 'screenshots/$formattedDeviceName-$screenshotName.png';
      print('Writing screenshot to $filePath');

      final File image = await File(filePath).create(recursive: true);
      image.writeAsBytesSync(screenshotBytes);
      return true;
    },
  );
}
