import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pslab/communication/commands_proto.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/others/logger_service.dart';

class PacketHandler {
  late Uint8List _buffer;
  late CommunicationHandler _mCommunicationHandler;
  static String version = '';
  late CommandsProto _mCommandsProto;
  int _timeout = 500, versionStringLength = 8, fwVersionLength = 3;

  PacketHandler(int timeout, CommunicationHandler communicationHandler) {
    _timeout = timeout;
    _mCommandsProto = CommandsProto();
    _mCommunicationHandler = communicationHandler;
    _buffer = Uint8List(10000);
  }

  bool isConnected() {
    return _mCommunicationHandler.isConnected();
  }

  Future<String> getVersion() async {
    try {
      sendByte(_mCommandsProto.common);
      sendByte(_mCommandsProto.getVersion);
      await _commonRead(versionStringLength + 1);
      version = utf8.decode(_buffer).split('\n').first;
    } catch (e) {
      logger.e("Error in getting version: $e");
    }
    return version;
  }

  void sendByte(int val) {
    if (!isConnected()) {
      throw Exception("Device not connected");
    }
    try {
      _commonWrite(Uint8List.fromList([val & 0xFF]));
    } catch (e) {
      logger.e("Error in sending byte: $e");
    }
  }

  void sendInt(int val) {
    if (!isConnected()) {
      throw Exception("Device not connected");
    }
    try {
      _commonWrite(Uint8List.fromList([val & 0xFF, (val >> 8) & 0xFF]));
    } catch (e) {
      logger.e("Error in sending int: $e");
    }
  }

  Future<int> getAcknowledgement() async {
    try {
      await _commonRead(1);
      return _buffer[0];
    } catch (e) {
      logger.e(e);
      return 3;
    }
  }

  Future<int> getByte() async {
    try {
      int numBytesRead = await _commonRead(3);
      if (numBytesRead == 3) {
        return _buffer[0];
      } else {
        logger.e("Error in getting voltage");
      }
    } catch (e) {
      logger.e(e);
    }
    return -1;
  }

  Future<int> getVoltageSummation() async {
    try {
      int numBytesRead = await _commonRead(3);
      if (numBytesRead == 3) {
        return (_buffer[0] & 0xFF | ((_buffer[1] << 8) & 0xFF00));
      } else {
        logger.e("Error in getting voltage");
      }
    } catch (e) {
      logger.e(e);
    }
    return -1;
  }

  Future<int> getInt() async {
    try {
      int numBytesRead = await _commonRead(2);
      if (numBytesRead == 2) {
        return (_buffer[0] & 0xFF | ((_buffer[1] << 8) & 0xFF00));
      } else {
        logger.e("Error in reading Int");
      }
    } catch (e) {
      logger.e(e);
    }
    return -1;
  }

  Future<int> getLong() async {
    try {
      int numBytesRead = await _commonRead(4);
      if (numBytesRead == 4) {
        return _buffer.buffer.asByteData(0, 4).getInt32(0, Endian.little);
      } else {
        logger.e("Error in reading Long");
      }
    } catch (e) {
      logger.e(e);
    }
    return -1;
  }

  Future<int> getFirmwareVersion() async {
    try {
      sendByte(_mCommandsProto.common);
      sendByte(_mCommandsProto.getFwVersion);
      int numBytesRead = await _commonRead(fwVersionLength);
      if (numBytesRead == 1) {
        return 2;
      } else {
        return _buffer[0];
      }
    } catch (e) {
      logger.e(e);
    }
    return 0;
  }

  Future<int> read(Uint8List dest, int bytesToRead) async {
    int numBytesRead = await _commonRead(bytesToRead);

    if (numBytesRead == 0) {
      return 0;
    }
    for (int i = 0; i < numBytesRead; i++) {
      dest[i] = _buffer[i];
    }

    if (numBytesRead == bytesToRead) {
      return numBytesRead;
    } else {
      logger.e(
          "Error in PacketHandler Reading. Expected: $bytesToRead, Got: $numBytesRead");
    }
    return -1;
  }

  Future<int> _commonRead(int bytesToRead) async {
    if (_mCommunicationHandler.isConnected()) {
      return await _mCommunicationHandler.read(_buffer, bytesToRead, _timeout);
    }
    return 0;
  }

  void _commonWrite(Uint8List data) {
    if (_mCommunicationHandler.isConnected()) {
      _mCommunicationHandler.write(data, _timeout);
    }
  }
}
