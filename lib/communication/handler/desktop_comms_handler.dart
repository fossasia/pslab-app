import 'dart:typed_data';

import 'package:flusbserial/flusbserial.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/others/logger_service.dart';

class DesktopUSBCommunicationHandler implements CommunicationHandler {
  static const int pslabVendorIdV5 = 1240;
  static const int pslabProductIdV5 = 223;
  static const int pslabVendorIdV6 = 0x10C4;
  static const int pslabProductIdV6 = 0xEA60;
  UsbSerialDevice? mDevice;

  @override
  bool connected = false;

  @override
  bool deviceFound = false;

  @override
  void close() {
    if (!connected || mDevice == null) return;
    mDevice?.close();
    connected = false;
  }

  @override
  Future<void> initialize() async {
    UsbSerialDevice.init();
    List<UsbDevice> availableDevices = await UsbSerialDevice.listDevices();
    for (final device in availableDevices) {
      if ((device.vendorId == pslabVendorIdV5 &&
              device.productId == pslabProductIdV5) ||
          (device.vendorId == pslabVendorIdV6 &&
              device.productId == pslabProductIdV6)) {
        deviceFound = true;
        mDevice = UsbSerialDevice.createDevice(device);
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
    UsbSerialDevice.setAutoDetachKernelDriver(true);
    if (await mDevice?.open() == false) {
      logger.e("Failed to open device");
      return;
    }
    await mDevice?.setBaudRate(1000000);
    await mDevice?.setDataBits(UsbSerialInterface.dataBits8);
    await mDevice?.setStopBits(UsbSerialInterface.stopBits1);
    await mDevice?.setParity(UsbSerialInterface.parityNone);
    connected = true;
  }

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    int numBytesRead = 0;
    int bytesToBeReadTemp = bytesToRead;

    try {
      while (numBytesRead < bytesToRead) {
        Uint8List? receivedData =
            await mDevice?.read(bytesToBeReadTemp, timeoutMillis);

        int? readNow = receivedData?.length;

        if (readNow == null || readNow == 0) {
          // If we read nothing and timeout, stop trying to avoid an infinite hang
          break;
        } else {
          int readLength = readNow.clamp(0, bytesToBeReadTemp);
          dest.setRange(numBytesRead, numBytesRead + readLength, receivedData!);
          numBytesRead += readLength;
          bytesToBeReadTemp -= readLength;
        }
      }
    } catch (e) {
      // If we hit a LIBUSB_ERROR_TIMEOUT but we already have data, it's just a partial read.
      if (numBytesRead > 0) {
        logger.d(
            "Partial read completed before timeout. Read: $numBytesRead/$bytesToRead bytes.");
      } else {
        logger.w("USB Read Timeout: Expected $bytesToRead bytes but got 0.");
      }
    }

    return numBytesRead;
  }

  @override
  void write(Uint8List src, int timeoutMillis) {
    mDevice?.write(src, timeoutMillis);
  }
}
