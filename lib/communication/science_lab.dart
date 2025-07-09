import 'dart:collection';
import 'dart:math';
import 'package:data/polynomial.dart';
import 'package:flutter/foundation.dart';
import 'package:pslab/communication/commands_proto.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/packet_handler.dart';
import 'package:pslab/communication/socket_client.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';

import 'analogChannel/analog_acquisition_channel.dart';
import 'analogChannel/analog_constants.dart';
import 'analogChannel/analog_input_source.dart';
import 'digitalChannel/digital_channel.dart';

class ScienceLab {
  late int ddsClock,
      maxSamples,
      samples,
      triggerLevel,
      triggerChannel,
      errorCount,
      channelsInBuffer,
      digitalChannelsInBuffer,
      dataSplitting;
  late double sin1Frequency, sin2Frequency;
  late List<double> currents, currentScalars, gainValues, buffer;
  late double socketCapacitance, resistanceScaling, timebase;
  late bool streaming, calibrated = false;
  late List<String> allAnalogChannels, allDigitalChannels;
  Map<String, AnalogInputSource> analogInputSources = {};
  Map<String, double> squareWaveFrequency = {};
  Map<String, int> gains = {};
  Map<String, String> waveType = {};
  List<AnalogAcquisitionChannel> aChannels = [];
  List<DigitalChannel> dChannels = [];
  static final double capacitorDischargeVoltage = 0.01 * 3.3;

  late CommunicationHandler mCommunicationHandler;
  late SocketClient mSocketClient;
  late PacketHandler mPacketHandler;
  late CommandsProto mCommandsProto;
  late AnalogConstants mAnalogConstants;

  ScienceLab(CommunicationHandler communicationHandler) {
    mCommunicationHandler = communicationHandler;
    mSocketClient = getIt.get<SocketClient>();
    mCommandsProto = CommandsProto();
    mAnalogConstants = AnalogConstants();
  }

  Future<void> connect() async {
    if (isDeviceFound()) {
      try {
        await mCommunicationHandler.open();
        mPacketHandler = PacketHandler(500, mCommunicationHandler);
      } catch (e) {
        logger.e(e);
      }
    }
    if (isConnected()) {
      await _initializeVariables();
    }
  }

  Future<void> connectWiFi() async {
    try {
      await mSocketClient.openConnection("192.168.4.1", 80);
      mPacketHandler = PacketHandler(500, mCommunicationHandler);
    } catch (e) {
      logger.e(e);
    }
    if (isConnected()) {
      await _initializeVariables();
    }
  }

