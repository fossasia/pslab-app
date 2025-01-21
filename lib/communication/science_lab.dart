import 'dart:math';

import 'package:pslab/communication/commands_proto.dart';
import 'package:pslab/communication/communication_handler.dart';
import 'package:pslab/communication/packet_handler.dart';

import 'analogChannel/analog_acquisition_channel.dart';
import 'analogChannel/analog_constants.dart';
import 'analogChannel/analog_input_source.dart';
import 'digitalChannel/digital_channel.dart';

class ScienceLab {
  late int DDS_CLOCK,
      MAX_SAMPLES,
      samples,
      triggerLevel,
      triggerChannel,
      errorCount,
      channelsInBuffer,
      digitalChannelsInBuffer,
      dataSplitting;
  late double sin1Frequency, sin2Frequency;
  late List<double> currents, currentScalars, gainValues, buffer;
  late double SOCKET_CAPACITANCE, resistanceScaling, timebase;
  late bool streaming, calibrated = false;
  late List<String> allAnalogChannels, allDigitalChannels;
  Map<String, AnalogInputSource> analogInputSources = {};
  Map<String, double> squareWaveFrequency = {};
  Map<String, int> gains = {};
  Map<String, String> waveType = {};
  List<AnalogAcquisitionChannel> aChannels = [];
  List<DigitalChannel> dChannels = [];

  late CommunicationHandler mCommunicationHandler;
  late PacketHandler mPacketHandler;
  late CommandsProto mCommandsProto;
  late AnalogConstants mAnalogConstants;

  ScienceLab(CommunicationHandler communicationHandler) {
    mCommunicationHandler = communicationHandler;
    mCommandsProto = CommandsProto();
    mAnalogConstants = AnalogConstants();
  }

  Future<void> connect() async {
    if (isDeviceFound()) {
      try {
        await mCommunicationHandler.open();
        mPacketHandler = PacketHandler(500, mCommunicationHandler);
      } catch (e) {
        print(e);
      }
    }
    if (isConnected()) {
      await _initializeVariables();
    }
  }

  bool isConnected() {
    return mCommunicationHandler.isConnected();
  }

  bool isDeviceFound() {
    return mCommunicationHandler.isDeviceFound();
  }

  Future<String> getVersion() async {
    if (isConnected()) {
      return await mPacketHandler.getVersion();
    } else {
      return 'Not Connected';
    }
  }

  Future<void> _initializeVariables() async {
    DDS_CLOCK = 0;
    timebase = 40;
    MAX_SAMPLES = mCommandsProto.MAX_SAMPLES;
    samples = MAX_SAMPLES;
    triggerChannel = 0;
    triggerLevel = 550;
    errorCount = 0;
    channelsInBuffer = 0;
    digitalChannelsInBuffer = 0;
    currents = [0.55e-3, 0.55e-6, 0.55e-5, 0.55e-4];
    currentScalars = [1.0, 1.0, 1.0, 1.0];
    dataSplitting = mCommandsProto.DATA_SPLITTING;
    allAnalogChannels = mAnalogConstants.allAnalogChannels;
    for (String aChannel in allAnalogChannels) {
      analogInputSources[aChannel] = AnalogInputSource(aChannel);
    }
    sin1Frequency = 0;
    sin2Frequency = 0;
    squareWaveFrequency['SQR1'] = 0.0;
    squareWaveFrequency['SQR2'] = 0.0;
    squareWaveFrequency['SQR3'] = 0.0;
    squareWaveFrequency['SQR4'] = 0.0;

    if (isConnected()) {
      await runInitSequence(true);
    }
  }

  Future<void> runInitSequence(bool loadCalibrationData) async {
    if (!isConnected()) {
      print("Check hardware connections. Not connected");
    }
    streaming = false;
    for (String aChannel in mAnalogConstants.biPolars) {
      aChannels.add(AnalogAcquisitionChannel(aChannel));
    }
    gainValues = mAnalogConstants.gains;
    buffer = List.filled(10000, 0);
    SOCKET_CAPACITANCE = 5e-11;
    resistanceScaling = 1;
    allDigitalChannels = DigitalChannel.digitalChannelNames;
    gains['CH1'] = 0;
    gains['CH2'] = 0;
    for (int i = 0; i < 4; i++) {
      dChannels.add(DigitalChannel(i));
    }
    if (isConnected()) {
      for (String temp in ['CH1', 'CH2']) {
        await setGain(temp, 0, true);
      }
      for (String temp in ['SI1', 'SI1']) {
        await loadEquation(temp, 'sine');
      }
    }
    calibrated = false;
  }

