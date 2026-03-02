import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'package:serial/serial.dart';

import '../../others/logger_service.dart';
import 'base.dart';

@JS()
extension type ReadResult._(JSObject _) implements JSObject {
  external bool get done;
  external JSUint8Array? get value;
}

class WebCommsHandler implements CommunicationHandler {
  @override
  bool connected = false;

  @override
  bool deviceFound = false;

  SerialPort? _port;
  web.ReadableStreamDefaultReader? _reader;
  web.WritableStreamDefaultWriter? _writer;

  final Queue<int> _rxBuffer = ListQueue<int>();
  bool _isReading = false;

  @override
  Future<void> initialize() async {
    deviceFound = true;
  }

  @override
  Future<void> open() async {
    try {
      _rxBuffer.clear();
      _port = await web.window.navigator.serial.requestPort().toDart;
      await _port!.open(baudRate: 1000000).toDart;

      await _port!
          .setSignals(dataTerminalReady: true, requestToSend: true)
          .toDart;
      await Future.delayed(const Duration(milliseconds: 2000));

      _writer = _port!.writable!.getWriter();
      _reader = _port!.readable!.getReader() as web.ReadableStreamDefaultReader;

      connected = true;
      _isReading = true;

      _startBackgroundReader();
    } catch (e) {
      connected = false;
      logger.e("User cancelled or connection failed: $e");
    }
  }

  void _startBackgroundReader() async {
    try {
      while (_isReading && connected && _reader != null) {
        final resultJS = await _reader!.read().toDart;
        final result = resultJS as ReadResult;

        if (result.done) {
          connected = false;
          break;
        }

        if (result.value != null) {
          final chunk = result.value!.toDart;
          for (int i = 0; i < chunk.length; i++) {
            _rxBuffer.add(chunk[i]);
          }
        }
      }
    } catch (e) {
      logger.e("Stream closed or device disconnected: $e");
      connected = false;
    }
  }

  @override
  bool isDeviceFound() => deviceFound;

  @override
  bool isConnected() => connected;

  @override
  void close() {
    _isReading = false;
    _reader?.cancel().toDart;
    _writer?.close().toDart;
    _port?.close().toDart;
    connected = false;
  }

  @override
  void write(Uint8List src, int timeoutMillis) {
    if (_writer != null) {
      _writer!.write(src.toJS).toDart;
    }
  }

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    int elapsed = 0;
    const int interval = 5;

    while (_rxBuffer.length < bytesToRead && elapsed < timeoutMillis) {
      await Future.delayed(const Duration(milliseconds: interval));
      elapsed += interval;
    }

    int bytesRead = 0;

    while (bytesRead < bytesToRead && _rxBuffer.isNotEmpty) {
      dest[bytesRead] = _rxBuffer.removeFirst();
      bytesRead++;
    }

    return bytesRead;
  }
}
