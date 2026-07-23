import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import '../../others/logger_service.dart';
import 'base.dart';
import 'package:pslab/src/rust/api/simple.dart' as rust_api;

@JS()
extension type Serial._(JSObject _) implements JSObject {
  external JSPromise<SerialPort> requestPort();
}

@JS()
extension type SerialPort._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> open(SerialOptions options);
  external JSPromise<JSAny?> setSignals(SerialOutputSignals options);
  external JSPromise<JSAny?> close();
  external web.ReadableStream? get readable;
  external web.WritableStream? get writable;
}

extension type SerialOptions._(JSObject _) implements JSObject {
  external factory SerialOptions({int baudRate});
}

extension type SerialOutputSignals._(JSObject _) implements JSObject {
  external factory SerialOutputSignals(
      {bool dataTerminalReady, bool requestToSend});
}

@JS()
extension type ReadResult._(JSObject _) implements JSObject {
  external bool get done;
  external JSUint8Array? get value;
}

extension NavigatorSerial on web.Navigator {
  Serial get serial => (this as JSObject).getProperty<Serial>('serial'.toJS);
}

class WebCommsHandler implements CommunicationHandler {
  @override
  bool connected = false;

  @override
  bool deviceFound = false;

  SerialPort? _port;
  web.ReadableStreamDefaultReader? _reader;
  web.WritableStreamDefaultWriter? _writer;
  bool _isReading = false;

  @override
  Future<void> initialize() async {
    final navigator = web.window.navigator as JSObject;
    final hasSerial = navigator.hasProperty('serial'.toJS).toDart;
    deviceFound = web.window.isSecureContext && hasSerial;

    if (deviceFound) {
      logger.d("Found Web Serial API support");
    } else {
      logger.d("Web Serial API not supported or not in secure context");
    }
  }

  @override
  Future<void> open() async {
    if (!deviceFound) {
      throw Exception("Web Serial API not available");
    }

    try {
      logger.d("Requesting Web Serial port (waiting for user selection)...");
      _port = await web.window.navigator.serial.requestPort().toDart;

      logger.d("Opening Web Serial port at 1000000 baud...");
      await _port!.open(SerialOptions(baudRate: 1000000)).toDart;

      logger.d("Setting DTR/RTS signals...");
      await _port!
          .setSignals(
              SerialOutputSignals(dataTerminalReady: true, requestToSend: true))
          .toDart;
      await Future.delayed(const Duration(milliseconds: 2000));

      _writer = _port!.writable!.getWriter();
      _reader = _port!.readable!.getReader() as web.ReadableStreamDefaultReader;

      connected = true;
      _isReading = true;
      logger.i("Connected to Web Serial device.");

      _pumpDataToRust();
    } catch (e) {
      connected = false;
      logger.e("User cancelled or connection failed: $e");
      throw Exception("Failed to open Web Serial port");
    }
  }

  void _pumpDataToRust() async {
    logger.d("Started Web data pump to Rust buffer.");
    try {
      while (_isReading && connected && _reader != null) {
        final resultJS = await _reader!.read().toDart;
        final result = resultJS as ReadResult;

        if (result.done) {
          logger.d("Web Serial stream closed from hardware side.");
          connected = false;
          break;
        }

        if (result.value != null) {
          rust_api.pushWebData(data: result.value!.toDart);
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
    if (!connected) return;
    logger.d("Closing Web Serial connection...");
    _isReading = false;
    _reader?.cancel().toDart.catchError((_) => null);
    _writer?.close().toDart.catchError((_) => null);
    _port?.close().toDart.catchError((_) => null);
    connected = false;
    rust_api.closeUsb();
  }

  @override
  void write(Uint8List src, int timeoutMillis) {
    if (_writer != null && connected) {
      logger.d("Writing data: $src");
      _writer!.write(src.toJS).toDart;
    }
  }

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    int numBytesRead = 0;
    int bytesToBeReadTemp = bytesToRead;
    int elapsed = 0;
    const int checkInterval = 2;

    try {
      while (numBytesRead < bytesToRead && elapsed < timeoutMillis) {
        final List<int> rustBuffer =
            rust_api.readWebData(bytesToRead: bytesToBeReadTemp);
        int readNow = rustBuffer.length;

        if (readNow > 0) {
          logger.d("Received chunk: $rustBuffer");
          int readLength = readNow.clamp(0, bytesToBeReadTemp);
          dest.setRange(numBytesRead, numBytesRead + readLength, rustBuffer);
          numBytesRead += readLength;
          bytesToBeReadTemp -= readLength;

          if (numBytesRead == bytesToRead) {
            break;
          }
        }
        await Future.delayed(const Duration(milliseconds: checkInterval));
        elapsed += checkInterval;
      }

      if (numBytesRead == 0 && elapsed >= timeoutMillis) {
        logger.w("Timeout: No signal on wire. Returning 0 bytes.");
      }
    } catch (e) {
      logger.e("Exception during read: $e");
    }

    logger.d("Bytes Read: $numBytesRead");
    return numBytesRead;
  }
}
