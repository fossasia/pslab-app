import 'dart:io';
import 'dart:typed_data';

import 'package:pslab/others/logger_service.dart';

class SocketClient {
  late Socket _socket;
  late Stream<Uint8List> _socketStream;
  bool _connected = false;
  Future<void> openConnection(String host, int port) async {
    try {
      _socket = await Socket.connect(host, port);
      _connected = true;
      _socket.setOption(SocketOption.tcpNoDelay, true);
      _socketStream = _socket.asBroadcastStream();
    } catch (e) {
      logger.e("Error connecting to socket: $e");
    }
  }

  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    int numBytesRead = 0;
    int bytesToBeReadTemp = bytesToRead;

    try {
      await for (Uint8List receivedData
          in _socketStream.timeout(Duration(milliseconds: timeoutMillis))) {
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
    _socket.add(src);
  }

  bool isConnected() {
    return _connected;
  }

  void setConnected(bool connected) {
    _connected = connected;
  }
}
