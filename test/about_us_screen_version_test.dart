import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pslab/view/about_us_version_resolver.dart';

void main() {
  test('uses package_info_plus version when available', () async {
    final version = await resolveAboutUsVersion(
      packageInfoLoader: () async => PackageInfo(
        appName: 'pslab',
        packageName: 'io.pslab',
        version: '1.2.3',
        buildNumber: '45',
      ),
      isLinux: false,
    );

    expect(version, '1.2.3');
  });

  test('falls back to linux bundle version json when package version is empty', () async {
    final tempDir = await Directory.systemTemp.createTemp('pslab-about-version-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final executablePath =
        '${tempDir.path}${Platform.pathSeparator}bin${Platform.pathSeparator}'
        'pslab';
    final versionFile = File(
      '${tempDir.path}${Platform.pathSeparator}bin${Platform.pathSeparator}'
      'data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}'
      'version.json',
    );
    await versionFile.create(recursive: true);
    await versionFile.writeAsString('{"version":"9.8.7"}');

    final version = await resolveAboutUsVersion(
      packageInfoLoader: () async => PackageInfo(
        appName: 'pslab',
        packageName: 'io.pslab',
        version: '',
        buildNumber: '45',
      ),
      isLinux: true,
      resolvedExecutable: executablePath,
    );

    expect(version, '9.8.7');
  });
}
