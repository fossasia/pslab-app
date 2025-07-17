import 'package:flutter/foundation.dart';
import 'package:pslab/communication/commands_proto.dart';
import 'package:pslab/communication/packet_handler.dart';
import 'package:pslab/others/logger_service.dart';

class I2C {
  late List<double> buffer;
  int frequency = 100000;
  late CommandsProto commandsProto;
  late PacketHandler packetHandler;
  int totalBytes = 0;
  int channels = 0;
  int samples = 0;
  int timeGap = 0;

  I2C(this.packetHandler) {
    buffer = List.filled(10000, 0);
    commandsProto = CommandsProto();
  }

  Future<void> init() async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cInit);
    await packetHandler.getAcknowledgement();
  }

  Future<void> enableSMBus() async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cEnableSmbus);
    await packetHandler.getAcknowledgement();
  }

  Future<void> pullSCLow(int uSec) async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cPulldownScl);
    packetHandler.sendInt(uSec);
    await packetHandler.getAcknowledgement();
  }

  Future<void> config(int frequency) async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cConfig);
    int brgval = ((1 / frequency - 1 / 1e7) * 64e6 - 1).toInt();
    if (brgval > 511) {
      brgval = 511;
      logger.t("Frequency too low");
    }
    packetHandler.sendInt(brgval);
    await packetHandler.getAcknowledgement();
  }

  Future<int> start(int address, int rw) async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cStart);
    packetHandler.sendByte((address << 1) | rw & 0xFF);
    return (await packetHandler.getAcknowledgement() >> 4);
  }

  Future<void> stop() async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cStop);
    await packetHandler.getAcknowledgement();
  }

  Future<void> wait() async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cWait);
    await packetHandler.getAcknowledgement();
  }

  Future<int> send(int data) async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cSend);
    packetHandler.sendByte(data);
    return (await packetHandler.getAcknowledgement() >> 4);
  }

  Future<int> restart(int address, int rw) async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cRestart);
    packetHandler.sendByte((address << 1) | rw & 0xFF);
    return (await packetHandler.getAcknowledgement() >> 4);
  }

  Future<List<int>> simpleRead(int address, int numBytes) async {
    await start(address, 1);
    return await read(numBytes);
  }

  Future<List<int>> read(int length) async {
    List<int> data = [];
    for (int i = 0; i < length - 1; i++) {
      packetHandler.sendByte(commandsProto.i2cHeader);
      packetHandler.sendByte(commandsProto.i2cReadMore);
      data.add(await packetHandler.getByte());
      await packetHandler.getAcknowledgement();
    }
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cReadEnd);
    data.add(await packetHandler.getByte());
    await packetHandler.getAcknowledgement();
    return data;
  }

  Future<int> readStatus() async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cStatus);
    int val = await packetHandler.getInt();
    await packetHandler.getAcknowledgement();
    return val;
  }

  Future<List<int>> readBulk(
      int deviceAddress, int registerAddress, int bytesToRead) async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cReadBulk);
    packetHandler.sendByte(deviceAddress);
    packetHandler.sendByte(registerAddress);
    packetHandler.sendByte(bytesToRead);
    Uint8List buffer = Uint8List(bytesToRead + 1);
    await packetHandler.read(buffer, bytesToRead + 1);
    List<int> data = [];
    for (int i in buffer) {
      data.add(i.toInt());
    }
    return data;
  }

  Future<int> readByte(int deviceAddress, int registerAddress) async {
    List<int> data = await readBulk(deviceAddress, registerAddress, 1);
    return data[0];
  }

  Future<int> readInt(int deviceAddress, int registerAddress) async {
    List<int> data = await readBulk(deviceAddress, registerAddress, 2);
    return (data[0] << 8) | data[1];
  }

  Future<int> readLong(int deviceAddress, int registerAddress) async {
    List<int> data = await readBulk(deviceAddress, registerAddress, 4);
    return (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
  }

  Future<void> writeBulk(int deviceAddress, List<int> data) async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cWriteBulk);
    packetHandler.sendByte(deviceAddress);
    packetHandler.sendByte(data.length);
    for (int d in data) {
      packetHandler.sendByte(d);
    }
    await packetHandler.getAcknowledgement();
  }

  Future<void> write(
      int deviceAddress, List<int> data, int registerAddress) async {
    List<int> finalData = [registerAddress, ...data];
    await writeBulk(deviceAddress, finalData);
  }

  Future<void> writeByte(
      int deviceAddress, int registerAddress, int data) async {
    await write(deviceAddress, [data], registerAddress);
  }

  Future<void> writeInt(
      int deviceAddress, int registerAddress, int data) async {
    await write(
        deviceAddress, [data & 0xFF, (data >> 8) & 0xFF], registerAddress);
  }

  Future<void> writeLong(
      int deviceAddress, int registerAddress, int data) async {
    await write(
        deviceAddress,
        [
          data & 0xFF,
          (data >> 8) & 0xFF,
          (data >> 16) & 0xFF,
          (data >> 24) & 0xFF
        ],
        registerAddress);
  }

  Future<List<int>> scan(int? frequency) async {
    frequency ??= 125000;
    await config(frequency);
    List<int> addresses = [];
    for (int i = 0; i < 128; i++) {
      int x = await start(i, 0);
      if ((x & 1) == 0) addresses.add(i);
      await stop();
    }
    return addresses;
  }

  Future<void> sendBurst(int data) async {
    packetHandler.sendByte(commandsProto.i2cHeader);
    packetHandler.sendByte(commandsProto.i2cSend);
    packetHandler.sendByte(data);
  }
}
