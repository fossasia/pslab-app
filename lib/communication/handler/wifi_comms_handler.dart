import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:pslab/src/rust/api/simple.dart' as rust_api;
import 'package:pslab/others/logger_service.dart';
import 'base.dart';

class WifiCommsHandler implements CommunicationHandler {
  String host;
  final int tcpPort = 80;
  final int wsPort = 81;

  bool useWebSockets = true;

  @override
  bool connected = false;
  @override
  bool deviceFound = false;

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;

  WifiCommsHandler({this.host = "192.168.4.1"});

  @override
  Future<void> initialize() async {
    deviceFound = true;
  }

  @override
  Future<void> open() async {
    int targetPort = useWebSockets ? wsPort : tcpPort;
    logger.d("Connecting to $host on port $targetPort...");

    if (kIsWeb) {
      final wsUrl = Uri.parse('ws://$host:$targetPort');

      try {
        rust_api.readWebData(bytesToRead: 999999);

        _wsChannel = WebSocketChannel.connect(wsUrl);
        await _wsChannel!.ready;

        _wsSubscription = _wsChannel!.stream.listen(
          (data) {
            if (data is Uint8List) {
              rust_api.pushWebData(data: data);
            } else if (data is List<int>) {
              rust_api.pushWebData(data: Uint8List.fromList(data));
            }
          },
          onDone: () {
            logger.w("Device closed the websocket connection");
            close();
          },
          onError: (e) {
            logger.e("Websocket stream error: $e");
            close();
          },
        );

        connected = true;
        logger.i("Connected via WebSockets");
      } catch (e) {
        logger.e("Could not connect to websocket: $e");
        connected = false;
        return;
      }
    } else {
      try {
        rust_api.wifiConnect(host: host, port: targetPort, useWebsocket: false);
        connected = true;
        logger.i("Connected via raw TCP");
      } catch (e) {
        logger.e("Failed to setup TCP connection: $e");
        connected = false;
      }
    }
  }

  @override
  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    if (!connected) return 0;

    int numBytesRead = 0;
    int bytesToBeReadTemp = bytesToRead;
    int elapsed = 0;
    const int checkInterval = 2;

    try {
      if (kIsWeb) {
        while (numBytesRead < bytesToRead && elapsed < timeoutMillis) {
          final List<int> rustBuffer =
              rust_api.readWebData(bytesToRead: bytesToBeReadTemp);
          int readNow = rustBuffer.length;

          if (readNow > 0) {
            int readLength = readNow.clamp(0, bytesToBeReadTemp);
            dest.setRange(numBytesRead, numBytesRead + readLength, rustBuffer);
            numBytesRead += readLength;
            bytesToBeReadTemp -= readLength;

            if (numBytesRead == bytesToRead) break;
          }
          await Future.delayed(const Duration(milliseconds: checkInterval));
          elapsed += checkInterval;
        }
      } else {
        final List<int> rustBuffer = await rust_api.wifiRead(
          bytesToRead: bytesToRead,
          timeoutMs: timeoutMillis,
        );
        numBytesRead = rustBuffer.length;
        if (numBytesRead > 0) {
          dest.setRange(0, numBytesRead, rustBuffer);
        }
      }

      if (numBytesRead < bytesToRead) {
        for (int i = numBytesRead; i < bytesToRead; i++) {
          dest[i] = 0;
        }
      }

      return numBytesRead;
    } catch (e) {
      logger.e("Error reading data: $e");
      connected = false;
      close();
      return 0;
    }
  }

  @override
  void write(Uint8List src, int timeoutMillis) {
    if (!connected) return;

    if (kIsWeb) {
      _wsChannel?.sink.add(src.toList());
    } else {
      rust_api.wifiWrite(data: src.toList());
    }
  }

  @override
  void close() {
    if (kIsWeb) {
      _wsSubscription?.cancel();
      _wsChannel?.sink.close();
      rust_api.readWebData(bytesToRead: 999999);
    } else {
      rust_api.wifiDisconnect();
    }
    connected = false;
    logger.i("Connection closed");
  }

  @override
  bool isDeviceFound() => deviceFound;

  @override
  bool isConnected() => connected;
}
