import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:usb_serial/usb_serial.dart';

class CommunicationHandler {
  static const int pslabVendorIdV5 = 1240;
  static const int pslabProductIdV5 = 223;
  static const int pslabVendorIdV6 = 0x10C4;
  static const int pslabProductIdV6 = 0xEA60;
  UsbDevice? mDevice;
  UsbPort? mPort;
  bool connected = false;
  bool deviceFound = false;

  Future<void> initialize() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    for (UsbDevice device in devices) {
      if ((device.vid == pslabVendorIdV5 && device.pid == pslabProductIdV5) ||
          (device.vid == pslabVendorIdV6 && device.pid == pslabProductIdV6)) {
        mDevice = device;
        deviceFound = true;
        break;
      }
    }
    if (deviceFound) {
      logger.d("Found PSLab device");
    } else {
      logger.d("No drivers found");
    }
  }

  Future<void> open() async {
    if (!deviceFound) {
      throw Exception("Device not connected");
    }
    mPort = await mDevice?.create();

    bool? openResult = await mPort?.open();
    if (!openResult!) {
      throw Exception("Failed to open");
    }
    await mPort?.setPortParameters(
      1000000,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );
    mPort?.inputStream?.listen((_) => ());
    connected = true;
  }

  bool isDeviceFound() => deviceFound;

  bool isConnected() => connected;

  void close() {
    if (!connected || mPort == null) return;
    mPort?.close();
    connected = false;
  }

  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    int numBytesRead = 0;
    int bytesToBeReadTemp = bytesToRead;

    try {
      await for (Uint8List receivedData in mPort!.inputStream!
          .timeout(Duration(milliseconds: timeoutMillis))) {
        int readNow = receivedData.length;

        if (readNow == 0) {
          logger.e("Read Error: $bytesToBeReadTemp");
          return numBytesRead;
        } else {
          int readLength = readNow.clamp(0, bytesToBeReadTemp);
          dest.setRange(numBytesRead, numBytesRead + readLength, receivedData);
          numBytesRead += readLength;
          bytesToBeReadTemp -= readLength;
        }

        if (numBytesRead >= bytesToRead) {
          break;
        }
      }
    } catch (e) {
      logger.e("Exception during read: $e");
    }

    logger.d("Bytes Read: $numBytesRead");
    return numBytesRead;
  }

  void write(Uint8List src, int timeoutMillis) {
    mPort?.write(src);
  }
}
