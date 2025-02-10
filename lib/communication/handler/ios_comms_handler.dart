import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pslab/communication/handler/base.dart';

class IosNoOpCommunicationHandler implements CommunicationHandler {
  @override
  bool connected = false;

  @override
  bool deviceFound = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> open() async {}

  @override
  bool isDeviceFound() => deviceFound;

  @override
  bool isConnected() => connected;

  @override
  void close() {}

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    return -1;
  }

  @override
  void write(Uint8List src, int timeoutMillis) {}
}
