import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/packet_handler.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/sensors/mlx90614.dart';
import 'package:pslab/communication/socket_client.dart';
import 'package:pslab/others/science_lab_common.dart';

// Manual Mock for I2C
class FakeCommunicationHandler implements CommunicationHandler {
  @override
  bool connected = false;
  @override
  bool deviceFound = false;
  @override
  bool isConnected() => false;
  @override
  bool isDeviceFound() => false;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> open() async {}
  @override
  void close() {}
  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async =>
      0;
  @override
  void write(Uint8List src, int timeoutMillis) {}
}

class FakePacketHandler extends PacketHandler {
  FakePacketHandler() : super(0, FakeCommunicationHandler());

  @override
  void sendByte(int val) {}
  @override
  void sendInt(int val) {}
  @override
  Future<int> getAcknowledgement() async => 0;
  @override
  Future<int> getByte() async => 0;
  @override
  Future<int> getInt() async => 0;
  @override
  Future<int> read(Uint8List buffer, int length) async => 0;
}

class MockI2C extends I2C {
  List<int>? nextReadBulkResult;
  Exception? nextReadBulkError;

  int readBulkCallCount = 0;
  int lastDeviceAddress = 0;
  int lastRegisterAddress = 0;
  int lastBytesToRead = 0;

  List<Map<String, int>> readBulkCalls = [];
  Map<int, List<int>> registerResults = {};
  List<List<int>>? sequentialResults;
  int _sequentialIndex = 0;

  MockI2C() : super(FakePacketHandler());

  @override
  Future<List<int>> readBulk(
    int deviceAddress,
    int registerAddress,
    int bytesToRead,
  ) async {
    readBulkCallCount++;
    lastDeviceAddress = deviceAddress;
    lastRegisterAddress = registerAddress;
    lastBytesToRead = bytesToRead;
    readBulkCalls.add({
      'deviceAddress': deviceAddress,
      'registerAddress': registerAddress,
      'bytesToRead': bytesToRead,
    });

    if (nextReadBulkError != null) {
      throw nextReadBulkError!;
    }

    if (sequentialResults != null &&
        _sequentialIndex < sequentialResults!.length) {
      return sequentialResults![_sequentialIndex++];
    }

    if (registerResults.containsKey(registerAddress)) {
      return registerResults[registerAddress]!;
    }

    return nextReadBulkResult ?? [0x98, 0x3A, 0x00];
  }
}

