import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:pslab/others/logger_service.dart';

class SocketClient {
  late html.WebSocket _ws;
  final StreamController<Uint8List> _controller = StreamController.broadcast();
  bool _connected = false;

  Future<void> openConnection(String host, int port) async {
    try {
      final uri = Uri(scheme: 'ws', host: host, port: port).toString();
      _ws = html.WebSocket(uri);
      _ws.binaryType = 'arraybuffer';
      _ws.onOpen.listen((_) {
        _connected = true;
      });
      _ws.onClose.listen((_) {
        _connected = false;
      });
      _ws.onError.listen((event) {
        logger.e('WebSocket error: $event');
      });
      _ws.onMessage.listen((html.MessageEvent ev) {
        try {
          final data = ev.data;
          if (data is ByteBuffer) {
            _controller.add(Uint8List.view(data));
          } else if (data is List<int>) {
            _controller.add(Uint8List.fromList(data));
          } else if (data is String) {
            _controller.add(Uint8List.fromList(data.codeUnits));
          }
        } catch (e) {
          logger.e('Error processing websocket message: $e');
        }
      });
    } catch (e) {
      logger.e('Error opening WebSocket: $e');
    }
  }

  Future<int> read(Uint8List dest, int bytesToRead, int timeoutMillis) async {
    int numBytesRead = 0;
    int bytesToBeReadTemp = bytesToRead;
    try {
      await for (Uint8List receivedData
          in _controller.stream.timeout(Duration(milliseconds: timeoutMillis))) {
        int readNow = receivedData.length;
        if (readNow == 0) {
          logger.e('Read Error: $bytesToBeReadTemp');
          return numBytesRead;
        } else {
          int readLength = readNow.clamp(0, bytesToBeReadTemp);
          dest.setRange(numBytesRead, numBytesRead + readLength, receivedData);
          numBytesRead += readLength;
          bytesToBeReadTemp -= readLength;
        }
        if (numBytesRead >= bytesToRead) break;
      }
    } catch (e) {
      logger.e('Exception during read (web): $e');
    }
    logger.d('Bytes Read (web): $numBytesRead');
    return numBytesRead;
  }

  void write(Uint8List src, int timeoutMillis) {
    if (!_connected) return;
    try {
      _ws.send(src.buffer);
    } catch (e) {
      logger.e('WebSocket send error: $e');
    }
  }

  bool isConnected() => _connected;

  void setConnected(bool connected) {
    _connected = connected;
    if (!connected) {
      try {
        _ws.close();
      } catch (_) {}
    }
  }
}
