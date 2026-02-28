import 'dart:typed_data';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/socket_client.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/logger_service.dart';

class WifiCommunicationHandler implements CommunicationHandler {
  @override
  bool connected = false;

  @override
  bool deviceFound = false;

  final SocketClient _socketClient = getIt.get<SocketClient>();

  @override
  Future<void> initialize() async {
    // Nothing to initialize for WiFi; device discovery is manual (connect to AP)
    deviceFound = false;
  }

  @override
  Future<void> open() async {
    // Opening over WiFi is handled by SocketClient directly via connect flow.
    // Mark deviceFound true so UI can allow WiFi connection attempts.
    deviceFound = true;
    connected = _socketClient.isConnected();
  }

  @override
  bool isDeviceFound() => deviceFound;

  @override
  bool isConnected() => _socketClient.isConnected() || connected;

  @override
  void close() {
    _socketClient.setConnected(false);
    connected = false;
  }

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    if (!_socketClient.isConnected()) return -1;
    return await _socketClient.read(dest, bytesToRead, timeoutMillis);
  }

  @override
  void write(Uint8List src, int timeoutMillis) {
    if (!_socketClient.isConnected()) return;
    _socketClient.write(src, timeoutMillis);
  }
}
