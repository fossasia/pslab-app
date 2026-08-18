import 'dart:async';
import 'dart:typed_data';
import 'package:pslab/communication/handler/base.dart';

/// Pure Dart implementation of the firmware flasher specifically for Web.
/// This file bypasses WebAssembly background threading limitations and
/// prevents browser deadlocks caused by Chrome's strict SharedArrayBuffer security policies.

class FlashChunk {
  final int address;
  final Uint8List data;
  FlashChunk(this.address, this.data);
}

class WebFirmwareFlasher {
  final CommunicationHandler handler;
  final Function(double progress, String status) onProgress;

  WebFirmwareFlasher({
    required this.handler,
    required this.onProgress,
  });

  Future<void> flashFirmware(String hexStr) async {
    Uint8List versionResp = Uint8List(0);
    for (int i = 0; i < 4; i++) {
      try {
        versionResp = await _exchange(0x00, 0, 0, 0, Uint8List(0), 500);
        break;
      } catch (_) {}
    }

    if (versionResp.isEmpty) {
      throw Exception(
          "Board did not respond. Are you sure the LED is blinking in bootloader mode?");
    }

    var vCursor = ByteData.sublistView(versionResp, 11);
    int maxPacket = vCursor.getUint16(2, Endian.little);
    int eraseSize = vCursor.getUint16(10, Endian.little);
    int writeSize = vCursor.getUint16(12, Endian.little);

    var memResp = await _exchange(0x0B, 0, 0, 0, Uint8List(0), 2000);
    var mCursor = ByteData.sublistView(memResp, 12);
    int programStart = mCursor.getUint32(0, Endian.little);
    int programEnd = mCursor.getUint32(4, Endian.little) + 2;

    var chunks = _prepareFlashChunks(
        hexStr, programStart, programEnd, maxPacket, writeSize);
    int totalBytes = chunks.fold(0, (sum, c) => sum + c.data.length);
    if (totalBytes == 0) {
      throw Exception("Hex file is empty or missing physical flash data.");
    }

    onProgress(0.20, "Erasing Flash Memory...");
    int pagesToErase = (programEnd - programStart) ~/ eraseSize;
    await _exchange(
        0x03, pagesToErase, 0x00AA0055, programStart, Uint8List(0), 15000);

    int writtenBytes = 0;
    for (var chunk in chunks) {
      await _exchange(
          0x02, chunk.data.length, 0x00AA0055, chunk.address, chunk.data, 2000);
      var chkResp = await _exchange(
          0x08, chunk.data.length, 0, chunk.address, Uint8List(0), 2000);

      int remoteChecksum =
          ByteData.sublistView(chkResp, 12).getUint16(0, Endian.little);
      int localChecksum = _getLocalChecksum(chunk.data);
      if (remoteChecksum != localChecksum) {
        throw Exception(
            "Checksum mismatch at 0x${chunk.address.toRadixString(16)}");
      }

      writtenBytes += chunk.data.length;
      double progress = 0.20 + ((writtenBytes / totalBytes) * 0.70);
      onProgress(progress,
          "Writing Flash: ${((writtenBytes / totalBytes) * 100).toInt()}%");
    }

    onProgress(0.95, "Verifying Checksum...");
    await _exchange(0x0A, 0, 0, 0, Uint8List(0), 5000);
    await _exchange(0x09, 0, 0, 0, Uint8List(0), 1000);
  }

