import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:data/data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:pslab/models/oscilloscope_measurements.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/others/oscilloscope_axes_scale.dart';
import 'package:pslab/others/ringbuffer.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/oscilloscope_config_provider.dart';
import 'package:pslab/src/rust/api/labrador.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:pslab/providers/board_state_provider.dart';

import '../communication/analytics_class.dart';
import '../hal/hardware_board.dart';
import '../hal/oscilloscope_interface.dart';
import '../hal/labrador_oscilloscope.dart';
import '../models/oscilloscope_recording_metadata.dart';
import '../others/audio_jack.dart';

enum MODE { rising, falling, dual }

enum ChannelMeasurements {
  frequency,
  period,
  amplitude,
  positivePeak,
  negativePeak
}

final Map<String, Color> plotColors = {
  'CH1': Colors.cyan,
  'CH2': Colors.green,
  'CH3': Colors.white,
  'MIC': Colors.purpleAccent
};

final Color curveFitColor = Colors.yellow;

final Color xyPlotColor = Colors.red;

class OscilloscopeStateProvider extends ChangeNotifier {
  late OscilloscopeConfigProvider _configProvider;
  late AudioJack _audioJack;
  late int _selectedIndex;
  late String selectedChannelOffset;

  int get selectedIndex => _selectedIndex;

  void updateSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void toggleRunning() {
    isRunning = !isRunning;
    logger.i("[OSC_PROVIDER] Toggled running state: $isRunning");
    notifyListeners();
  }

  late int samples;
  late double timeGap;
  late double timebase;
  double maxTimebase = 102.4;
  final Set<String> _selectedChannels = {};
  late bool _isBuiltInMICSelected;
  late bool isAudioInputSelected;

  bool _isTriggerSelected = false;
  bool get isTriggerSelected => _isTriggerSelected;
  set isTriggerSelected(bool value) {
    _isTriggerSelected = value;
    try {
      labradorSetTriggerEnabled(enabled: value);
    } catch (e) {
      logger.e('Failed to set labrador trigger enabled: $e');
    }
  }

  late bool isTriggered;
  late bool isFourierTransformSelected;
  late bool isXYPlotSelected;

  late bool isStackedMode;
  late bool sineFit;
  late bool squareFit;
  late String triggerChannel;
  late String triggerMode;
  late String curveFittingChannel1;
  late String curveFittingChannel2;
  late Map<String, double> xOffsets;
  late Map<String, double> yOffsets;
  late double trigger;

  late BoardStateProvider _boardState;

  late AnalyticsClass _analyticsClass;
  late bool _monitor;
  late double _maxAmp;
  late double _maxFreq;
  late bool isRunning;
  bool _isPlayingBack = false;
  bool get isPlayingBack => _isPlayingBack;
  bool _isPlaybackPaused = false;
  bool get isPlaybackPaused => _isPlaybackPaused;
  bool _isPlaybackComplete = false;
  bool get isPlaybackComplete => _isPlaybackComplete;

  int get playbackTotalFrames {
    if (_playbackData == null) return 0;
    final n = _playbackData!.length - 1;
    return n > 0 ? n : 0;
  }

  int get playbackCurrentFrame {
    if (_playbackData == null) return 0;
    return (_playbackIndex - 1).clamp(0, playbackTotalFrames);
  }

  Duration get playbackPosition {
    if (_playbackData == null) return Duration.zero;
    final base = _firstTimestampMs;
    if (base == 0) return Duration.zero;
    final shown = (_playbackIndex - 1).clamp(1, _playbackData!.length - 1);
    final cur = int.tryParse(_playbackData![shown][0].toString());
    if (cur == null) return Duration.zero;
    final ms = cur - base;
    return Duration(milliseconds: ms > 0 ? ms : 0);
  }

  Duration get playbackDuration {
    final ms = _lastTimestampMs - _firstTimestampMs;
    return Duration(milliseconds: ms > 0 ? ms : 0);
  }

  int get _firstTimestampMs {
    if (_playbackData == null) return 0;
    for (int i = 1; i < _playbackData!.length; i++) {
      final v = int.tryParse(_playbackData![i][0].toString());
      if (v != null) return v;
    }
    return 0;
  }

  int get _lastTimestampMs {
    if (_playbackData == null) return 0;
    for (int i = _playbackData!.length - 1; i >= 1; i--) {
      final v = int.tryParse(_playbackData![i][0].toString());
      if (v != null) return v;
    }
    return 0;
  }

  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  Function? onPlaybackEnd;
  late bool _isRecording;
  bool get isRecording => _isRecording;
  bool isMeasurementsChecked = false;
  late Map<String, int> _channelIndexMap;
  late String xyPlotAxis1;
  late String xyPlotAxis2;
  final Map<String, RingBuffer<List<FlSpot>>> _waveformBuffer =
      <String, RingBuffer<List<FlSpot>>>{};
  late List<List<FlSpot>> dataEntriesXYPlot;
  late List<List<FlSpot>> dataEntriesCurveFit;
  late List<String> dataParamsChannels;
  List<List<dynamic>> _recordedData = [];
  DateTime? _recordingStartedAt;
  OscilloscopeRecordingMetadata? _lastRecordingMetadata;

  OscilloscopeRecordingMetadata? get recordingMetadata =>
      _lastRecordingMetadata;
  late int _timebaseDivisions;
  int get timebaseDivisions => _timebaseDivisions;
  bool _wakelockEnabled = false;

  late double timebaseSlider;

  late int oscillscopeRangeSelection;

  late bool _isProcessing;

  late Timer _timer;

  late OscilloscopeAxesScale oscilloscopeAxesScale;

  Position? currentPosition;
  StreamSubscription? _locationStream;

