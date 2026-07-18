import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/others/logger_service.dart';

import 'package:pslab/src/rust/api/simple.dart' as rust_api;

class PSLabBoard {
  final String version;
  final int vid;
  final int pid;
  const PSLabBoard(
      {required this.version, required this.vid, required this.pid});
}

class PSLabCommunicationHandler implements CommunicationHandler {
  static const List<PSLabBoard> supportedBoards = [
    PSLabBoard(version: 'V6', vid: 0x10C4, pid: 0xEA60),
    PSLabBoard(version: 'V5', vid: 1240, pid: 223),
  ];

  static const MethodChannel _androidChannel = MethodChannel('usb_serial');

  @override
  bool connected = false;

  @override
  bool deviceFound = false;

  @override
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      deviceFound = true;
    } else {
      deviceFound = rust_api.checkDesktopDevicePresent();
    }

    if (deviceFound) {
      logger.d("Found PSLab device");
    } else {
      logger.d("No drivers found");
    }
  }

  @override
  Future<void> open() async {
    if (!deviceFound) {
      throw Exception("Device not connected");
    }

    rust_api.closeUsb();

    bool boardConnected = false;

    for (final board in supportedBoards) {
      try {
        if (Platform.isAndroid) {
          logger.d(
              "Probing Android for ${board.version} (VID: ${board.vid}, PID: ${board.pid})...");
          final int fd = await _androidChannel.invokeMethod('getAndroidFd', {
            "vid": board.vid,
            "pid": board.pid,
          });
          logger.d("Got FD from Android: $fd. Handing to Rust...");
          await rust_api.initAndroid(fd: fd);
        } else {
          logger.d("Probing Desktop for ${board.version}...");
          await rust_api.initDesktop(vid: board.vid, pid: board.pid);
        }

        logger.i(" Connected to PSLab ${board.version} hardware.");
        boardConnected = true;
        break;
      } catch (e) {
        logger.w("Failed on ${board.version}: $e");
        continue;
      }
    }

    if (!boardConnected) {
      connected = false;
      throw Exception(
          "Failed to open. See warnings above for the exact reason.");
    }

    try {
      rust_api.setDtr(state: true);
      rust_api.setRts(state: true);
      await Future.delayed(const Duration(milliseconds: 250));
      connected = true;
    } catch (e) {
      connected = false;
      throw Exception("Failed to wake up board");
    }
  }

  @override
  bool isDeviceFound() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return rust_api.checkDesktopDevicePresent();
    }
    return deviceFound;
  }

  @override
  bool isConnected() => connected;

  @override
  void close() {
    if (!connected) return;
    rust_api.closeUsb();
    connected = false;
  }

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    int numBytesRead = 0;
    int bytesToBeReadTemp = bytesToRead;

    try {
      while (numBytesRead < bytesToRead) {
        final List<int> receivedData = await rust_api.readData(
          bytesToRead: bytesToBeReadTemp,
          timeoutMs: timeoutMillis,
        );

        int readNow = receivedData.length;
        logger.d("Received chunk: $receivedData");

        if (readNow == 0) {
          logger.w("No signal on wire. Returning 0 bytes.");
          return numBytesRead;
        } else {
          int readLength = readNow.clamp(0, bytesToBeReadTemp);
          dest.setRange(numBytesRead, numBytesRead + readLength, receivedData);
          numBytesRead += readLength;
          bytesToBeReadTemp -= readLength;
        }
      }
    } catch (e) {
      logger.e("Exception during read: $e");
    }

    logger.d("Bytes Read: $numBytesRead");
    return numBytesRead;
  }

  @override
  void write(Uint8List src, int timeoutMillis) {
    if (!connected) return;
    rust_api.writeData(data: src.toList());
  }
}
