import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/communication/handler/wifi_comms_handler.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/science_lab_common.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeScienceLab extends ScienceLab {
  _FakeScienceLab(this.version) : super(WifiCommsHandler());

  final String version;

  @override
  Future<String> getVersion() async => version;

  @override
  bool isConnected() => false;
}

class _FakeScienceLabCommon extends ScienceLabCommon {
  _FakeScienceLabCommon(this.scienceLab) : super(WifiCommsHandler());

  final ScienceLab scienceLab;

  @override
  ScienceLab getScienceLab() => scienceLab;

  @override
  Future<bool> openWiFiDevice() async => true;
}

BoardStateProvider _providerForVersion(String version) {
  final scienceLab = _FakeScienceLab(version);
  getIt.registerSingleton<ScienceLab>(scienceLab);
  getIt.registerSingleton<ScienceLabCommon>(_FakeScienceLabCommon(scienceLab));
  return BoardStateProvider();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
  });

  test('reports a device that fails the version handshake', () async {
    final provider = _providerForVersion('garbage');

    await provider.initializeWiFi();

    expect(provider.pslabIsConnected, isFalse);
    expect(provider.unresponsiveDeviceNotifier.value, isTrue);
  });

  test('reports every failed handshake, not just the first', () async {
    final provider = _providerForVersion('');
    var reports = 0;
    provider.unresponsiveDeviceNotifier.addListener(() {
      if (provider.unresponsiveDeviceNotifier.value) reports++;
    });

    await provider.initializeWiFi();
    await provider.initializeWiFi();

    expect(reports, 2);
  });

  test('does not report a PSLab that answers the handshake', () async {
    final provider = _providerForVersion('PSLab V6');

    await provider.initializeWiFi();

    expect(provider.pslabIsConnected, isTrue);
    expect(provider.unresponsiveDeviceNotifier.value, isFalse);
  });
}