  OscilloscopeStateProvider() {
    _audioJack = AudioJack();
    _selectedIndex = 0;
    selectedChannelOffset = 'CH1';

    _isBuiltInMICSelected = false;
    isAudioInputSelected = false;
    isTriggerSelected = false;
    isTriggered = false;
    isFourierTransformSelected = false;
    isXYPlotSelected = false;
    isStackedMode = false;
    _monitor = true;
    _isRecording = false;
    isRunning = true;
    xyPlotAxis1 = 'CH1';
    xyPlotAxis2 = 'CH2';
    _timebaseDivisions = 8;
    timebaseSlider = 0;
    oscillscopeRangeSelection = 0;
    _isProcessing = false;

    dataEntriesXYPlot = <List<FlSpot>>[];
    dataEntriesCurveFit = <List<FlSpot>>[];
    dataParamsChannels = <String>[];

    _channelIndexMap = <String, int>{};
    _channelIndexMap['CH1'] = 1;
    _channelIndexMap['CH2'] = 2;
    _channelIndexMap['CH3'] = 3;
    _channelIndexMap['MIC'] = 4;

    _boardState = getIt.get<BoardStateProvider>();

    triggerChannel = 'CH1';
    triggerMode = MODE.rising.toString();
    trigger = 0;
    timebase = 875;
    samples = 512;
    timeGap = (2 * timebase) / samples;

    xOffsets = <String, double>{};
    xOffsets['CH1'] = 0.0;
    xOffsets['CH2'] = 0.0;
    xOffsets['CH3'] = 0.0;
    xOffsets['MIC'] = 0.0;
    yOffsets = <String, double>{};
    yOffsets['CH1'] = 0.0;
    yOffsets['CH2'] = 0.0;
    yOffsets['CH3'] = 0.0;
    yOffsets['MIC'] = 0.0;

    sineFit = true;
    squareFit = false;
    curveFittingChannel1 = '';
    curveFittingChannel2 = '';
    _analyticsClass = AnalyticsClass();
    oscilloscopeAxesScale = OscilloscopeAxesScale();

    monitor();
  }

  bool get isBuiltInMICSelected => _isBuiltInMICSelected;

  set isBuiltInMICSelected(bool isBuiltInMICSelected) {
    _isBuiltInMICSelected = isBuiltInMICSelected;
    if (isBuiltInMICSelected) {
      _waveformBuffer.putIfAbsent('MIC', _createWaveformBuffer);
    } else {
      _waveformBuffer.remove('MIC');
    }
  }

  RingBuffer<List<FlSpot>> _createWaveformBuffer() =>
      RingBuffer<List<FlSpot>>(_configProvider.config.bufferSize + 1);

  void _clearWaveformBuffers() {
    for (final buffer in _waveformBuffer.values) {
      buffer.clear();
    }
  }

  List<FlSpot>? _latestWaveform(String channel) {
    final buffer = _waveformBuffer[channel];
    return buffer == null || buffer.isEmpty ? null : buffer.last;
  }

  void setConfigProvider(
      OscilloscopeConfigProvider oscilloscopeConfigProvider) {
    _configProvider = oscilloscopeConfigProvider;
  }

  bool isBufferOverlayEnabled() => _configProvider.config.bufferOverlayEnabled;

  void setChannelSelected(String channel, bool selected) {
    if (selected) {
      _selectedChannels.add(channel);
      _waveformBuffer.putIfAbsent(channel, _createWaveformBuffer);
    } else {
      _selectedChannels.remove(channel);
      _removeChannelData(channel);
      _waveformBuffer.remove(channel);
    }

    final chNum = _channelIndexMap[channel];
    if (chNum != null) {
      _boardState.activeBoard?.oscilloscope?.configureChannel(chNum, selected);
    }
    notifyListeners();
  }

  bool isChannelSelected(String channel) {
    return _selectedChannels.contains(channel);
  }

  void removeChannelData(String channel) {
    _removeChannelData(channel);
    notifyListeners();
  }

  void _removeChannelData(String channel) {
    final index = dataParamsChannels.indexOf(channel);
    if (index == -1) {
      return;
    }

    dataParamsChannels.removeAt(index);

    if (curveFittingChannel1 == channel) {
      curveFittingChannel1 = '';
      dataEntriesCurveFit = [];
    }
    if (curveFittingChannel2 == channel) {
      curveFittingChannel2 = '';
      dataEntriesCurveFit = [];
    }
  }

  Future<void> _startGeoLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logger.w('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.w('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logger.w(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).listen((Position position) {
      currentPosition = position;
    });
  }

  Future<void> monitor() async {
    _timer = Timer.periodic(
      const Duration(milliseconds: 10),
      (timer) async {
        if (!_monitor) {
          timer.cancel();
          return;
        }

        if (_isProcessing) {
          return;
        }
        _isProcessing = true;

        if (isRunning) {
          if (isBuiltInMICSelected && !_audioJack.isListening()) {
            await _audioJack.initialize();
            await _audioJack.start();
          }

          List<String> channels = [];

          final HardwareBoard? board = _boardState.activeBoard;
          final bool hasOscilloscope =
              board?.isConnected == true && board?.oscilloscope != null;

          if (hasOscilloscope && isXYPlotSelected) {
            await xyPlotTask(xyPlotAxis1, xyPlotAxis2);
            if (!_wakelockEnabled) {
              WakelockPlus.enable();
              _wakelockEnabled = true;
            }
          } else {
            if (hasOscilloscope) {
              if (isChannelSelected('CH1')) {
                channels.add('CH1');
              }
              if (isChannelSelected('CH2')) {
                channels.add('CH2');
              }
              if (isChannelSelected('CH3')) {
                channels.add('CH3');
              }
            }
            if (isAudioInputSelected && _isBuiltInMICSelected ||
                (hasOscilloscope && isChannelSelected('MIC'))) {
              channels.add('MIC');
            }
            if (channels.isNotEmpty) {
              if (!_wakelockEnabled) {
                WakelockPlus.enable();
                _wakelockEnabled = true;
              }
              await captureTask(channels);
            } else {
              if (_wakelockEnabled) {
                WakelockPlus.disable();
                _wakelockEnabled = false;
              }
              resetGraph();
            }
          }
          if (!_isBuiltInMICSelected && _audioJack.isListening()) {
            await _audioJack.close();
          }
        }
        _isProcessing = false;
      },
    );
  }