  bool isConnected() {
    return (mSocketClient.isConnected() || mCommunicationHandler.isConnected());
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
    ddsClock = 0;
    timebase = 40;
    maxSamples = mCommandsProto.maxSamples;
    samples = maxSamples;
    triggerChannel = 0;
    triggerLevel = 550;
    errorCount = 0;
    channelsInBuffer = 0;
    digitalChannelsInBuffer = 0;
    currents = [0.55e-3, 0.55e-6, 0.55e-5, 0.55e-4];
    currentScalars = [1.0, 2.0, 3.0, 4.0];
    dataSplitting = mCommandsProto.dataSplitting;
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
      logger.d("Check hardware connections. Not connected");
    }
    streaming = false;
    for (String aChannel in mAnalogConstants.biPolars) {
      aChannels.add(AnalogAcquisitionChannel(aChannel));
    }
    gainValues = mAnalogConstants.gains;
    buffer = List.filled(10000, 0);
    socketCapacitance = 46e-12;
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
    await clearBuffer(0, samples);
    calibrated = false;
  }

  Future<double?> getResistance() async {
    double voltage = await getAverageVoltage("RES", null);
    if (voltage > 3.295) {
      return null;
    }
    double current = (3.3 - voltage) / 5.1e3;
    return (voltage / current) * resistanceScaling;
  }

  Future<void> captureTraces(int number, int samples, double timeGap,
      String? channelOneInput, bool trigger, int? ch123sa) async {
    ch123sa ??= 0;
    channelOneInput ??= 'CH1';
    timebase = timeGap;
    timebase = timebase.toInt().toDouble();
    if (!analogInputSources.containsKey(channelOneInput)) {
      logger.e("Invalid channel: $channelOneInput");
      return;
    }
    int chosa = analogInputSources[channelOneInput]!.chosa;
    aChannels[0].setParams(channelOneInput, samples, 0, timebase, 10,
        analogInputSources[channelOneInput], null);
    try {
      mPacketHandler.sendByte(mCommandsProto.adc);
      if (number == 1) {
        if (timeGap < 0.5) {
          timebase = 0.5;
        }
        if (samples > maxSamples) {
          samples = maxSamples;
        }
        if (trigger) {
          if (timeGap < 0.75) {
            timebase = 0.75;
          }
          mPacketHandler.sendByte(mCommandsProto.captureOne);
          mPacketHandler.sendByte(chosa | 0x80);
        } else if (timeGap > 1) {
          aChannels[0].setParams(channelOneInput, samples, 0, timebase, 12,
              analogInputSources[channelOneInput], null);
          mPacketHandler.sendByte(mCommandsProto.captureDmaSpeed);
          mPacketHandler.sendByte(chosa | 0x80);
        } else {
          mPacketHandler.sendByte(mCommandsProto.captureDmaSpeed);
          mPacketHandler.sendByte(chosa);
        }
      } else if (number == 2) {
        if (timeGap < 0.875) {
          timebase = 0.875;
        }
        if (samples > maxSamples / 2) {
          samples = (maxSamples / 2).toInt();
        }
        aChannels[1].setParams('CH2', samples, samples, timebase, 10,
            analogInputSources['CH2'], null);
        mPacketHandler.sendByte(mCommandsProto.captureTwo);
        mPacketHandler.sendByte(chosa | (0x80 * (trigger ? 1 : 0)));
      } else {
        if (timeGap < 1.75) {
          timebase = 1.75;
        }
        if (samples > maxSamples / 4) {
          samples = (maxSamples / 4).toInt();
        }
        int i = 1;
        for (String temp in ['CH2', 'CH3', 'MIC']) {
          aChannels[i].setParams(temp, samples, i * samples, timebase, 10,
              analogInputSources[temp], null);
          i++;
        }
        mPacketHandler.sendByte(mCommandsProto.captureFour);
        mPacketHandler
            .sendByte(chosa | (ch123sa << 4) | (0x80 * (trigger ? 1 : 0)));
      }
      this.samples = samples;
      mPacketHandler.sendInt(samples);
      mPacketHandler.sendInt((timebase * 8).toInt());
      await mPacketHandler.getAcknowledgement();
      channelsInBuffer = number;
    } catch (e) {
      logger.e(e);
    }
  }

  Future<Map<String, List<double>>> fetchTrace(int channelNumber) async {
    await fetchData(channelNumber);
    Map<String, List<double>> retData = {};
    retData['x'] = aChannels[channelNumber - 1].getXAxis();
    retData['y'] = aChannels[channelNumber - 1].getYAxis();
    return retData;
  }

  Future<bool> fetchData(int channelNumber) async {
    int samples = aChannels[channelNumber - 1].length;
    if (channelNumber > channelsInBuffer) {
      logger.e("Channel Unavailable");
      return false;
    }
    logger.d("Samples: $samples");
    logger.d("Data Splitting: $dataSplitting");
    List<int> listData = [];
    try {
      for (int i = 0; i < samples / dataSplitting; i++) {
        mPacketHandler.sendByte(mCommandsProto.common);
        mPacketHandler.sendByte(mCommandsProto.retrieveBuffer);
        mPacketHandler.sendInt(
            aChannels[channelNumber - 1].bufferIndex + (i * dataSplitting));
        mPacketHandler.sendInt(dataSplitting);
        Uint8List data = Uint8List(dataSplitting * 2 + 1);
        await mPacketHandler.read(data, dataSplitting * 2 + 1);
        for (int j = 0; j < data.length - 1; j++) {
          listData.add(data[j] & 0xFF);
        }
      }
      if ((samples % dataSplitting) != 0) {
        mPacketHandler.sendByte(mCommandsProto.common);
        mPacketHandler.sendByte(mCommandsProto.retrieveBuffer);
        mPacketHandler.sendInt(aChannels[channelNumber - 1].bufferIndex +
            samples -
            samples % dataSplitting);
        mPacketHandler.sendInt(samples % dataSplitting);
        Uint8List data = Uint8List(2 * (samples % dataSplitting) + 1);
        await mPacketHandler.read(data, 2 * (samples % dataSplitting) + 1);
        for (int j = 0; j < data.length - 1; j++) {
          listData.add(data[j] & 0xFF);
        }
      }
    } catch (e) {
      logger.e(e);
    }

    for (int i = 0; i < listData.length / 2; i++) {
      buffer[i] = (listData[i * 2] | (listData[i * 2 + 1] << 8)).toDouble();
      while (buffer[i] > 1023) {
        buffer[i] -= 1023;
      }
    }

    logger.d("RAW DATA: ${buffer.sublist(0, samples).toString()}");

    aChannels[channelNumber - 1].yAxis =
        aChannels[channelNumber - 1].fixValue(buffer.sublist(0, samples));
    return true;
  }

  Future<double> setGain(String channel, int gain, bool? force) async {
    force ??= false;
    if (gain < 0 || gain > 8) {
      logger.e("Invalid gain parameter. 0-7 only.");
      return 0;
    }
    if (analogInputSources[channel]?.gainPGA == -1) {
      logger.e("No amplifier exists on this channel: $channel");
      return 0;
    }
    bool refresh = false;
    if (gains[channel] != gain) {
      gains[channel] = gain;
      refresh = true;
    }
    if (refresh || force) {
      analogInputSources[channel]?.setGain(gain);
      if (gain > 7) {
        gain = 0;
      }
      try {
        mPacketHandler.sendByte(mCommandsProto.adc);
        mPacketHandler.sendByte(mCommandsProto.setPgaGain);
        mPacketHandler.sendByte(analogInputSources[channel]!.gainPGA);
        mPacketHandler.sendByte(gain);
        await mPacketHandler.getAcknowledgement();
        return gainValues[gain];
      } catch (e) {
        logger.e(e);
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
      logger.e("Channel doesn't exist. Try SI1 or SI2");
      return;
    }
    if (amp == -1) {
      amp = 0.95;
    }
    double largeMax = 511 * amp, smallMax = 63 * amp;
    double minimum = y.reduce(min);
    for (int i = 0; i < y.length; i++) {
      y[i] = y[i] - minimum;
    }
    double maximum = y.reduce(max);
    List<int> yMod1 = [];
    for (int i = 0; i < y.length; i++) {
      double temp = 1 - (y[i] / maximum);
      yMod1.add((largeMax - largeMax * temp).round());
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
      yMod2.add((smallMax - smallMax * temp).round());
    }

    try {
      mPacketHandler.sendByte(mCommandsProto.wavegen);
      switch (num) {
        case 1:
          mPacketHandler.sendByte(mCommandsProto.loadWaveform1);
          break;
        case 2:
          mPacketHandler.sendByte(mCommandsProto.loadWaveform2);
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
      logger.e(e);
    }
  }

  Future<void> clearBuffer(int startingPosition, int totalPoints) async {
    try {
      mPacketHandler.sendByte(mCommandsProto.common);
      mPacketHandler.sendByte(mCommandsProto.clearBuffer);
      mPacketHandler.sendInt(startingPosition);
      mPacketHandler.sendInt(totalPoints);
      await mPacketHandler.getAcknowledgement();
    } catch (e) {
      logger.e("Error in clearBuffer: $e");
    }
  }

  DigitalChannel getDigitalChannel(int i) {
    return dChannels[i];
  }

  int? calculateDigitalChannel(String name) {
    if (DigitalChannel.digitalChannelNames.contains(name)) {
      return DigitalChannel.digitalChannelNames.indexOf(name);
    } else {
      logger.e("Invalid digital channel name: $name");
      return null;
    }
  }

  int calculateBufferPosition(
      int channel, int offset, int channels, int bytes) {
    int multiplier = (channels < 3) ? 2 : 1;
    return (channel - 1) * bytes * multiplier + offset;
  }

  Future<List<int>?> fetchIntDataFromLA(
      int bytes, int? channel, int channels) async {
    channel ??= 1;
    try {
      List<int> l = [];
      for (int i = 0; i < bytes / dataSplitting; i++) {
        mPacketHandler.sendByte(mCommandsProto.common);
        mPacketHandler.sendByte(mCommandsProto.retrieveBuffer);
        mPacketHandler.sendInt(calculateBufferPosition(
            channel, i * dataSplitting, channels, bytes));
        mPacketHandler.sendInt(dataSplitting);
        Uint8List data = Uint8List(dataSplitting * 2 + 1);
        await mPacketHandler.read(data, dataSplitting * 2 + 1);
        for (int j = 0; j < data.length - 1; j++) {
          l.add(data[j] & 0xFF);
        }
      }

      if ((bytes % dataSplitting) != 0) {
        mPacketHandler.sendByte(mCommandsProto.common);
        mPacketHandler.sendByte(mCommandsProto.retrieveBuffer);
        mPacketHandler.sendInt(calculateBufferPosition(
            channel, bytes - bytes % dataSplitting, channels, bytes));
        mPacketHandler.sendInt(bytes % dataSplitting);
        Uint8List data = Uint8List(2 * (bytes % dataSplitting) + 1);
        await mPacketHandler.read(data, 2 * (bytes % dataSplitting) + 1);
        for (int j = 0; j < data.length - 1; j++) {
          l.add(data[j] & 0xFF);
        }
      }

      if (l.isNotEmpty) {
        String string = "";
        List<int> timeStamps = List.filled(bytes + 1, 0);
        for (int i = 0; i < bytes; i++) {
          int t = (l[i * 2] | (l[i * 2 + 1] << 8));
          timeStamps[i + 1] = t;
          string += "$t ";
        }
        logger.t("Fetched points: $string");
        timeStamps[0] = 1;
        return timeStamps;
      } else {
        logger.e("Error: Obtained bytes = 0");
        List<int> timeStamps = List.filled(2501, 0);
        return timeStamps;
      }
    } catch (e) {
      logger.e("Error in fetchIntDataFromLA: $e");
    }
    return null;
  }

  Future<bool> fetchLAChannel(int channelNumber,
      LinkedHashMap<String, int> initialStates, int channels) async {
    DigitalChannel dChan = dChannels[channelNumber];

    LinkedHashMap<String, int> tempMap = LinkedHashMap<String, int>();
    tempMap['LA1'] = initialStates['LA1']!;
    tempMap['LA2'] = initialStates['LA2']!;
    tempMap['LA3'] = initialStates['LA3']!;
    tempMap['LA4'] = initialStates['LA4']!;
    tempMap['RES'] = initialStates['RES']!;

    int i = 0;
    for (MapEntry<String, int> entry in initialStates.entries) {
      if (dChan.channelNumber == i) {
        i = entry.value;
        break;
      }
      i++;
    }
    List<int>? temp =
        await fetchIntDataFromLA(i, dChan.channelNumber + 1, channels);
    List<double> data = List.filled(temp!.length - 1, 0.0);
    if (temp[0] == 1) {
      for (int j = 1; j < temp.length; j++) {
        data[j - 1] = temp[j].toDouble();
      }
    } else {
      logger.e("Error: Can't load data");
      return false;
    }
    dChan.loadData(tempMap, data);

    dChan.generateAxes();
    return true;
  }

  Future<double> fetchLAChannelFrequency(
      int channelNumber, LinkedHashMap<String, int> initialStates) async {
    double laChannelFrequency = 0;
    DigitalChannel dChan = dChannels[channelNumber];

    LinkedHashMap<String, int> tempMap = LinkedHashMap<String, int>();
    tempMap['LA1'] = initialStates['LA1']!;
    tempMap['LA2'] = initialStates['LA2']!;
    tempMap['LA3'] = initialStates['LA3']!;
    tempMap['LA4'] = initialStates['LA4']!;
    tempMap['RES'] = initialStates['RES']!;

    int i = initialStates['A']!;
    List<int>? temp = await fetchIntDataFromLA(i, 1, 1);
    List<double> data = List.filled(temp!.length - 1, 0.0);
    if (temp[0] == 1) {
      for (int j = 1; j < temp.length; j++) {
        data[j - 1] = temp[j].toDouble();
      }
    } else {
      logger.e("Error: Can't load data");
      return -1;
    }
    dChan.loadData(tempMap, data);

    dChan.generateAxes();
    int count = 0;
    List<double> yAxis = dChan.getYAxis();
    if (count == maxSamples / 2 - 1) {
      laChannelFrequency = 0;
    } else if (yAxis.isNotEmpty &&
        yAxis.length != maxSamples / 2 - 1 &&
        laChannelFrequency != yAxis.length) {
      laChannelFrequency = yAxis.length.toDouble();
    }
    return laChannelFrequency * 2;
  }

  Future<double> getFrequency(String? channel) async {
    channel ??= 'LA1';
    LinkedHashMap<String, int>? data;
    try {
      await startOneChannelLA(channel, 1, channel, 3);
      await Future.delayed(const Duration(milliseconds: 250));
      data = await getLAInitialStates();
      await Future.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      logger.e("Error in getFrequency: $e");
    }
    return await fetchLAChannelFrequency(
        calculateDigitalChannel(channel)!, data!);
  }

  Future<void> startOneChannelLA(String? channel, int? channelMode,
      String? triggerChannel, int? triggerMode) async {
    channel ??= 'LA1';
    channelMode ??= 1;
    triggerChannel ??= 'LA1';
    triggerMode ??= 3;
    try {
      await clearBuffer(0, maxSamples);
      mPacketHandler.sendByte(mCommandsProto.timing);
      mPacketHandler.sendByte(mCommandsProto.startAlternateOneChanLa);
      mPacketHandler.sendByte((maxSamples / 4).toInt());
      int? aqChannel = calculateDigitalChannel(channel);
      int aqMode = channelMode;
      int? trChannel = calculateDigitalChannel(triggerChannel);
      int trMode = triggerMode;
      mPacketHandler.sendByte((aqChannel! << 4) | aqMode);
      mPacketHandler.sendByte((trChannel! << 4) | trMode);
      await mPacketHandler.getAcknowledgement();
      digitalChannelsInBuffer = 1;
      dChannels[aqChannel].prescaler = 0;
      dChannels[aqChannel].dataType = "long";
      dChannels[aqChannel].length = (maxSamples / 4).toInt();
      dChannels[aqChannel].maxTime = (67 * 1e6).toInt();
      dChannels[aqChannel].mode = channelMode;
      dChannels[aqChannel].channelName = channel;
      if (trMode == 3 || trMode == 4 || trMode == 5) {
        dChannels[aqChannel].initialStateOverride = 2;
      } else if (trMode == 2) {
        dChannels[aqChannel].initialStateOverride = 1;
      }
    } catch (e) {
      logger.e("Error starting logic analyzer: $e");
    }
  }

  Future<void> startTwoChannelLA(
      List<String>? channels,
      List<int>? modes,
      int? maximumTime,
      int? trigger,
      String? edge,
      String? triggerChannel) async {
    maximumTime ??= 67;
    trigger ??= 0;
    edge ??= 'rising';
    channels ??= ['LA1', 'LA2'];
    modes ??= [1, 1];
    List<int> chans = [
      calculateDigitalChannel(channels[0])!,
      calculateDigitalChannel(channels[1])!
    ];
    triggerChannel ??= channels[0];
    if (trigger != 0) {
      trigger = 1;
      if (edge == 'falling') {
        trigger |= 2;
      }
      trigger |= (calculateDigitalChannel(triggerChannel)! << 4);
    }

    try {
      await clearBuffer(0, maxSamples);
      mPacketHandler.sendByte(mCommandsProto.timing);
      mPacketHandler.sendByte(mCommandsProto.startTwoChanLa);
      mPacketHandler.sendInt((maxSamples / 4).toInt());
      mPacketHandler.sendByte(trigger);
      mPacketHandler.sendByte(modes[0] | (modes[1] << 4));
      mPacketHandler.sendByte(chans[0] | (chans[1] << 4));
      await mPacketHandler.getAcknowledgement();
      for (int i = 0; i < 2; i++) {
        DigitalChannel temp = dChannels[chans[i]];
        temp.prescaler = 0;
        temp.length = (maxSamples / 4).toInt();
        temp.dataType = "long";
        temp.maxTime = (maximumTime * 1e6).toInt();
        temp.mode = modes[i];
        temp.channelNumber = chans[i];
        temp.channelName = channels[i];
      }
      digitalChannelsInBuffer = 2;
    } catch (e) {
      logger.e("Error starting logic analyzer: $e");
    }
  }

  Future<void> startFourChannelLA(int? trigger, double? maximumTime,
      List<int>? modes, String? edge, List<bool>? triggerChannel) async {
    trigger ??= 1;
    maximumTime ??= 0.001;
    modes ??= [1, 1, 1, 1];
    edge ??= '0';
    await clearBuffer(0, maxSamples);
    int prescale = 0;
    try {
      mPacketHandler.sendByte(mCommandsProto.timing);
      mPacketHandler.sendByte(mCommandsProto.startFourChanLa);
      mPacketHandler.sendInt((maxSamples / 4).toInt());
      mPacketHandler.sendInt(
          modes[0] | (modes[1] << 4) | (modes[2] << 8) | (modes[3] << 12));
      mPacketHandler.sendByte(prescale);
      int triggerOptions = 0;
      for (int i = 0; i < 3; i++) {
        if (triggerChannel![i]) {
          triggerOptions |= (4 << i);
        }
      }
      if (triggerOptions == 0) {
        triggerOptions |= 4;
      }
      if (edge == 'rising') {
        triggerOptions |= 2;
      }
      trigger |= triggerOptions;
      mPacketHandler.sendByte(trigger);
      await mPacketHandler.getAcknowledgement();
      digitalChannelsInBuffer = 4;
      int i = 0;
      for (DigitalChannel dChan in dChannels) {
        dChan.prescaler = prescale;
        dChan.dataType = "int";
        dChan.length = (maxSamples / 4).toInt();
        dChan.maxTime = (maximumTime * 1e6).toInt();
        dChan.mode = modes[i];
        dChan.channelName = DigitalChannel.digitalChannelNames[i];
        i++;
      }
    } catch (e) {
      logger.e("Error starting logic analyzer: $e");
    }
  }

  Future<LinkedHashMap<String, int>?> getLAInitialStates() async {
    try {
      mPacketHandler.sendByte(mCommandsProto.timing);
      mPacketHandler.sendByte(mCommandsProto.getInitialDigitalStates);
      Uint8List initialStatesBytes = Uint8List(13);
      await mPacketHandler.read(initialStatesBytes, 13);
      int initial = (initialStatesBytes[0] & 0xFF) |
          ((initialStatesBytes[1] << 8) & 0xFF00);
      int A = ((((initialStatesBytes[2] & 0xFF) |
                      ((initialStatesBytes[3] << 8) & 0xFF00)) -
                  initial) /
              2)
          .toInt();
      int B = ((((initialStatesBytes[4] & 0xFF) |
                          ((initialStatesBytes[5] << 8) & 0xFF00)) -
                      initial) /
                  2 -
              maxSamples / 4)
          .toInt();
      int C = ((((initialStatesBytes[6] & 0xFF) |
                          ((initialStatesBytes[7] << 8) & 0xFF00)) -
                      initial) /
                  2 -
              2 * maxSamples / 4)
          .toInt();
      int D = ((((initialStatesBytes[8] & 0xFF) |
                          ((initialStatesBytes[9] << 8) & 0xFF00)) -
                      initial) /
                  2 -
              3 * maxSamples / 4)
          .toInt();
      int s = initialStatesBytes[10] & 0xFF;

      if (A == 0) {
        A = (maxSamples / 4).toInt();
      }
      if (B == 0) {
        B = (maxSamples / 4).toInt();
      }
      if (C == 0) {
        C = (maxSamples / 4).toInt();
      }
      if (D == 0) {
        D = (maxSamples / 4).toInt();
      }

      if (A < 0) {
        A = 0;
      }
      if (B < 0) {
        B = 0;
      }
      if (C < 0) {
        C = 0;
      }
      if (D < 0) {
        D = 0;
      }

      LinkedHashMap<String, int> retData = LinkedHashMap<String, int>();
      retData['A'] = A;
      retData['B'] = B;
      retData['C'] = C;
      retData['D'] = D;

      if ((s & 1) != 0) {
        retData['LA1'] = 1;
      } else {
        retData['LA1'] = 0;
      }
      if ((s & 2) != 0) {
        retData['LA2'] = 1;
      } else {
        retData['LA2'] = 0;
      }
      if ((s & 4) != 0) {
        retData['LA3'] = 1;
      } else {
        retData['LA3'] = 0;
      }
      if ((s & 8) != 0) {
        retData['LA4'] = 1;
      } else {
        retData['LA4'] = 0;
      }
      if ((s & 16) != 0) {
        retData['RES'] = 1;
      } else {
        retData['RES'] = 0;
      }
      return retData;
    } catch (e) {
      logger.e("Error in getLAInitialStates: $e");
    }
    return null;
  }

  Future<void> countPulses(String? channel) async {
    channel ??= 'RES';
    try {
      mPacketHandler.sendByte(mCommandsProto.common);
      mPacketHandler.sendByte(mCommandsProto.startCounting);
      mPacketHandler.sendByte(calculateDigitalChannel(channel)!);
      await mPacketHandler.getAcknowledgement();
    } catch (e) {
      logger.e("Error in countPulses: $e");
    }
  }

  Future<int> readPulseCount() async {
    try {
      mPacketHandler.sendByte(mCommandsProto.common);
      mPacketHandler.sendByte(mCommandsProto.fetchCount);
      int count = await mPacketHandler.getVoltageSummation();
      return 10 * count;
    } catch (e) {
      logger.e("Error in readPulseCount: $e");
    }
    return -1;
  }

  int calcCHOSA(String channelName) {
    channelName = channelName.toUpperCase();
    AnalogInputSource? source = analogInputSources[channelName];
    bool found = false;
    for (String temp in allAnalogChannels) {
      if (temp == channelName) {
        found = true;
        break;
      }
    }
    if (!found) {
      logger.e("Invalid channel name: $channelName");
      return calcCHOSA("CH1");
    }

    return source!.chosa;
  }

  Future<double> getVoltage(String channelName, int sample) async {
    await voltmeterAutoRange(channelName);
    double voltage = await getAverageVoltage(channelName, sample);
    if (channelName == 'CH1' || channelName == 'CH2') {
      return 2 * voltage;
    }
    return voltage;
  }

  Future<void> voltmeterAutoRange(String channelName) async {
    if (analogInputSources[channelName]!.gainPGA != 0) {
      await setGain(channelName, 0, true);
    }
  }

  Future<double> getAverageVoltage(String channelName, int? sample) async {
    sample ??= 1;
    Polynomial poly;
    double sum = 0;
    poly = analogInputSources[channelName]!.calPoly12;
    List<double> vals = [];
    for (int i = 0; i < sample; i++) {
      vals.add(await getRawAverageVoltage(channelName));
    }
    for (int j = 0; j < vals.length; j++) {
      sum = sum + poly.evaluate(vals[j]);
    }
    return sum / 2 * vals.length;
  }

  Future<double> getRawAverageVoltage(String channelName) async {
    try {
      int chosa = calcCHOSA(channelName);
      mPacketHandler.sendByte(mCommandsProto.adc);
      mPacketHandler.sendByte(mCommandsProto.getVoltageSummed);
      mPacketHandler.sendByte(chosa);
      int vSum = await mPacketHandler.getVoltageSummation();
      return vSum / 16.0;
    } catch (e) {
      logger.e("Error in getRawAverageVoltage");
    }
    return 0;
  }

  Future<void> setCapacitorState(int state, int t) async {
    try {
      mPacketHandler.sendByte(mCommandsProto.adc);
      mPacketHandler.sendByte(mCommandsProto.setCap);
      mPacketHandler.sendByte(state);
      mPacketHandler.sendInt(t);
      await mPacketHandler.getAcknowledgement();
    } catch (e) {
      logger.e("Error in setCapacitorState: $e");
    }
  }

  Future<void> dischargeCap(int dischargeTime, double timeout) async {
    DateTime startTime = DateTime.now();

    double voltage = await getVoltage("CAP", 1);
    double previousVoltage = voltage;

    while (voltage > capacitorDischargeVoltage) {
      await setCapacitorState(0, dischargeTime);
      voltage = await getVoltage("CAP", 1);

      if ((previousVoltage - voltage).abs() < capacitorDischargeVoltage) {
        break;
      }

      previousVoltage = voltage;
      if (DateTime.now().difference(startTime).inMilliseconds > timeout) {
        break;
      }
    }
  }

  Future<double?> getCapacitance() async {
    List<double> goodVolts = [2.5, 3.3];
    int ct = 10;
    int cr = 1;
    int iterations = 0;
    double startTime = DateTime.now().millisecondsSinceEpoch / 1000;
    while (DateTime.now().millisecondsSinceEpoch / 1000 - startTime < 5) {
      if (ct > 65000) {
        logger.t("CT too high");
        ct = (ct / pow(10, (4 - cr))).toInt();
        cr = 0;
      }
      List<double>? temp = await getCap(cr, 0, ct);
      double V = temp![0];
      double C = temp[1];
      if (ct > 30000 && V < 0.1) {
        logger.t("Capacitance too high!");
        return null;
      } else if (V > goodVolts[0] && V < goodVolts[1]) {
        return C;
      } else if (V < goodVolts[0] && V > 0.01 && ct < 40000) {
        if (goodVolts[0] / V > 1.1 && iterations < 10) {
          ct = (ct * goodVolts[0] / V).toInt();
          iterations++;
          logger.t("Increasing charge time: $ct");
        } else if (iterations == 10) {
          return null;
        } else {
          return C;
        }
      } else if (V <= 0.1 && cr <= 3) {
        if (cr == 3) {
          cr = 0;
        } else {
          cr++;
        }
      } else if (cr == 0) {
        logger.t("Capacitance too high!");
        return null;
      }
    }
    return null;
  }

  Future<List<double>?> getCap(
      int currentRange, double trim, int chargeTime) async {
    await dischargeCap(30000, 1000);
    try {
      mPacketHandler.sendByte(mCommandsProto.common);
      mPacketHandler.sendByte(mCommandsProto.getCapacitance);
      mPacketHandler.sendByte(currentRange);
      if (trim < 0) {
        mPacketHandler.sendByte((31 - trim.abs() / 2).toInt() | 32);
      } else {
        mPacketHandler.sendByte((trim / 2).toInt());
      }
      mPacketHandler.sendInt(chargeTime);
      await Future.delayed(
          Duration(seconds: (chargeTime * 1e-6 + 0.02).toInt()));
      int vCode;
      int i = 0;
      do {
        vCode = await mPacketHandler.getVoltageSummation();
      } while (vCode == -1 && i++ < 10);
      double v = 3.3 * vCode / 4095;
      double chargeCurrent = currents[currentRange] * (100 + trim) / 100;
      double c = 0;
      if (v != 0) {
        c = (chargeCurrent * chargeTime * 1e-6 / v - socketCapacitance);
      }
      return [v, c];
    } catch (e) {
      logger.e("Error in getCapacitance: $e");
    }
    return null;
  }

  Future<void> servo4(
    double? angle1,
    double? angle2,
    double? angle3,
    double? angle4, {
    int maxAngle = 180,
    int frequency = 50,
  }) async {
    final int period = (1000000 ~/ frequency);
    const int base = 750;
    final int range = maxAngle == 360 ? 3800 : 1900;
    const int params = (1 << 5) | 2;

    try {
      mPacketHandler.sendByte(mCommandsProto.wavegen);
      mPacketHandler.sendByte(mCommandsProto.sqr4);
      mPacketHandler.sendInt(period);

      mPacketHandler
          .sendInt(angle1 != null ? base + (angle1 * range ~/ maxAngle) : -1);
      mPacketHandler.sendInt(0);

      mPacketHandler
          .sendInt(angle2 != null ? base + (angle2 * range ~/ maxAngle) : -1);
      mPacketHandler.sendInt(0);

      mPacketHandler
          .sendInt(angle3 != null ? base + (angle3 * range ~/ maxAngle) : -1);
      mPacketHandler.sendInt(0);

      mPacketHandler
          .sendInt(angle4 != null ? base + (angle4 * range ~/ maxAngle) : -1);

      mPacketHandler.sendByte(params);
      await mPacketHandler.getAcknowledgement();
    } catch (e) {
      logger.e("Error in servo4(): $e");
    }
  }
}
