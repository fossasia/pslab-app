import 'dart:async';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class TSL2561 {
  static const String tag = "TSL2561";

  static const int commandBit = 0x80;
  static const int wordBit = 0x20;

  static const int controlPowerOn = 0x03;
  static const int controlPowerOff = 0x00;

  static const int registerControl = 0x00;
  static const int registerTiming = 0x01;
  static const int registerId = 0x0A;
  static const int registerChan0Low = 0x0C;
  static const int registerChan1Low = 0x0E;

  static const int integrationTime13ms = 0x00;
  static const int integrationTime101ms = 0x01;
  static const int integrationTime402ms = 0x02;

  static const int gain0x = 0x00;
  static const int gain16x = 0x10;

  static const List<int> addresses = [0x39, 0x29, 0x49];

  final I2C i2c;
  int address = 0x39;
  int timing = integrationTime13ms;
  int gain = gain16x;

  TSL2561(this.i2c, ScienceLab scienceLab) {
    () async {
      if (scienceLab.isConnected()) {
        for (final addr in addresses) {
          address = addr;
          await disable();
          logger.d("$tag: Checking address 0x${address.toRadixString(16)}");
          try {
            int id = await i2c.readByte(address, registerId);
            if (id != 0xffffffff && (id & 0x0A) == 0x0A) {
              logger.d("$tag: TSL2561 found!");
              break;
            } else {
              logger.d("$tag: TSL2561 not found.");
            }
          } catch (e) {
            logger.e("$tag: Error reading ID: $e");
          }
        }
        await enable();
        await _wait();
        await i2c
            .writeBulk(address, [commandBit | registerTiming, timing | gain]);
      }
    }();
  }

  Future<int> getID() async {
    try {
      List<int> idList = await i2c.readBulk(address, registerId, 1);
      if (idList.isEmpty) return -1;
      int id = int.parse(idList[0].toRadixString(16), radix: 16);
      logger.d("$tag: ID: $id");
      return id;
    } catch (e) {
      logger.e("$tag: Error getting ID: $e");
      rethrow;
    }
  }

  Future<double?> getRaw() async {
    try {
      List<int> infraList = await i2c.readBulk(
          address, commandBit | wordBit | registerChan1Low, 2);
      List<int> fullList = await i2c.readBulk(
          address, commandBit | wordBit | registerChan0Low, 2);

      if (infraList.isNotEmpty && fullList.isNotEmpty) {
        int full = ((fullList[1] & 0xff) << 8) | (fullList[0] & 0xff);
        int infra = ((infraList[1] & 0xff) << 8) | (infraList[0] & 0xff);
        return (full - infra).toDouble();
      } else {
        return 0.0;
      }
    } catch (e) {
      logger.e("$tag: Error reading raw values: $e");
      return 0.0;
    }
  }

  Future<void> setGain(int gainValue) async {
    switch (gainValue) {
      case 1:
        gain = gain0x;
        break;
      case 16:
        gain = gain16x;
        break;
      default:
        gain = gain16x;
    }
    await i2c.writeBulk(address, [commandBit | registerTiming, gain | timing]);
  }

  Future<void> enable() async {
    await i2c
        .writeBulk(address, [commandBit | registerControl, controlPowerOn]);
  }

  Future<void> disable() async {
    await i2c
        .writeBulk(address, [commandBit | registerControl, controlPowerOff]);
  }

  Future<void> _wait() async {
    switch (timing) {
      case integrationTime13ms:
        await Future.delayed(const Duration(milliseconds: 14));
        break;
      case integrationTime101ms:
        await Future.delayed(const Duration(milliseconds: 102));
        break;
      case integrationTime402ms:
      default:
        await Future.delayed(const Duration(milliseconds: 403));
        break;
    }
  }
}
