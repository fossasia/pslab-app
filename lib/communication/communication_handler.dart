import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

class CommunicationHandler {
  static const int PSLAB_VENDOR_ID_V5 = 1240;
  static const int PSLAB_PRODUCT_ID_V5 = 223;
  static const int PSLAB_VENDOR_ID_V6 = 0x10C4;
  static const int PSLAB_PRODUCT_ID_V6 = 0xEA60;
  UsbDevice? mDevice;
  UsbPort? mPort;
  bool connected = false;
  bool deviceFound = false;

  Future<void> initialize() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    for (UsbDevice device in devices) {
      if ((device.vid == PSLAB_VENDOR_ID_V5 &&
              device.pid == PSLAB_PRODUCT_ID_V5) ||
          (device.vid == PSLAB_VENDOR_ID_V6 &&
              device.pid == PSLAB_PRODUCT_ID_V6)) {
        mDevice = device;
        deviceFound = true;
        break;
      }
    }
    if (deviceFound) {
      print("Found PSLab device");
    } else {
      print("No drivers found");
    }
  }

  Future<void> open() async {
    if (!deviceFound) {
      throw Exception("Device not connected");
    }
    mPort = await mDevice!.create();

    bool openResult = await mPort!.open();
    if (!openResult) {
      throw Exception("Failed to open");
    }
    await mPort!.setPortParameters(
      1000000,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );
    mPort!.inputStream!.listen((_) => ());
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
    await for (Uint8List receivedData
        in mPort!.inputStream!.timeout(Duration(milliseconds: timeoutMillis))) {
      dest.setRange(0, receivedData.length, receivedData);
      if (receivedData.length == bytesToRead) {
        print("Read: $bytesToRead");
      } else {
        print("Read Error: ${bytesToRead - numBytesRead}");
      }
      return numBytesRead;
    }
    return numBytesRead;
  }

  void write(Uint8List src, int timeoutMillis) {
    mPort!.write(src);
  }
}
