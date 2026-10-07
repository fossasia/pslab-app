import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/packet_handler.dart';
import 'package:pslab/communication/peripherals/uart.dart';

class _FakeCommunicationHandler implements CommunicationHandler {
  final List<int> writes = [];
  final List<int> responses = [];

  @override
  bool connected = true;

  @override
  bool deviceFound = true;

  @override
  void close() => connected = false;

  @override
  Future<void> initialize() async {}

  @override
  bool isConnected() => connected;

  @override
  bool isDeviceFound() => deviceFound;

  @override
  Future<void> open({int overrideBaud = 1000000}) async => connected = true;

  @override
  Future<int> read(
    Uint8List dest,
    int bytesToRead,
    int timeoutMillis,
  ) async {
    final count = bytesToRead.clamp(0, responses.length);
    for (var index = 0; index < count; index++) {
      dest[index] = responses.removeAt(0);
    }
    return count;
  }

  @override
  void write(Uint8List src, int timeoutMillis) => writes.addAll(src);
}

void main() {
  late _FakeCommunicationHandler handler;
  late Uart2 uart;

  setUp(() {
    handler = _FakeCommunicationHandler();
    PacketHandler.boardType = BoardType.binary;
    uart = Uart2(PacketHandler(500, handler));
  });

  test('configures 9600 baud using the UART clock divider', () async {
    handler.responses.add(1);

    await uart.configure(9600);

    expect(handler.writes, [5, 4, 0x82, 0x06]);
  });

  test('rejects a failed baud-rate acknowledgement', () async {
    handler.responses.add(3);

    await expectLater(uart.configure(9600), throwsStateError);
  });

  test('reads UART status and one byte without bulk length fields', () async {
    handler.responses.addAll([1, 0xaa]);

    expect(await uart.hasData(), isTrue);
    expect(await uart.readByte(), 0xaa);
    expect(handler.writes, [5, 8, 5, 6]);
  });

  test('writes each UART byte as an individual firmware command', () async {
    await uart.write([0xaa, 0xb4]);

    expect(handler.writes, [5, 1, 0xaa, 5, 1, 0xb4]);
  });

  test('consumes write acknowledgements required by legacy firmware', () async {
    handler.responses.addAll([1, 1]);
    final legacyUart = Uart2(
      PacketHandler(500, handler),
      requiresWriteAcknowledgement: true,
    );

    await legacyUart.write([0xaa, 0xb4]);

    expect(handler.responses, isEmpty);
  });
}
