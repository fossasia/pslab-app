import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/others/logger_service.dart';

class DesktopUSBCommunicationHandler implements CommunicationHandler {
  static const int pslabVendorIdV5 = 1240;
  static const int pslabProductIdV5 = 223;
  static const int pslabVendorIdV6 = 0x10C4;
  static const int pslabProductIdV6 = 0xEA60;
  SerialPort? mPort;

  @override
  bool connected = false;

  @override
  bool deviceFound = false;

  @override
  void close() {
    if (!connected || mPort == null) return;
    mPort?.close();
    connected = false;
  }

  @override
  Future<void> initialize() async {
    List<String> addresses = SerialPort.availablePorts;
    for (final address in addresses) {
      final port = SerialPort(address);
      if ((port.vendorId == pslabVendorIdV5 &&
              port.productId == pslabProductIdV5) ||
          (port.vendorId == pslabVendorIdV6 &&
              port.productId == pslabProductIdV6)) {
        deviceFound = true;
        mPort = port;
        break;
      }
    }
    if (deviceFound) {
      logger.d("Found PSLab device");
    } else {
      logger.d("No drivers found");
    }
  }

  @override
  bool isConnected() {
    return connected;
  }

  @override
  bool isDeviceFound() {
    return deviceFound;
  }

  @override
  Future<void> open() async {
    if (!deviceFound) {
      throw Exception("Device not connected");
    }
    mPort?.openReadWrite();
    mPort?.config.baudRate = 1000000;
    mPort?.config.bits = 8;
    mPort?.config.stopBits = 1;
    mPort?.config.parity = SerialPortParity.none;
    connected = true;
  }

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    int numBytesRead = 0;
    int bytesToBeReadTemp = bytesToRead;
    try {
      while (numBytesRead < bytesToRead) {
        Uint8List receivedData = mPort!.read(bytesToBeReadTemp, timeout: 0);
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
      }
    } catch (e) {
      logger.e("Exception during read: $e");
    }

    logger.d("Bytes Read: $numBytesRead");
    return numBytesRead;
  }

  @override
  void write(Uint8List src, int timeoutMillis) {
    mPort?.write(src, timeout: 0);
    mPort?.flush();
  }
}
