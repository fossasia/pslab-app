import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/handler/comms_handler.dart';
import 'package:pslab/communication/packet_handler.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/science_lab_common.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/providers/locator.dart';

class FakeCommunicationHandler implements CommunicationHandler {
  @override
  bool connected = true;

  @override
  bool deviceFound = true;

  final writes = <List<int>>[];
  final responses = <List<int>>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> open({int overrideBaud = 1000000}) async {}

  @override
  bool isDeviceFound() => deviceFound;

  @override
  bool isConnected() => connected;

  @override
  void close() => connected = false;

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    final response = responses.removeAt(0);
    dest.setRange(0, response.length, response);
    return response.length;
  }

  @override
  void write(Uint8List src, int timeoutMillis) => writes.add(src.toList());
}

class FakeScienceLab extends ScienceLab {
  FakeScienceLab(super.communicationHandler);

  String reportedVersion = '';

  @override
  Future<String> getVersion() async => reportedVersion;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'recognizes both Mini USB identifiers without dropping legacy boards',
    () {
      expect(
        PSLabCommunicationHandler.supportedBoards.map(
          (board) => (board.vid, board.pid),
        ),
        containsAll([
          (0x2E8A, 0x0003),
          (0xCAFE, 0x4010),
          (0x10C4, 0xEA60),
          (1240, 223),
        ]),
      );
    },
  );

  test('SCPI commands use UTF-8 and a newline terminator', () async {
    final comms = FakeCommunicationHandler();
    final packets = PacketHandler(500, comms);

    await packets.sendScpiCommand('TEST é');

    expect(comms.writes.single, utf8.encode('TEST é\n'));
  });

  test('existing SCPI block writes preserve raw I2C payload bytes', () async {
    final comms = FakeCommunicationHandler();
    final packets = PacketHandler(500, comms);

    await packets.sendScpi('BUS:I2C:WRIT #11${String.fromCharCode(0xFF)}');

    expect(comms.writes.single.last, 10);
    expect(comms.writes.single[comms.writes.single.length - 3], 0xFF);
  });

  test('SCPI query decodes UTF-8 responses', () async {
    final comms = FakeCommunicationHandler();
    comms.responses.add(utf8.encode('PSLab Mini,é\r\n'));
    final packets = PacketHandler(500, comms);

    expect(await packets.queryScpi('*IDN?'), 'PSLab Mini,é');
    expect(comms.writes.single, utf8.encode('*IDN?\n'));
  });

  for (final name in ['PSLab Mini', 'PSLab Pico']) {
    test('identifies $name via SCPI without binary commands', () async {
      final comms = FakeCommunicationHandler();
      comms.responses.add(utf8.encode('$name,1.0\r\n'));
      final packets = PacketHandler(500, comms);

      expect(await packets.getVersion(), '$name,1.0');
      expect(PacketHandler.boardType, BoardType.scpi);
      expect(comms.writes, [utf8.encode('*IDN?\n')]);
    });
  }

  test('legacy handshake still uses binary commands after SCPI probe',
      () async {
    final comms = FakeCommunicationHandler();
    comms.responses.add([]);
    comms.responses.add(utf8.encode('PSLab V6\n'));
    final packets = PacketHandler(500, comms);

    expect(await packets.getVersion(), 'PSLab V6');
    expect(PacketHandler.boardType, BoardType.binary);
    expect(comms.writes.first, utf8.encode('*IDN?\n'));
    expect(comms.writes.skip(1).every((write) => write.length == 1), isTrue);
  });

  test('board state maps Mini and Pico to SCPI version 7', () async {
    SharedPreferences.setMockInitialValues({});
    final comms = FakeCommunicationHandler();
    final scienceLab = FakeScienceLab(comms);
    getIt.registerSingleton<ScienceLabCommon>(ScienceLabCommon(comms));
    getIt.registerSingleton<ScienceLab>(scienceLab);
    addTearDown(() async => getIt.reset());
    final provider = BoardStateProvider();
    addTearDown(provider.dispose);

    scienceLab.reportedVersion = 'FOSSASIA,PSLab Mini,1.0';
    await provider.setPSLabVersionIDs();
    expect(provider.pslabVersionID, 'PSLab Mini');
    expect(provider.pslabVersion, 7);

    scienceLab.reportedVersion = 'PSLab Pico,1.0';
    await provider.setPSLabVersionIDs();
    expect(provider.pslabVersionID, 'PSLab Pico');
    expect(provider.pslabVersion, 7);

    scienceLab.reportedVersion = 'PSLab V6';
    await provider.setPSLabVersionIDs();
    expect(provider.pslabVersionID, 'PSLab V6');
    expect(provider.pslabVersion, 6);

    scienceLab.reportedVersion = 'Unknown';
    await provider.setPSLabVersionIDs();
    expect(provider.pslabVersionID, 'Not Connected');
    expect(provider.pslabVersion, 0);
  });
}