  Future<void> xyPlotTask(String xyPlotAxis1, String xyPlotAxis2) async {
    String analogInput1 = xyPlotAxis1;
    String analogInput2 = xyPlotAxis2;
    List<List<FlSpot>> entries = [];

    OscilloscopeInterface? activeScope = _boardState.activeBoard?.oscilloscope;
    if (activeScope == null) return;

    entries.add([]);

    if (analogInput1 == analogInput2) {
      int chNum = _channelIndexMap[analogInput1]!;
      await activeScope.configureChannel(chNum, true);
      List<double> yData = await activeScope.fetchSamples(samples, chNum);

      int n = yData.length;
      for (int i = 0; i < n; i++) {
        entries[0].add(FlSpot(yData[i], yData[i]));
      }
    } else {
      int chNum1 = _channelIndexMap[analogInput1]!;
      int chNum2 = _channelIndexMap[analogInput2]!;

      await activeScope.configureChannel(chNum1, true);
      await activeScope.configureChannel(chNum2, true);

      double timeWindowSecs = (175 * timeGap) / 1000000.0;
      if (timeWindowSecs <= 0) timeWindowSecs = 0.00035;

      List<double> yData1 =
          await activeScope.fetchSamples(175, chNum1, timeWindowSecs);
      List<double> yData2 =
          await activeScope.fetchSamples(175, chNum2, timeWindowSecs);

      int n = min(yData1.length, yData2.length);
      for (int i = 0; i < n; i++) {
        entries[0].add(FlSpot(yData1[i], yData2[i]));
      }
    }

    dataEntriesXYPlot = List.from(entries);
    notifyListeners();
  }

