import 'dart:typed_data';

interface class CommunicationHandler {
  bool connected = false;
  bool deviceFound = false;

  Future<void> initialize() {
    throw UnimplementedError();
  }

  Future<void> open() async {
    throw UnimplementedError();
  }

  bool isDeviceFound() {
    throw UnimplementedError();
  }

  bool isConnected() {
    throw UnimplementedError();
  }

  void close() {
    throw UnimplementedError();
  }

  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    throw UnimplementedError();
  }

  void write(Uint8List src, int timeoutMillis) {
    throw UnimplementedError();
  }
}
