import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

typedef PackageInfoLoader = Future<PackageInfo> Function();

Future<String> resolveAboutUsVersion({
  PackageInfoLoader? packageInfoLoader,
  bool? isLinux,
  String? resolvedExecutable,
}) async {
  try {
    final packageInfo =
        await (packageInfoLoader ?? PackageInfo.fromPlatform)();

    if (packageInfo.version.isNotEmpty) {
      return packageInfo.version;
    }

    final versionFromBundle = await _loadLinuxBundleVersion(
      isLinux: isLinux,
      resolvedExecutable: resolvedExecutable,
    );
    if (versionFromBundle.isNotEmpty) {
      return versionFromBundle;
    }

    return packageInfo.buildNumber;
  } catch (_) {
    final versionFromBundle = await _loadLinuxBundleVersion(
      isLinux: isLinux,
      resolvedExecutable: resolvedExecutable,
    );
    return versionFromBundle.isNotEmpty ? versionFromBundle : '';
  }
}

Future<String> _loadLinuxBundleVersion({
  bool? isLinux,
  String? resolvedExecutable,
}) async {
  if (!(isLinux ?? Platform.isLinux)) {
    return '';
  }

  final executablePath = resolvedExecutable ?? Platform.resolvedExecutable;
  final executableParent = Directory(executablePath).parent;
  final candidatePaths = <String>[
    '${executableParent.path}/data/flutter_assets/version.json',
    '${executableParent.parent.path}/share/pslab/flutter_assets/version.json',
  ];

  for (final candidatePath in candidatePaths) {
    final versionFile = File(candidatePath);
    if (!await versionFile.exists()) {
      continue;
    }

    try {
      final jsonContent = jsonDecode(await versionFile.readAsString())
          as Map<String, dynamic>;
      final version = jsonContent['version'];
      if (version is String && version.isNotEmpty) {
        return version;
      }
    } catch (_) {}
  }

  return '';
}