  Future<double> setGain(String channel, int gain, bool? force) async {
    force ??= false;
    if (gain < 0 || gain > 8) {
      print("Invalid gain parameter. 0-7 only.");
      return 0;
    }
    if (analogInputSources[channel]!.gainPGA == -1) {
      print("No amplifier exists on this channel: $channel");
      return 0;
    }
    bool refresh = false;
    if (gains[channel] != gain) {
      gains[channel] = gain;
      refresh = true;
    }
    if (refresh || force) {
      analogInputSources[channel]!.setGain(gain);
      if (gain > 7) {
        gain = 0;
      }
      try {
        mPacketHandler.sendByte(mCommandsProto.ADC);
        mPacketHandler.sendByte(mCommandsProto.SET_PGA_GAIN);
        mPacketHandler.sendByte(analogInputSources[channel]!.gainPGA);
        mPacketHandler.sendByte(gain);
        await mPacketHandler.getAcknowledgement();
        return gainValues[gain];
      } catch (e) {
        print(e);
      }
    }
    return 0;
  }

  Future<void> loadEquation(String channel, String function) async {
    List<double> span = List.filled(2, 0);
    if (function == 'sine') {
      span[0] = 0;
      span[1] = 2 * pi;
      waveType[channel] = 'sine';
    } else if (function == 'tria') {
      span[0] = 0;
      span[1] = 4;
      waveType[channel] = 'tria';
    } else {
      waveType[channel] = 'orbit';
    }
    double factor = (span[1] - span[0]) / 512;
    List<double> x = [];
    List<double> y = [];
    for (int i = 0; i < 512; i++) {
      x.add(span[0] + i * factor);
      switch (function) {
        case 'sine':
          y.add(sin(x[i]));
          break;
        case 'tria':
          y.add((x[i] % 4 - 2).abs());
          break;
        default:
          break;
      }
    }
    await _loadTable(channel, y, waveType[channel]!, -1);
  }

  Future<void> _loadTable(
      String channel, List<double> y, String mode, double amp) async {
    waveType[channel] = mode;
    List<String> channels = [];
    List<double> points = y;
    channels.add('SI1');
    channels.add('SI2');
    int num;
    if (channels.contains(channel)) {
      num = channels.indexOf(channel) + 1;
    } else {
      print("Channel doesn't exist. Try SI1 or SI2");
      return;
    }
    if (amp == -1) {
      amp = 0.95;
    }
    double LARGE_MAX = 511 * amp, SMALL_MAX = 63 * amp;
    double minimum = y.reduce(min);
    for (int i = 0; i < y.length; i++) {
      y[i] = y[i] - minimum;
    }
    double maximum = y.reduce(max);
    List<int> yMod1 = [];
    for (int i = 0; i < y.length; i++) {
      double temp = 1 - (y[i] / maximum);
      yMod1.add((LARGE_MAX - LARGE_MAX * temp).round());
    }
    y = [];
    for (int i = 0; i < points.length; i += 16) {
      y.add(points[i]);
    }
    minimum = y.reduce(min);
    for (int i = 0; i < y.length; i++) {
      y[i] = y[i] - minimum;
    }
    maximum = y.reduce(max);
    List<int> yMod2 = [];
    for (int i = 0; i < y.length; i++) {
      double temp = 1 - (y[i] / maximum);
      yMod2.add((SMALL_MAX - SMALL_MAX * temp).round());
    }

    try {
      mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
      switch (num) {
        case 1:
          mPacketHandler.sendByte(mCommandsProto.LOAD_WAVEFORM1);
          break;
        case 2:
          mPacketHandler.sendByte(mCommandsProto.LOAD_WAVEFORM2);
          break;
      }
      for (int a in yMod1) {
        mPacketHandler.sendInt(a);
      }
      for (int a in yMod2) {
        mPacketHandler.sendByte(a);
      }
      await mPacketHandler.getAcknowledgement();
    } catch (e) {
      print(e);
    }
  }
}
