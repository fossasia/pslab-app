import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pslab/src/rust/api/simple.dart' as rust_api;
import 'package:pslab/others/logger_service.dart';
import 'base.dart';

class WifiCommsHandler implements CommunicationHandler {
  final String host;
  final int port;

  @override
  bool connected = false;

  @override
  bool deviceFound = false;

  WifiCommsHandler({this.host = "192.168.4.1", this.port = 80});

  @override
  Future<void> initialize() async {
    deviceFound = true;
  }

  @override
  Future<void> open() async {
    if (kIsWeb) {
      logger.e("Raw Wi-Fi TCP not supported on Web.");
      return;
    }

    try {
      rust_api.wifiConnect(host: host, port: port);
      connected = true;
      logger.i("Connected to PSLab via Wi-Fi (Rust Pipeline)");
    } catch (e) {
      connected = false;
      logger.e("Failed to connect via Wi-Fi: $e");
    }
  }

  @override
  bool isDeviceFound() => deviceFound;

  @override
  bool isConnected() => connected;

  @override
  void close() {
    if (!kIsWeb) {
      rust_api.wifiDisconnect();
    }
    connected = false;
    logger.i("Wi-Fi connection closed.");
  }

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    if (kIsWeb || !connected) return 0;

    try {
      final List<int> rustBuffer = await rust_api.wifiRead(
        bytesToRead: bytesToRead,
        timeoutMs: timeoutMillis,
      );

      int readLength = rustBuffer.length;
      if (readLength > 0) {
        dest.setRange(0, readLength, rustBuffer);
      }
      return readLength;
    } catch (e) {
      logger.e("Wi-Fi Read Error (Socket dropped): $e");

      connected = false;
      close();

      return 0;
    }
  }

  @override
  void write(Uint8List src, int timeoutMillis) {
    if (kIsWeb || !connected) return;
    try {
      rust_api.wifiWrite(data: src.toList());
    } catch (e) {
      logger.e("Wi-Fi Write Error (Socket dropped): $e");

      connected = false;
      close();
    }
  }
}