  Future<Uint8List> _readExact(int size, int timeoutMs) async {
    Uint8List buf = Uint8List(size);
    int totalRead = 0;
    final startTime = DateTime.now();

    while (totalRead < size) {
      if (DateTime.now().difference(startTime).inMilliseconds > timeoutMs) {
        throw Exception("Read timeout: Expected $size, got $totalRead");
      }
      Uint8List chunk = Uint8List(size - totalRead);
      int readNow = await handler.read(chunk, chunk.length, 50);
      if (readNow > 0) {
        buf.setRange(totalRead, totalRead + readNow, chunk.sublist(0, readNow));
        totalRead += readNow;
      } else {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    return buf;
  }

  Future<Uint8List> _exchange(int command, int dataLen, int unlock, int addr,
      Uint8List payload, int timeoutMs) async {
    final tx = ByteData(11 + payload.length);
    tx.setUint8(0, command);
    tx.setUint16(1, dataLen, Endian.little);
    tx.setUint32(3, unlock, Endian.little);
    tx.setUint32(7, addr, Endian.little);
    for (int i = 0; i < payload.length; i++) {
      tx.setUint8(11 + i, payload[i]);
    }

    handler.write(tx.buffer.asUint8List(), timeoutMs);

    var header = await _readExact(11, timeoutMs);
    if (header[0] != command) {
      throw Exception(
          "Command echo mismatch: expected 0x${command.toRadixString(16)}, got 0x${header[0].toRadixString(16)}");
    }

    if (command == 0x00) {
      var remainder = await _readExact(26, timeoutMs);
      var resp = BytesBuilder();
      resp.add(header);
      resp.add(remainder);
      return resp.toBytes();
    }

    var success = await _readExact(1, timeoutMs);
    if (success[0] != 0x01) {
      throw Exception(
          "Bootloader error code: 0x${success[0].toRadixString(16)}");
    }

    int remainderLen = (command == 0x0B)
        ? 8
        : (command == 0x08)
            ? 2
            : 0;
    var resp = BytesBuilder();
    resp.add(header);
    resp.add(success);
    if (remainderLen > 0) resp.add(await _readExact(remainderLen, timeoutMs));

    return resp.toBytes();
  }

  int _getLocalChecksum(Uint8List data) {
    int chksum = 0;
    for (int i = 0; i < data.length; i += 4) {
      if (i + 2 < data.length) {
        chksum += data[i] + (data[i + 1] << 8) + data[i + 2];
      }
    }
    return chksum & 0xFFFF;
  }

  List<FlashChunk> _prepareFlashChunks(String hexStr, int programStart,
      int programEnd, int maxPacket, int writeSize) {
    int numPcAddresses = programEnd - programStart;
    int memSizeBytes = numPcAddresses * 2;
    int rem = memSizeBytes % writeSize;
    if (rem != 0) memSizeBytes += writeSize - rem;

    Uint8List flashMem = Uint8List(memSizeBytes);
    flashMem.fillRange(0, memSizeBytes, 0xFF);
    List<bool> hasData = List.filled(memSizeBytes, false);

    int extLinAddr = 0, extSegAddr = 0;

    for (String line in hexStr.split('\n').map((l) => l.trim())) {
      if (line.isEmpty || !line.startsWith(':')) continue;
      int len = int.parse(line.substring(1, 3), radix: 16);
      int addr = int.parse(line.substring(3, 7), radix: 16);
      int type = int.parse(line.substring(7, 9), radix: 16);

      if (type == 0x04) {
        extLinAddr = int.parse(line.substring(9, 13), radix: 16) << 16;
        extSegAddr = 0;
      } else if (type == 0x02) {
        extSegAddr = int.parse(line.substring(9, 13), radix: 16) << 4;
        extLinAddr = 0;
      } else if (type == 0x00) {
        int baseHexAddr = extLinAddr + extSegAddr + addr;
        for (int i = 0; i < len; i++) {
          int byte =
              int.parse(line.substring(9 + i * 2, 11 + i * 2), radix: 16);
          int hexAddr = baseHexAddr + i;
          int pcAddr = hexAddr ~/ 2;
          if (pcAddr >= programStart && pcAddr < programEnd) {
            int pcOffset = pcAddr - programStart;
            int byteOffset = (pcOffset * 2) + (hexAddr % 2);
            flashMem[byteOffset] = byte;
            hasData[byteOffset] = true;
          }
        }
      } else if (type == 0x01) {
        break;
      }
    }

    List<FlashChunk> segments = [];
    for (int i = 0; i < memSizeBytes; i += writeSize) {
      int blockEnd =
          (i + writeSize > memSizeBytes) ? memSizeBytes : i + writeSize;
      bool blockHasData = false;
      for (int j = i; j < blockEnd; j++) {
        if (hasData[j]) {
          blockHasData = true;
          break;
        }
      }

      if (blockHasData) {
        Uint8List blockData = flashMem.sublist(i, blockEnd);
        int blockPcAddr = programStart + (i ~/ 2);
        if (segments.isNotEmpty) {
          var last = segments.last;
          if (last.address + (last.data.length ~/ 2) == blockPcAddr) {
            var newData = Uint8List(last.data.length + blockData.length);
            newData.setAll(0, last.data);
            newData.setAll(last.data.length, blockData);
            segments[segments.length - 1] = FlashChunk(last.address, newData);
          } else {
            segments.add(FlashChunk(blockPcAddr, blockData));
          }
        } else {
          segments.add(FlashChunk(blockPcAddr, blockData));
        }
      }
    }

    int maxPayloadBytes = ((maxPacket - 11) ~/ writeSize) * writeSize;
    List<FlashChunk> chunks = [];
    for (var seg in segments) {
      int offset = 0;
      while (offset < seg.data.length) {
        int take = (seg.data.length - offset < maxPayloadBytes)
            ? seg.data.length - offset
            : maxPayloadBytes;
        chunks.add(FlashChunk(seg.address + (offset ~/ 2),
            seg.data.sublist(offset, offset + take)));
        offset += take;
      }
    }
    return chunks;
  }
}
