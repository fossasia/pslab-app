import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pslab/communication/commands_proto.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/others/logger_service.dart';

import '../src/rust/api/simple.dart' as rust_api;

enum BoardType { binary, scpi, other }

class PacketHandler {
  late Uint8List _buffer;
  late CommunicationHandler _mCommunicationHandler;

  static String version = '';
  static BoardType boardType = BoardType.other;

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
      String scpiResponse = await queryScpi("*IDN?");
      if (scpiResponse.contains("PSLab Pico") ||
          scpiResponse.contains("PSLab Mini")) {
        version = scpiResponse;
        boardType = BoardType.scpi;
        return version;
      }

      sendByte(_mCommandsProto.common);
      sendByte(_mCommandsProto.getVersion);
      await _commonRead(versionStringLength + 1);
      version = utf8
          .decode(_buffer.sublist(0, versionStringLength + 1))
          .split('\n')
          .first;
      boardType = BoardType.binary;
    } catch (e) {
      logger.e("Error in getting version: $e");
    }
    return version;
  }

  Future<void> sendScpi(String command) async {
    String fullCommand = "$command\r\n";
    _mCommunicationHandler.write(
        Uint8List.fromList(fullCommand.codeUnits), 100);
    await Future.delayed(const Duration(milliseconds: 25));
  }

  Future<String> queryScpi(String command) async {
    await sendScpi(command);

    Uint8List buffer = Uint8List(256);
    int bytesRead = await _mCommunicationHandler.read(buffer, 256, 500);
    if (bytesRead > 0) {
      String response =
          String.fromCharCodes(buffer.sublist(0, bytesRead)).trim();
      return response;
    }
    return "";
  }

  Future<Uint8List> queryScpiBinary(String command) async {
    Uint8List data =
        await rust_api.queryScpiBinaryRust(command: command, timeoutMs: 1000);
    return data;
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
      if (boardType == BoardType.scpi) {
        return 3;
      }
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
      int res =
          await _mCommunicationHandler.read(_buffer, bytesToRead, _timeout);
      return res;
    }
    return 0;
  }

  void _commonWrite(Uint8List data) {
    if (_mCommunicationHandler.isConnected()) {
      _mCommunicationHandler.write(data, _timeout);
    }
  }
}