  Future<void> captureTask(List<String> channels) async {
    List<List<FlSpot>> entries = [];
    List<List<FlSpot>> curveFitEntries = [];
    int noOfChannels = channels.length;
    List<String> paramsChannels = channels;
    String? channel;

    if (_isBuiltInMICSelected) {
      noOfChannels--;
    }

    try {
      List<List<String>> yDataString = [];
      List<String> xDataString = [];
      _maxAmp = 0;

      OscilloscopeInterface? activeScope =
          _boardState.activeBoard?.oscilloscope;
      final bool isLabrador = activeScope is LabradorOscilloscope;
      List<Map<String, List<double>>> allChannelData = [];
      double? masterTriggerTime;

      if (activeScope != null && noOfChannels > 0) {
        if (isLabrador) {
          timeGap = timebase / samples;
          try {
            labradorSetTriggerEnabled(enabled: isTriggerSelected);
          } catch (_) {}
        }

        for (int i = 0; i < noOfChannels; i++) {
          int chNum = _channelIndexMap[channels[i]]!;
          await activeScope.configureChannel(chNum, true);
        }

        for (int i = 0; i < noOfChannels; i++) {
          channel = channels[i];
          int chNum = _channelIndexMap[channel]!;

          double timeWindowSecs = isLabrador
              ? (timebase / 1000000.0)
              : ((samples * timeGap) / 1000000.0);
          if (timeWindowSecs <= 0) timeWindowSecs = 0.00035;

          List<double> yData =
              await activeScope.fetchSamples(samples, chNum, timeWindowSecs);

          List<double> xData;
          if (isLabrador) {
            double maxXVal = (timebase == 875) ? timebase : (timebase / 1000.0);
            double xStep =
                (yData.length > 1) ? maxXVal / (yData.length - 1) : 0.0;
            xData = List.generate(yData.length, (idx) => idx * xStep);
          } else {
            xData = List.generate(yData.length, (idx) {
              return (idx * timeGap) / ((timebase == 875) ? 1.0 : 1000.0);
            });
          }

          allChannelData.add({'x': xData, 'y': yData});
        }
      }

      if (activeScope != null && noOfChannels > 0) {
        if (!isLabrador) {
          for (int i = 0; i < noOfChannels; i++) {
            channel = channels[i];
            Map<String, List<double>> data = allChannelData[i];
            List<double> xRaw = data['x']!;

            if (isTriggerSelected &&
                triggerChannel == channel &&
                !isFourierTransformSelected) {
              List<double> yRaw = data['y']!;

              logger.d(
                  "Provider Software Trigger active. Mode: $triggerMode, Level: $trigger");

              if (yRaw.isNotEmpty) {
                double prevY = yRaw[0];
                bool increasing = false;
                bool found = false;

                for (int j = 0; j < min(xRaw.length, yRaw.length); j++) {
                  double currY = yRaw[j];
                  if (currY > prevY) {
                    increasing = true;
                  } else if (currY < prevY && increasing) {
                    increasing = false;
                  }

                  bool triggered = false;
                  if (triggerMode == MODE.rising.toString() &&
                      prevY < trigger &&
                      currY >= trigger &&
                      increasing) {
                    triggered = true;
                  } else if (triggerMode == MODE.falling.toString() &&
                      prevY > trigger &&
                      currY <= trigger &&
                      !increasing) {
                    triggered = true;
                  } else if (triggerMode == MODE.dual.toString() &&
                      ((prevY < trigger && currY >= trigger && increasing) ||
                          (prevY > trigger &&
                              currY <= trigger &&
                              !increasing))) {
                    triggered = true;
                  }

                  if (triggered) {
                    masterTriggerTime = xRaw[j];
                    found = true;
                    logger.i(
                        "Trigger FOUND at index $j, Time: $masterTriggerTime");
                    break;
                  }
                  prevY = currY;
                }
                if (!found) {
                  logger.w(
                      "Software trigger active but edge NOT FOUND. (Vpp might be too low or flatlined)");
                }
              }
            }
          }
        }

        for (int i = 0; i < noOfChannels; i++) {
          entries.add([]);
          channel = channels[i];

          Map<String, List<double>> data = allChannelData[i];
          List<double> xData = data['x']!;
          List<double> yData = data['y']!;
          int n = min(xData.length, yData.length);

          if (n == 0) {
            logger.w("Skipping rendering for $channel because array is empty!");
            continue;
          }

          xDataString = List.filled(n, '');
          yDataString.add(List.filled(n, ''));

          List<Complex> fftOut = [];
          if (isFourierTransformSelected) {
            List<Complex> yComplex =
                List.filled(yData.length, const Complex(0));
            for (int j = 0; j < yData.length; j++) {
              yComplex[j] = Complex(yData[j]);
            }
            fftOut = fft(yComplex);
          }

          double factor = samples * timeGap * 1e-3;
          _maxFreq = (n / 2 - 1) / factor;
          double mA = 0;

          int startIndex = 0;

          if (!isLabrador &&
              !isFourierTransformSelected &&
              isTriggerSelected &&
              masterTriggerTime != null) {
            int foundIndex = xData.indexWhere((t) => t >= masterTriggerTime!);
            if (foundIndex != -1) {
              startIndex = foundIndex;
            }
            logger.d(
                "Shifting render start index to $startIndex due to masterTriggerTime");
          }

          for (int j = startIndex; j < n; j++) {
            double timeShift =
                (!isLabrador && isTriggerSelected && masterTriggerTime != null)
                    ? masterTriggerTime
                    : xData[startIndex];
            double relativeTime = xData[j] - timeShift;

            if (!isFourierTransformSelected) {
              entries[i].add(FlSpot(relativeTime + xOffsets[channels[i]]!,
                  yData[j] + yOffsets[channels[i]]!));
            } else {
              if (j < n / 2) {
                double y = fftOut[j].abs() / samples;
                if (y > mA) mA = y;
                entries[i].add(FlSpot(j / factor, y));
              }
              xDataString[j] = xData[j].toString();
              yDataString[i][j] = yData[j].toString();
            }
          }

          if (sineFit && channel == curveFittingChannel1) {
            List<double> xFit = xData.sublist(startIndex);
            List<double> yFit = yData.sublist(startIndex);

            if (xFit.isNotEmpty) {
              if (curveFitEntries.isEmpty) curveFitEntries.add([]);
              List<double> sinFit = _analyticsClass.sineFit(xFit, yFit);
              double amp = sinFit[0];
              double freq = sinFit[1] / 1e6;
              double offset = sinFit[2];
              double phase = sinFit[3];
              double maxX = xFit.last - xFit.first;

              for (int k = 0; k < 500; k++) {
                double x = k * maxX / 500;
                double y = offset +
                    amp * sin(((freq * (2 * pi)).abs()) * x + phase * pi / 180);
                curveFitEntries.last.add(FlSpot(x, y));
              }
            }
          }

          if (squareFit && channel == curveFittingChannel2) {
            List<double> xFit = xData.sublist(startIndex);
            List<double> yFit = yData.sublist(startIndex);

            if (xFit.isNotEmpty) {
              if (curveFitEntries.isEmpty) curveFitEntries.add([]);
              List<double> sqFit = _analyticsClass.squareFit(xFit, yFit);
              double amp = sqFit[0];
              double freq = sqFit[1] / 1e6;
              double phase = sqFit[2];
              double dc = sqFit[3];
              double offset = sqFit[4];
              double maxX = xFit.last - xFit.first;

              for (int k = 0; k < 500; k++) {
                double x = k * maxX / 500;
                double t = 2 * pi * freq * (x - phase);
                double y = (t % (2 * pi) < 2 * pi * dc)
                    ? offset + amp
                    : offset - 2 * amp;
                curveFitEntries.last.add(FlSpot(x, y));
              }
            }
          }

          if (mA > _maxAmp) _maxAmp = mA;
        }
      }

      if (_isBuiltInMICSelected) {
        noOfChannels++;
        isTriggered = false;
        entries.add([]);
        List<double> buffer = _audioJack.read();

        if (buffer.isEmpty) return;

        xDataString = List.filled(buffer.length, '');
        yDataString.add(List.filled(buffer.length, ''));
        int n = buffer.length;

        List<double> micXData = List.generate(n, (i) {
          double t = ((i / AudioJack.samplingRate) * 1000000.0);
          return t / ((timebase == 875) ? 1 : 1000);
        });

        List<Complex> fftOut = [];
        if (isFourierTransformSelected) {
          List<Complex> yComplex =
              List.filled(buffer.length, const Complex(0), growable: true);
          for (int j = 0; j < buffer.length; j++) {
            yComplex[j] = Complex(buffer[j] * 3);
          }
          fftOut = fft(yComplex);
        }

        double factor = buffer.length * timeGap * 1e-3;
        _maxFreq = (n / 2 - 1) / factor;
        double mA = 0;

        int micStartIndex = 0;
        double micTimeShift = 0;

        if (!isFourierTransformSelected &&
            isTriggerSelected &&
            triggerChannel == 'MIC') {
          double prevY = buffer[0] * 3;
          bool increasing = false;
          for (int j = 0; j < n; j++) {
            double currY = buffer[j] * 3;
            if (currY > prevY) {
              increasing = true;
            } else if (currY < prevY && increasing) {
              increasing = false;
            }

            bool triggered = false;
            if (triggerMode == MODE.rising.toString() &&
                prevY < trigger &&
                currY >= trigger &&
                increasing) {
              triggered = true;
            } else if (triggerMode == MODE.falling.toString() &&
                prevY > trigger &&
                currY <= trigger &&
                !increasing) {
              triggered = true;
            } else if (triggerMode == MODE.dual.toString() &&
                ((prevY < trigger && currY >= trigger && increasing) ||
                    (prevY > trigger && currY <= trigger && !increasing))) {
              triggered = true;
            }

            if (triggered) {
              micStartIndex = j;
              micTimeShift = micXData[j];
              break;
            }
            prevY = currY;
          }
        }

        for (int i = micStartIndex; i < n; i += 4) {
          double audioValue = buffer[i] * 20;

          if (!isFourierTransformSelected) {
            entries.last.add(FlSpot(
                micXData[i] - micTimeShift - xOffsets['MIC']!,
                audioValue + yOffsets['MIC']!));
          } else {
            if (i < n / 2) {
              double y = fftOut[i].abs() / samples;
              if (y > mA) mA = y;

              double frequency = i / factor;
              entries.last.add(FlSpot(frequency, 0));
              entries.last.add(FlSpot(frequency, y));
              entries.last.add(FlSpot(frequency, 0));
            }
          }
          yDataString.last[i] = audioValue.toString();
        }
        if (mA > _maxAmp) _maxAmp = mA;
      }

      if (!isFourierTransformSelected) {
        for (int i = 0; i < min(entries.length, paramsChannels.length); i++) {
          String channel = paramsChannels[i];
          double minY = 0, maxY = 0;

          List<FlSpot> entriesList = entries[i];
          List<double> voltage = List.filled(512, 0.0);

          if (entriesList.isNotEmpty) {
            minY = double.maxFinite;
            maxY = -double.maxFinite;
            for (int j = 0; j < entriesList.length; j++) {
              FlSpot entry = entriesList[j];
              if (j < voltage.length) voltage[j] = entry.y;
              if (entry.y > maxY) maxY = entry.y;
              if (entry.y < minY) minY = entry.y;
            }
          }

          final double frequency;
          if (paramsChannels[i] == 'MIC') {
            frequency = _analyticsClass.findFrequency(
                voltage, (1 / AudioJack.samplingRate).toDouble());
          } else {
            frequency =
                _analyticsClass.findFrequency(voltage, timeGap / 1000000.0);
          }

          double period = (frequency > 0) ? (1 / frequency) * 1000.0 : 0;
          double yRange = maxY - minY;

          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.frequency] = frequency;
          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.period] = period;
          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.amplitude] = yRange;
          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.positivePeak] = maxY;
          OscilloscopeMeasurements
              .channel[channel]![ChannelMeasurements.negativePeak] = minY;
        }
      }

      for (int i = 0; i < min(entries.length, paramsChannels.length); i++) {
        final channelName = paramsChannels[i];
        _waveformBuffer
            .putIfAbsent(channelName, _createWaveformBuffer)
            .add(entries[i]);
      }
      dataEntriesCurveFit = List.from(curveFitEntries);
      dataParamsChannels = List.from(paramsChannels);

      if (_isRecording) {
        final now = DateTime.now();
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
        final recordedChannels = <String>[];
        final recordedWaveforms = <List<FlSpot>>[];
        for (final channelName in paramsChannels) {
          final waveform = _latestWaveform(channelName);
          if (waveform != null) {
            recordedChannels.add(channelName);
            recordedWaveforms.add(waveform);
          }
        }
        _recordedData.add(
          [
            now.millisecondsSinceEpoch.toString(),
            dateFormat.format(now),
            recordedWaveforms,
            recordedChannels,
            oscilloscopeAxesScale.xAxisScale,
            oscilloscopeAxesScale.yAxisScale,
            _configProvider.config.includeLocationData
                ? currentPosition?.latitude.toString() ?? 0
                : 0,
            _configProvider.config.includeLocationData
                ? currentPosition?.longitude.toString() ?? 0
                : 0
          ],
        );
      }

      if (isFourierTransformSelected) {
        oscilloscopeAxesScale.setYAxisScaleMax((_maxAmp > 0) ? _maxAmp : 1.0);
        oscilloscopeAxesScale.setYAxisScaleMin(0);
        oscilloscopeAxesScale.setXAxisScale(_maxFreq * 1000);
      }
      notifyListeners();
    } catch (e) {
      logger.e("ERROR IN CAPTURE TASK: $e");
    }
  }

  List<FlSpot> _parseSpotList(dynamic data) {
    if (data is Iterable) {
      return data
          .map((spot) {
            if (spot is FlSpot) return spot;
            if (spot is Iterable) {
              final coordinates = spot.toList();
              if (coordinates.length >= 2) {
                final x = double.tryParse(coordinates[0].toString());
                final y = double.tryParse(coordinates[1].toString());
                if (x != null && y != null) return FlSpot(x, y);
              }
            }
            return null;
          })
          .whereType<FlSpot>()
          .toList();
    }

    if (data is! String) return [];

    final coordinatePattern = RegExp(
      r'(?:FlSpot)?\(\s*(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s*,\s*(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)(?:\s*,\s*-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\s*,\s*-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)?\s*\)',
    );
    return coordinatePattern.allMatches(data).map((match) {
      return FlSpot(
        double.parse(match.group(1)!),
        double.parse(match.group(2)!),
      );
    }).toList();
  }

  List<List<FlSpot>> parseFlSpotList(dynamic data) {
    if (data is Map) {
      return data.values.map(_parseSpotList).toList();
    }
    if (data is Iterable && data is! String) {
      return data.map(_parseSpotList).toList();
    }
    if (data is! String) return [];

    return data.split(RegExp(r'\],\s*\[')).map(_parseSpotList).toList();
  }

  List<String> parseChannelsList(dynamic input) {
    if (input is Iterable && input is! String) {
      return input.map((channel) => channel.toString()).toList();
    }
    if (input is! String) return [];

    String clean = input.trim();
    if (clean.startsWith('[') && clean.endsWith(']')) {
      clean = clean.substring(1, clean.length - 1);
    }

    return clean.split(',').map((s) => s.trim()).toList();
  }

  void _startPlaybackTimer() {
    if (_playbackIndex >= _playbackData!.length) {
      _completePlayback();
      return;
    }

    final currentRow = _playbackData![_playbackIndex];
    if (currentRow.length > 2) {
      _renderPlaybackFrame(currentRow);
      if (currentRow.length > 4) {
        oscilloscopeAxesScale
            .setXAxisScale(double.tryParse(currentRow[4].toString()) ?? 875.0);
      }
      if (currentRow.length > 5) {
        oscilloscopeAxesScale
            .setYAxisScale(double.tryParse(currentRow[5].toString()) ?? 16.0);
      }
      _playbackIndex++;
      notifyListeners();
    } else {
      logger.e(
          'Skipping playback row at index $_playbackIndex due to insufficient columns');
      _playbackIndex++;
      notifyListeners();
    }

    Duration interval = const Duration(seconds: 1);

    if (_playbackIndex < _playbackData!.length && _playbackIndex > 1) {
      try {
        final currentTimestamp =
            int.tryParse(_playbackData![_playbackIndex - 1][0].toString());
        final nextTimestamp =
            int.tryParse(_playbackData![_playbackIndex][0].toString());

        if (currentTimestamp != null && nextTimestamp != null) {
          final timeDiff = nextTimestamp - currentTimestamp;
          interval = Duration(milliseconds: timeDiff);
          if (interval.inMilliseconds < 100) {
            interval = const Duration(milliseconds: 100);
          } else if (interval.inMilliseconds > 10000) {
            interval = const Duration(seconds: 10);
          }
        }
      } catch (e) {
        interval = const Duration(seconds: 1);
      }
    }

    _playbackTimer = Timer(interval, () {
      if (_isPlayingBack && !_isPlaybackPaused) {
        _startPlaybackTimer();
      }
    });
  }

  void _completePlayback() {
    _isPlaybackComplete = true;
    _isPlaybackPaused = true;
    _playbackTimer?.cancel();

    if (_wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    _isPlayingBack = false;
    _isPlaybackPaused = false;
    _isPlaybackComplete = false;
    _playbackTimer?.cancel();
    _playbackData = null;
    _playbackIndex = 0;

    if (_wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
    _clearWaveformBuffers();
    notifyListeners();
    onPlaybackEnd?.call();
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) return;

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _isPlaybackComplete = false;
    _playbackData = data;
    _playbackIndex = 1;

    if (!_wakelockEnabled) {
      WakelockPlus.enable();
      _wakelockEnabled = true;
    }
    _timer.cancel();

    _clearWaveformBuffers();
    _startPlaybackTimer();
    notifyListeners();
  }

  void pausePlayback() {
    if (_isPlayingBack) {
      _isPlaybackPaused = true;
      _playbackTimer?.cancel();
      if (_wakelockEnabled) {
        WakelockPlus.disable();
        _wakelockEnabled = false;
      }
      notifyListeners();
    }
  }

  void resumePlayback() {
    if (!_isPlayingBack) return;

    if (_isPlaybackComplete) {
      _isPlaybackComplete = false;
      _isPlaybackPaused = false;
      _playbackIndex = 1;
      _clearWaveformBuffers();
      if (!_wakelockEnabled) {
        WakelockPlus.enable();
        _wakelockEnabled = true;
      }
      _startPlaybackTimer();
      notifyListeners();
      return;
    }

    if (_isPlaybackPaused) {
      _isPlaybackPaused = false;
      if (!_wakelockEnabled) {
        WakelockPlus.enable();
        _wakelockEnabled = true;
      }
      _startPlaybackTimer();
      notifyListeners();
    }
  }

  void _renderFrameAt(int index) {
    if (_playbackData == null) return;
    if (index < 1 || index >= _playbackData!.length) return;
    final row = _playbackData![index];
    _renderPlaybackFrame(row);
    if (row.length > 3) {
      dataParamsChannels = parseChannelsList(row[3]);
    }
    if (row.length > 4) {
      oscilloscopeAxesScale
          .setXAxisScale(double.tryParse(row[4].toString()) ?? 875.0);
    }
    if (row.length > 5) {
      oscilloscopeAxesScale
          .setYAxisScale(double.tryParse(row[5].toString()) ?? 16.0);
    }
  }

  void _renderPlaybackFrame(List<dynamic> row) {
    if (row.length <= 2) return;

    final channels = row.length > 3 ? parseChannelsList(row[3]) : <String>[];
    final rawWaveforms = row[2];
    final List<List<FlSpot>> waveforms;
    if (rawWaveforms is Map) {
      waveforms = channels
          .map((channelName) => _parseSpotList(rawWaveforms[channelName]))
          .toList();
    } else if (rawWaveforms is String &&
        rawWaveforms.trimLeft().startsWith('{')) {
      waveforms = channels.map((channelName) {
        final escapedChannel = RegExp.escape(channelName);
        final match = RegExp(
          '$escapedChannel\\s*:\\s*\\[(.*?)\\]',
          dotAll: true,
        ).firstMatch(rawWaveforms);
        return _parseSpotList(match?.group(1));
      }).toList();
    } else {
      waveforms = parseFlSpotList(rawWaveforms);
    }

    _clearWaveformBuffers();
    dataParamsChannels = [];
    for (int i = 0; i < min(channels.length, waveforms.length); i++) {
      _waveformBuffer
          .putIfAbsent(channels[i], _createWaveformBuffer)
          .add(waveforms[i]);
      dataParamsChannels.add(channels[i]);
    }
  }

  void seekToFrame(int frame) {
    if (_playbackData == null || !_isPlayingBack) return;
    final maxIndex = _playbackData!.length - 1;
    if (maxIndex < 1) return;

    frame = frame.clamp(1, maxIndex);
    _playbackTimer?.cancel();
    _isPlaybackComplete = false;
    _renderFrameAt(frame);
    _playbackIndex = frame + 1;
    notifyListeners();

    if (!_isPlaybackPaused) {
      _playbackTimer = Timer(const Duration(milliseconds: 150), () {
        if (_isPlayingBack && !_isPlaybackPaused) {
          _startPlaybackTimer();
        }
      });
    }
  }

  Future<bool> startRecording() async {
    final HardwareBoard? board = _boardState.activeBoard;
    final bool hasOscilloscope =
        board?.isConnected == true && board?.oscilloscope != null;

    if (!hasOscilloscope && !isBuiltInMICSelected) {
      return false;
    }
    if (_configProvider.config.includeLocationData) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordingStartedAt = DateTime.now();
    _recordedData = [
      [
        'Timestamp',
        'DateTime',
        'Readings',
        'Channels',
        'XAxisScale',
        'YAxisScale',
        'Latitude',
        'Longitude'
      ]
    ];
    notifyListeners();
    return true;
  }

  List<List<dynamic>> stopRecording() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _isRecording = false;
    _lastRecordingMetadata = _buildRecordingMetadata();
    notifyListeners();
    return _recordedData;
  }

  OscilloscopeRecordingMetadata _buildRecordingMetadata() {
    final channelSet = <String>{};
    for (int i = 1; i < _recordedData.length; i++) {
      final row = _recordedData[i];
      if (row.length > 3 && row[3] is List) {
        for (final c in (row[3] as List)) {
          final name = c.toString().trim();
          if (name.isNotEmpty) channelSet.add(name);
        }
      }
    }
    const channelOrder = ['CH1', 'CH2', 'CH3', 'MIC'];
    final channels = <String>[
      for (final c in channelOrder)
        if (channelSet.contains(c)) c,
      for (final c in channelSet)
        if (!channelOrder.contains(c)) c,
    ];
    if (channels.isEmpty) {
      channels.addAll([
        if (isChannelSelected('CH1')) 'CH1',
        if (isChannelSelected('CH2')) 'CH2',
        if (isChannelSelected('CH3')) 'CH3',
        if (isChannelSelected('MIC') || _isBuiltInMICSelected) 'MIC',
      ]);
    }
    final frameCount = _recordedData.isNotEmpty ? _recordedData.length - 1 : 0;
    final yScale = oscilloscopeAxesScale.yAxisScale;
    final rangeText = yScale == yScale.roundToDouble()
        ? yScale.toStringAsFixed(0)
        : yScale.toString();
    return OscilloscopeRecordingMetadata(
      recordedAt: _recordingStartedAt,
      enabledChannels: channels,
      range: '±${rangeText}V',
      timebase: timebase,
      triggerEnabled: isTriggerSelected,
      triggerChannel: triggerChannel,
      triggerMode: triggerMode,
      triggerLevel: trigger,
      samplingRate: timeGap > 0 ? 1e6 / timeGap : null,
      samplesPerFrame: samples,
      sampleCount: frameCount,
    );
  }

  void setTimebaseDivisions(int divisions) {
    _timebaseDivisions = divisions;
    notifyListeners();
  }

  void setTimebase(double value) {
    switch (value) {
      case 0:
        timebase = 875.00;
        samples = 512;
        break;
      case 1:
        timebase = 1000.00;
        samples = 512;
        break;
      case 2:
        timebase = 2000.00;
        samples = 512;
        break;
      case 3:
        timebase = 4000.00;
        samples = 512;
        break;
      case 4:
        timebase = 8000.00;
        samples = 1024;
        break;
      case 5:
        timebase = 25600.00;
        samples = 1024;
        break;
      case 6:
        timebase = 38400.00;
        samples = 1024;
        break;
      case 7:
        timebase = 51200.00;
        samples = 1024;
        break;
      case 8:
        timebase = 102400.00;
        samples = 1024;
        break;
      default:
        timebase = 875.00;
        samples = 512;
        break;
    }
    final bool isLabrador =
        _boardState.activeBoard?.oscilloscope is LabradorOscilloscope;
    if (isLabrador) {
      timeGap = timebase / samples;
    } else {
      timeGap = (2 * timebase) / samples;
    }
    oscilloscopeAxesScale.setXAxisScale(timebase);
    notifyListeners();
  }

  void setYAxisScale(double value) {
    oscilloscopeAxesScale.setYAxisScale(value);
    notifyListeners();
  }

  bool autoScale() {
    double minY = double.maxFinite;
    double maxY = double.minPositive;
    double maxPeriod = -1 * double.minPositive;
    double yRange;
    double yPadding;
    List<double> voltage = List.filled(512, 0.0);
    for (var channelName in dataParamsChannels) {
      final entryList = _latestWaveform(channelName);
      if (entryList != null) {
        for (int j = 0; j < entryList.length; j++) {
          FlSpot entry = entryList[j];
          if (j < voltage.length - 1) {
            voltage[j] = entry.y;
          }
          if (entry.y > maxY) {
            maxY = entry.y;
          }
          if (entry.y < minY) {
            minY = entry.y;
          }
        }
        final double frequency;
        if (channelName == 'MIC') {
          frequency = _analyticsClass.findSignalFrequency(
              voltage, (1 / AudioJack.samplingRate).toDouble());
        } else {
          frequency =
              _analyticsClass.findSignalFrequency(voltage, timeGap / 1000000.0);
        }
        double period = (1 / frequency) * 1000.0;
        if (period > maxPeriod) {
          maxPeriod = period;
        }
      }
    }
    yRange = maxY - minY;
    yPadding = yRange * 0.1;
    if (maxPeriod > 0) {
      double xAxisScale = min((maxPeriod * 5), maxTimebase);
      double yAxisScale;
      if (maxY.abs() > minY.abs()) {
        yAxisScale = maxY + yPadding;
      } else {
        yAxisScale = -1 * (minY - yPadding);
      }
      samples = 512;
      timeGap = (2 * xAxisScale * 1000.0) / samples;
      timebase = xAxisScale * 1000.0;
      oscilloscopeAxesScale.setXAxisScale(timebase);
      oscilloscopeAxesScale.setYAxisScale(yAxisScale);
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  void setStackedMode(bool value) {
    isStackedMode = value;
    notifyListeners();
  }

  List<String> stackedChannelNames() {
    final names = <String>[];
    if (dataParamsChannels.isNotEmpty) {
      for (final name in dataParamsChannels) {
        if (!names.contains(name)) names.add(name);
      }
      return names;
    }
    if (isChannelSelected('CH1')) names.add('CH1');
    if (isChannelSelected('CH2')) names.add('CH2');
    if (isChannelSelected('CH3')) names.add('CH3');
    if (isChannelSelected('MIC') || _isBuiltInMICSelected) {
      names.add('MIC');
    }
    if (names.isEmpty) names.add('CH1');
    return names;
  }

  List<LineChartBarData> createPlotForChannel(String channelName) {
    return _createChannelPlots(
      channelName,
      includeHistory: isBufferOverlayEnabled(),
    );
  }

  List<LineChartBarData> _createChannelPlots(
    String channelName, {
    required bool includeHistory,
  }) {
    final plots = <LineChartBarData>[];
    final buffer = _waveformBuffer[channelName];
    final color = plotColors[channelName];
    if (buffer == null || buffer.isEmpty || color == null) return plots;

    final historyCount = includeHistory ? buffer.length - 1 : 0;
    for (int i = 0; i < buffer.length; i++) {
      final isCurrent = i == buffer.length - 1;
      if (!includeHistory && !isCurrent) continue;

      final opacity =
          isCurrent ? 1.0 : ((i + 1) / (historyCount + 1)).clamp(0.1, 0.6);
      plots.add(
        LineChartBarData(
          spots: buffer[i],
          isCurved: true,
          color: color.withValues(alpha: opacity),
          barWidth: 1,
          dotData: const FlDotData(show: false),
        ),
      );
    }
    return plots;
  }

  List<LineChartBarData> createPlots() {
    final plots = <LineChartBarData>[];
    for (final channelName in dataParamsChannels) {
      plots.addAll(_createChannelPlots(
        channelName,
        includeHistory: isBufferOverlayEnabled(),
      ));
    }

    plots.addAll(
      List<LineChartBarData>.generate(
        dataEntriesCurveFit.length,
        (index) {
          return LineChartBarData(
            spots: dataEntriesCurveFit[index],
            isCurved: true,
            color: curveFitColor,
            barWidth: 1,
            dotData: const FlDotData(
              show: false,
            ),
          );
        },
      ),
    );
    return plots;
  }

  List<LineChartBarData> createXYPlot() {
    return List<LineChartBarData>.generate(
      dataEntriesXYPlot.length,
      (index) {
        return LineChartBarData(
          spots: dataEntriesXYPlot[index],
          isCurved: true,
          color: xyPlotColor,
          barWidth: 1,
          dotData: const FlDotData(
            show: false,
          ),
        );
      },
    );
  }

  void resetGraph() {
    if (_waveformBuffer.values.every((buffer) => buffer.isEmpty) &&
        dataEntriesXYPlot.isEmpty &&
        dataEntriesCurveFit.isEmpty &&
        dataParamsChannels.isEmpty) {
      return;
    }
    oscilloscopeAxesScale.setYAxisScaleMax(oscilloscopeAxesScale.yAxisScale);
    oscilloscopeAxesScale.setYAxisScaleMin(-oscilloscopeAxesScale.yAxisScale);
    oscilloscopeAxesScale.setXAxisScale(timebase);
    _clearWaveformBuffers();
    dataEntriesXYPlot = [];
    dataEntriesCurveFit = [];
    dataParamsChannels = [];
    notifyListeners();
  }

  void setFourierTransform(bool enabled) {
    if (enabled == isFourierTransformSelected) {
      return;
    }

    _clearWaveformBuffers();

    isFourierTransformSelected = enabled;

    if (!enabled) {
      oscilloscopeAxesScale.setYAxisScaleMax(oscilloscopeAxesScale.yAxisScale);
      oscilloscopeAxesScale.setYAxisScaleMin(-oscilloscopeAxesScale.yAxisScale);
      oscilloscopeAxesScale.setXAxisScale(timebase);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _monitor = false;
    if (_timer.isActive) {
      _timer.cancel();
    }
    _playbackTimer?.cancel();
    if (_wakelockEnabled) {
      WakelockPlus.disable();
    }
    _audioJack.disposeHardware();
    super.dispose();
  }
}