void main() {
  late MockI2C mockI2C;
  final getIt = GetIt.instance;

  setUp(() {
    getIt.reset();
    final fakeCommunicationHandler = FakeCommunicationHandler();
    getIt.registerLazySingleton<SocketClient>(() => SocketClient());
    getIt.registerLazySingleton<ScienceLabCommon>(
      () => ScienceLabCommon(fakeCommunicationHandler),
    );
    mockI2C = MockI2C();
  });

  tearDown(() {
    getIt.reset();
  });

  group('MLX90614 Constants', () {
    test('I2C address is 0x5A', () {
      expect(MLX90614.address, 0x5A);
      expect(MLX90614.address, 90);
    });

    test('sensor name is set correctly', () {
      expect(MLX90614.name, 'IR Temperature MLX90614');
    });

    test('numPlots is 2', () {
      expect(MLX90614.numPlots, 2);
    });

    test('plotNames has exactly 2 entries', () {
      expect(MLX90614.plotNames.length, 2);
    });

    test('plotNames has correct values', () {
      expect(MLX90614.plotNames, ['Object Temp', 'Ambient Temp']);
    });

    test('tag is MLX90614', () {
      expect(MLX90614.tag, 'MLX90614');
    });
  });

  group('MLX90614 Initialization', () {
    test('create returns MLX90614 instance', () async {
      final sensor = await MLX90614.create(mockI2C);
      expect(sensor, isA<MLX90614>());
    });

    test('create stores the I2C reference', () async {
      final sensor = await MLX90614.create(mockI2C);
      expect(sensor.i2c, same(mockI2C));
    });

    test('multiple creates return different instances', () async {
      final s1 = await MLX90614.create(mockI2C);
      final s2 = await MLX90614.create(mockI2C);
      expect(s1, isNot(same(s2)));
    });
  });

  group('readObjectTemperature', () {
    test('reads from register 0x07', () async {
      final sensor = await MLX90614.create(mockI2C);
      await sensor.readObjectTemperature();
      expect(mockI2C.readBulkCalls.length, 1);
      expect(mockI2C.readBulkCalls[0]['registerAddress'], 0x07);
    });

    test('uses device address 0x5A', () async {
      final sensor = await MLX90614.create(mockI2C);
      await sensor.readObjectTemperature();
      expect(mockI2C.lastDeviceAddress, 0x5A);
    });

    test('requests exactly 3 bytes', () async {
      final sensor = await MLX90614.create(mockI2C);
      await sensor.readObjectTemperature();
      expect(mockI2C.lastBytesToRead, 3);
    });

    test('converts raw 15000 to 26.85C', () async {
      mockI2C.nextReadBulkResult = [0x98, 0x3A, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(26.85, 0.01));
    });

    test('returns double type', () async {
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, isA<double>());
    });
  });

  group('readAmbientTemperature', () {
    test('reads from register 0x06', () async {
      final sensor = await MLX90614.create(mockI2C);
      await sensor.readAmbientTemperature();
      expect(mockI2C.readBulkCalls.length, 1);
      expect(mockI2C.readBulkCalls[0]['registerAddress'], 0x06);
    });

    test('uses device address 0x5A', () async {
      final sensor = await MLX90614.create(mockI2C);
      await sensor.readAmbientTemperature();
      expect(mockI2C.lastDeviceAddress, 0x5A);
    });

    test('requests exactly 3 bytes', () async {
      final sensor = await MLX90614.create(mockI2C);
      await sensor.readAmbientTemperature();
      expect(mockI2C.lastBytesToRead, 3);
    });

    test('correctly converts raw value', () async {
      mockI2C.nextReadBulkResult = [0x4C, 0x3A, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readAmbientTemperature();
      expect(temp, closeTo(25.33, 0.01));
    });

    test('uses different register than object', () async {
      mockI2C.registerResults = {
        0x07: [0x98, 0x3A, 0x00],
        0x06: [0x4C, 0x3A, 0x00],
      };
      final sensor = await MLX90614.create(mockI2C);
      await sensor.readObjectTemperature();
      await sensor.readAmbientTemperature();
      expect(mockI2C.readBulkCalls[0]['registerAddress'], 0x07);
      expect(mockI2C.readBulkCalls[1]['registerAddress'], 0x06);
    });
  });

  group('Temperature Conversion Accuracy', () {
    test('absolute zero raw=0', () async {
      mockI2C.nextReadBulkResult = [0x00, 0x00, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(-273.15, 0.01));
    });

    test('freezing point 0C', () async {
      mockI2C.nextReadBulkResult = [0x5A, 0x35, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(0.01, 0.1));
    });

    test('room temperature 25C', () async {
      mockI2C.nextReadBulkResult = [0x3C, 0x3A, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(25.01, 0.1));
    });

    test('body temperature 37C', () async {
      mockI2C.nextReadBulkResult = [0x94, 0x3C, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(37.01, 0.1));
    });

    test('boiling point 100C', () async {
      mockI2C.nextReadBulkResult = [0xE2, 0x48, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(100.01, 0.1));
    });

    test('sensor min -40C', () async {
      mockI2C.nextReadBulkResult = [0x8A, 0x2D, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(-40.0, 0.1));
    });

    test('high temp 300C', () async {
      mockI2C.nextReadBulkResult = [0xF2, 0x6F, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(300.01, 0.1));
    });
  });

  group('PEC byte handling', () {
    test('PEC byte does not affect result', () async {
      final sensor = await MLX90614.create(mockI2C);

      mockI2C.nextReadBulkResult = [0x98, 0x3A, 0x00];
      final t1 = await sensor.readObjectTemperature();

      mockI2C.nextReadBulkResult = [0x98, 0x3A, 0xFF];
      final t2 = await sensor.readObjectTemperature();

      mockI2C.nextReadBulkResult = [0x98, 0x3A, 0xAB];
      final t3 = await sensor.readObjectTemperature();

      expect(t1, equals(t2));
      expect(t2, equals(t3));
    });
  });

  group('getRawData', () {
    test('returns map with both temperature keys', () async {
      mockI2C.registerResults = {
        0x07: [0x98, 0x3A, 0x00],
        0x06: [0x4C, 0x3A, 0x00],
      };
      final sensor = await MLX90614.create(mockI2C);
      final data = await sensor.getRawData();
      expect(data.containsKey('objectTemperature'), isTrue);
      expect(data.containsKey('ambientTemperature'), isTrue);
    });

    test('returns map with exactly 2 entries', () async {
      mockI2C.registerResults = {
        0x07: [0x98, 0x3A, 0x00],
        0x06: [0x4C, 0x3A, 0x00],
      };
      final sensor = await MLX90614.create(mockI2C);
      final data = await sensor.getRawData();
      expect(data.length, 2);
    });

    test('values are correct', () async {
      mockI2C.registerResults = {
        0x07: [0x98, 0x3A, 0x00],
        0x06: [0x4C, 0x3A, 0x00],
      };
      final sensor = await MLX90614.create(mockI2C);
      final data = await sensor.getRawData();
      expect(data['objectTemperature'], closeTo(26.85, 0.01));
      expect(data['ambientTemperature'], closeTo(25.33, 0.01));
    });

    test('makes exactly 2 I2C reads', () async {
      mockI2C.registerResults = {
        0x07: [0x98, 0x3A, 0x00],
        0x06: [0x4C, 0x3A, 0x00],
      };
      final sensor = await MLX90614.create(mockI2C);
      await sensor.getRawData();
      expect(mockI2C.readBulkCallCount, 2);
    });

    test('reads object before ambient', () async {
      mockI2C.registerResults = {
        0x07: [0x98, 0x3A, 0x00],
        0x06: [0x4C, 0x3A, 0x00],
      };
      final sensor = await MLX90614.create(mockI2C);
      await sensor.getRawData();
      expect(mockI2C.readBulkCalls[0]['registerAddress'], 0x07);
      expect(mockI2C.readBulkCalls[1]['registerAddress'], 0x06);
    });
  });

  group('Error Handling', () {
    test('throws on fewer than 3 bytes', () async {
      mockI2C.nextReadBulkResult = [0x98, 0x3A];
      final sensor = await MLX90614.create(mockI2C);
      expect(() => sensor.readObjectTemperature(), throwsA(isA<Exception>()));
    });

    test('throws on empty list', () async {
      mockI2C.nextReadBulkResult = [];
      final sensor = await MLX90614.create(mockI2C);
      expect(() => sensor.readObjectTemperature(), throwsA(isA<Exception>()));
    });

    test('throws on only 1 byte', () async {
      mockI2C.nextReadBulkResult = [0x98];
      final sensor = await MLX90614.create(mockI2C);
      expect(() => sensor.readObjectTemperature(), throwsA(isA<Exception>()));
    });

    test('rethrows I2C errors', () async {
      mockI2C.nextReadBulkError = Exception('I2C bus error');
      final sensor = await MLX90614.create(mockI2C);
      expect(() => sensor.readObjectTemperature(), throwsA(isA<Exception>()));
    });

    test('ambient also throws on I2C error', () async {
      mockI2C.nextReadBulkError = Exception('NACK from slave');
      final sensor = await MLX90614.create(mockI2C);
      expect(() => sensor.readAmbientTemperature(), throwsA(isA<Exception>()));
    });

    test('getRawData throws on read fail', () async {
      mockI2C.nextReadBulkError = Exception('Read failed');
      final sensor = await MLX90614.create(mockI2C);
      expect(() => sensor.getRawData(), throwsA(isA<Exception>()));
    });
  });

  group('Sequential Reads', () {
    test('can read multiple times', () async {
      mockI2C.nextReadBulkResult = [0x98, 0x3A, 0x00];
      final sensor = await MLX90614.create(mockI2C);

      final t1 = await sensor.readObjectTemperature();
      final t2 = await sensor.readObjectTemperature();
      final t3 = await sensor.readObjectTemperature();

      expect(t1, equals(t2));
      expect(t2, equals(t3));
      expect(mockI2C.readBulkCallCount, 3);
    });

    test('temps can change between reads', () async {
      mockI2C.sequentialResults = [
        [0x98, 0x3A, 0x00],
        [0x4C, 0x3A, 0x00],
      ];
      final sensor = await MLX90614.create(mockI2C);

      final t1 = await sensor.readObjectTemperature();
      final t2 = await sensor.readObjectTemperature();

      expect(t1, isNot(equals(t2)));
      expect(t1, closeTo(26.85, 0.01));
      expect(t2, closeTo(25.33, 0.01));
    });
  });

  group('Byte Masking', () {
    test('LSB uses full byte', () async {
      mockI2C.nextReadBulkResult = [0x98, 0x3A, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(26.85, 0.01));
    });

    test('MSB uses full byte', () async {
      mockI2C.nextReadBulkResult = [0x00, 0xFF, 0x00];
      final sensor = await MLX90614.create(mockI2C);
      final temp = await sensor.readObjectTemperature();
      expect(temp, closeTo(1032.45, 0.01));
    });
  });
}
