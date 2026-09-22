import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/data_service.dart';
import 'package:pslab/others/recording_duration.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/robotic_arm_state_provider.dart';

void main() {
  late AppLocalizations appLocalizations;

  setUp(() async {
    await getIt.reset();
    appLocalizations = lookupAppLocalizations(const Locale('en'));
    registerAppLocalizations(appLocalizations);
  });

  test('timeline duration matches the selected timeline length', () {
    final provider = RoboticArmStateProvider();
    expect(provider.timelineDuration, const Duration(minutes: 1));

    provider.setSelectedDuration(appLocalizations.duration2Min);
    expect(provider.timelineDuration, const Duration(minutes: 2));
  });

  test('saved timelines record the timeline length, not the step count', () {
    final provider = RoboticArmStateProvider();
    final data = provider.generateExportData();

    DataService().writeMetaData('robotic arm', data,
        recordingDuration: provider.timelineDuration);

    expect(computeRecordingDurationFromData(data), const Duration(minutes: 1));
  });
}
