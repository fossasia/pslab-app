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
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/oscilloscope_config_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../communication/analytics_class.dart';
import '../communication/science_lab.dart';
import '../others/audio_jack.dart';

enum MODE { rising, falling, dual }

enum ChannelMeasurements {
  frequency,
  period,
  amplitude,
  positivePeak,
  negativePeak
}

List<Color> colors = [
  Colors.cyan,
  Colors.green,
  Colors.white,
  Colors.purpleAccent
];

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

  late int samples;
  late double timeGap;
  late double timebase;
  double maxTimebase = 102.4;
  late bool isCH1Selected;
  late bool isCH2Selected;
  late bool isCH3Selected;
  late bool isMICSelected;
  late bool isInBuiltMICSelected;
  late bool isAudioInputSelected;
  late bool isTriggerSelected;
  late bool isTriggered;
  late bool isFourierTransformSelected;
  late bool isXYPlotSelected;
  late bool sineFit;
  late bool squareFit;
  late String triggerChannel;
  late String triggerMode;
  late String curveFittingChannel1;
  late String curveFittingChannel2;
  late Map<String, double> xOffsets;
  late Map<String, double> yOffsets;
  late double trigger;
  late ScienceLab _scienceLab;
  late AnalyticsClass _analyticsClass;
  late bool _monitor;
  late double _maxAmp;
  late double _maxFreq;
  late bool isRunning;
  bool _isPlayingBack = false;
  bool get isPlayingBack => _isPlayingBack;
  bool _isPlaybackPaused = false;
  bool get isPlaybackPaused => _isPlaybackPaused;
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
  late List<List<FlSpot>> dataEntries;
  late List<List<FlSpot>> dataEntriesXYPlot;
  late List<List<FlSpot>> dataEntriesCurveFit;
  late List<String> dataParamsChannels;
  List<List<dynamic>> _recordedData = [];
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

    isCH1Selected = false;
    isCH2Selected = false;
    isCH3Selected = false;
    isMICSelected = false;
    isInBuiltMICSelected = false;
    isAudioInputSelected = false;
    isTriggerSelected = false;
    isTriggered = false;
    isFourierTransformSelected = false;
    isXYPlotSelected = false;
    _monitor = true;
    _isRecording = false;
    isRunning = true;
    xyPlotAxis1 = 'CH1';
    xyPlotAxis2 = 'CH2';
    dataEntries = [];
    dataEntriesXYPlot = [];
    dataEntriesCurveFit = [];
    _timebaseDivisions = 8;
    timebaseSlider = 0;
    oscillscopeRangeSelection = 0;
    _isProcessing = false;

    dataEntries = <List<FlSpot>>[];
    dataEntriesXYPlot = <List<FlSpot>>[];
    dataEntriesCurveFit = <List<FlSpot>>[];
    dataParamsChannels = <String>[];

    _channelIndexMap = <String, int>{};
    _channelIndexMap['CH1'] = 1;
    _channelIndexMap['CH2'] = 2;
    _channelIndexMap['CH3'] = 3;
    _channelIndexMap['MIC'] = 4;

    _scienceLab = getIt.get<ScienceLab>();
    triggerChannel = 'CH1';
    triggerMode = MODE.rising.toString();
    trigger = 0;
    timebase = 875;
    samples = 512;
    timeGap = 2;

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

  void setConfigProvider(
      OscilloscopeConfigProvider oscilloscopeConfigProvider) {
    _configProvider = oscilloscopeConfigProvider;
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
          if (isInBuiltMICSelected && !_audioJack.isListening()) {
            await _audioJack.initialize();
            await _audioJack.start();
          }

          List<String> channels = [];

          if (_scienceLab.isConnected() && isXYPlotSelected) {
            await xyPlotTask(xyPlotAxis1, xyPlotAxis2);
            if (!_wakelockEnabled) {
              WakelockPlus.enable();
              _wakelockEnabled = true;
            }
          } else {
            if (_scienceLab.isConnected()) {
              if (isCH1Selected) {
                channels.add('CH1');
              }
              if (isCH2Selected) {
                channels.add('CH2');
              }
              if (isCH3Selected) {
                channels.add('CH3');
              }
            }
            if (isAudioInputSelected && isInBuiltMICSelected ||
                (_scienceLab.isConnected() && isMICSelected)) {
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
              dataEntries = [];
            }
          }
          if (!isInBuiltMICSelected && _audioJack.isListening()) {
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

    Map<String, List<double>> data;
    entries.add([]);
    if (analogInput1 == analogInput2) {
      await _scienceLab.captureTraces(
          1, samples, timeGap, analogInput1, isTriggerSelected, null);
      data = await _scienceLab.fetchTrace(1);
      List<double>? yData = data['y'];
      int n = yData!.length;
      for (int i = 0; i < n; i++) {
        entries[0].add(FlSpot(yData[i], yData[i]));
      }
    } else {
      int noOfChannels = 1;
      if ((analogInput1 == 'CH1' && analogInput2 == 'CH2') ||
          (analogInput1 == 'CH2' && analogInput2 == 'CH1')) {
        noOfChannels = 2;
        await _scienceLab.captureTraces(
            noOfChannels, 175, timeGap, 'CH1', isTriggerSelected, null);
        data = await _scienceLab.fetchTrace(1);
        List<double>? yData1 = data['y'];
        data = await _scienceLab.fetchTrace(2);
        List<double>? yData2 = data['y'];
        int n = min(yData1!.length, yData2!.length);
        for (int i = 0; i < n; i++) {
          entries[0].add(FlSpot(yData1[i], yData2[i]));
        }
      } else {
        noOfChannels = 4;
        await _scienceLab.captureTraces(
            noOfChannels, 175, timeGap, 'CH1', isTriggerSelected, null);
        data = await _scienceLab.fetchTrace(_channelIndexMap[analogInput1]!);
        List<double>? yData1 = data['y'];
        data = await _scienceLab.fetchTrace(_channelIndexMap[analogInput2]!);
        List<double>? yData2 = data['y'];
        int n = min(yData1!.length, yData2!.length);
        for (int i = 0; i < n; i++) {
          entries[0].add(FlSpot(yData1[i], yData2[i]));
        }
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

    if (isInBuiltMICSelected) {
      noOfChannels--;
    }

    try {
      List<List<String>> yDataString = [];
      List<String> xDataString = [];
      _maxAmp = 0;

      if (noOfChannels > 0) {
        await _scienceLab.captureTraces(
            4, samples, timeGap, channel, false, null);
      }

      await Future.delayed(
          Duration(milliseconds: (samples * timeGap * 1e-3).toInt()));

      List<Map<String, List<double>>> allChannelData = [];

      double? masterTriggerTime;

      for (int i = 0; i < noOfChannels; i++) {
        channel = channels[i];
        Map<String, List<double>> data =
            await _scienceLab.fetchTrace(_channelIndexMap[channel]!);

        List<double> xRaw = data['x']!;
        for (int k = 0; k < xRaw.length; k++) {
          xRaw[k] = xRaw[k] / ((timebase == 875) ? 1 : 1000);
        }

        allChannelData.add(data);

        if (isTriggerSelected &&
            triggerChannel == channel &&
            !isFourierTransformSelected) {
          List<double> yRaw = data['y']!;

          double prevY = yRaw[0];
          bool increasing = false;

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
                    (prevY > trigger && currY <= trigger && !increasing))) {
              triggered = true;
            }

            if (triggered) {
              masterTriggerTime = xRaw[j];
              break;
            }
            prevY = currY;
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

        xDataString = List.filled(n, '');
        yDataString.add(List.filled(n, ''));

        List<Complex> fftOut = [];
        if (isFourierTransformSelected) {
          List<Complex> yComplex = List.filled(yData.length, const Complex(0));
          for (int j = 0; j < yData.length; j++) {
            yComplex[j] = Complex(yData[j]);
          }
          fftOut = fft(yComplex);
        }

        double factor = samples * timeGap * 1e-3;
        _maxFreq = (n / 2 - 1) / factor;
        double mA = 0;

        int startIndex = 0;

        if (!isFourierTransformSelected &&
            isTriggerSelected &&
            masterTriggerTime != null) {
          int foundIndex = xData.indexWhere((t) => t >= masterTriggerTime!);
          if (foundIndex != -1) {
            startIndex = foundIndex;
          }
        }

        for (int j = startIndex; j < n; j++) {
          double timeShift = (isTriggerSelected && masterTriggerTime != null)
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

      if (isInBuiltMICSelected) {
        noOfChannels++;
        isTriggered = false;
        entries.add([]);
        List<double> buffer = _audioJack.read();
        xDataString = List.filled(buffer.length, '');
        yDataString.add(List.filled(buffer.length, ''));
        int n = buffer.length;

        List<double> micXData = List.generate(n, (i) {
          double t = ((i / AudioJack.samplingRate) * 1000000.0);
          return t / ((timebase == 875) ? 1 : 1000);
        });

        List<Complex> fftOut = [];
        if (isFourierTransformSelected) {
          List<Complex> yComplex = List.filled(buffer.length, const Complex(0));
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

        for (int i = micStartIndex; i < n; i++) {
          double audioValue = buffer[i] * 3;

          if (!isFourierTransformSelected) {
            entries.last.add(FlSpot(
                micXData[i] - micTimeShift - xOffsets['MIC']!,
                audioValue + yOffsets['MIC']!));
          } else {
            if (i < n / 2) {
              double y = fftOut[i].abs() / samples;
              if (y > mA) mA = y;
              entries.last.add(FlSpot((i / factor), y));
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

      dataEntries = List.from(entries);
      dataEntriesCurveFit = List.from(curveFitEntries);
      dataParamsChannels = List.from(paramsChannels);

      if (_isRecording) {
        final now = DateTime.now();
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
        _recordedData.add(
          [
            now.millisecondsSinceEpoch.toString(),
            dateFormat.format(now),
            dataEntries,
            dataParamsChannels,
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
        oscilloscopeAxesScale.setYAxisScaleMax(_maxAmp);
        oscilloscopeAxesScale.setYAxisScaleMin(0);
        oscilloscopeAxesScale.setXAxisScale(_maxFreq * 1000);
      }

      notifyListeners();
    } catch (e) {
      logger.e(e);
    }
  }

  List<List<FlSpot>> parseFlSpotList(String data) {
    String clean = data.trim();
    if (clean.startsWith('[[') && clean.endsWith(']]')) {
      clean = clean.substring(2, clean.length - 2);
    }

    List<String> groups = clean.split('], [');

    return groups.map((group) {
      List<String> tuples = group.split('), (');
      return tuples.map((tuple) {
        String cleaned = tuple.replaceAll('(', '').replaceAll(')', '');
        List<String> parts = cleaned.split(',');
        if (parts.length <= 2) {
          return FlSpot(0.0, 0.0);
        }
        double x = double.tryParse(parts[0].trim()) ?? 0.0;
        double y = double.tryParse(parts[1].trim()) ?? 0.0;

        return FlSpot(x, y);
      }).toList();
    }).toList();
  }

  List<String> parseChannelsList(String input) {
    String clean = input.trim();
    if (clean.startsWith('[') && clean.endsWith(']')) {
      clean = clean.substring(1, clean.length - 1);
    }

    return clean.split(',').map((s) => s.trim()).toList();
  }

  void _startPlaybackTimer() {
    if (_playbackIndex >= _playbackData!.length) {
      stopPlayback();
      return;
    }

    final currentRow = _playbackData![_playbackIndex];
    if (currentRow.length > 2) {
      dataEntries = parseFlSpotList(currentRow[2]);
      dataParamsChannels = parseChannelsList(currentRow[3]);
      oscilloscopeAxesScale
          .setXAxisScale(double.tryParse(currentRow[4].toString()) ?? 875.0);
      oscilloscopeAxesScale
          .setYAxisScale(double.tryParse(currentRow[5].toString()) ?? 16.0);
      _playbackIndex++;
      notifyListeners();
    } else {
      logger.e(
          'Skipping playback row at index $_playbackIndex due to insufficient columns (found ${currentRow.length}, expected at least 3');
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

  Future<void> stopPlayback() async {
    _isPlayingBack = false;
    _isPlaybackPaused = false;
    _playbackTimer?.cancel();
    _playbackData = null;
    _playbackIndex = 0;

    if (_wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
    dataEntries.clear();
    notifyListeners();
    onPlaybackEnd?.call();
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) return;

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;

    if (!_wakelockEnabled) {
      WakelockPlus.enable();
      _wakelockEnabled = true;
    }
    _timer.cancel();

    dataEntries.clear();
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
    if (_isPlayingBack && _isPlaybackPaused) {
      _isPlaybackPaused = false;
      if (!_wakelockEnabled) {
        WakelockPlus.enable();
        _wakelockEnabled = true;
      }
      _startPlaybackTimer();
      notifyListeners();
    }
  }

  Future<bool> startRecording() async {
    if (!_scienceLab.isConnected()) {
      return false;
    }
    if (_configProvider.config.includeLocationData) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
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
    notifyListeners();
    return _recordedData;
  }

  void setTimebaseDivisions(int divisions) {
    _timebaseDivisions = divisions;
    notifyListeners();
  }

  void setTimebase(double value) {
    switch (value) {
      case 0:
        timebase = 875.00;
        break;
      case 1:
        timebase = 1000.00;
        break;
      case 2:
        timebase = 2000.00;
        break;
      case 3:
        timebase = 4000.00;
        break;
      case 4:
        timebase = 8000.00;
        break;
      case 5:
        timebase = 25600.00;
        break;
      case 6:
        timebase = 38400.00;
        break;
      case 7:
        timebase = 51200.00;
        break;
      case 8:
        timebase = 102400.00;
        break;
      default:
        timebase = 875.00;
        break;
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
    for (int i = 0; i < dataParamsChannels.length; i++) {
      if (dataEntries.length > i) {
        List<FlSpot> entryList = dataEntries[i];
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
        if (dataParamsChannels[i] == 'MIC') {
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

  List<LineChartBarData> createPlots() {
    List<Color> curveFitColors = [Colors.yellow];
    List<LineChartBarData> plots = [];
    plots.addAll(
      List<LineChartBarData>.generate(
        dataEntries.length,
        (index) {
          return LineChartBarData(
            spots: dataEntries[index],
            isCurved: true,
            color: colors[index % colors.length],
            barWidth: 1,
            dotData: const FlDotData(
              show: false,
            ),
          );
        },
      ),
    );
    plots.addAll(
      List<LineChartBarData>.generate(
        dataEntriesCurveFit.length,
        (index) {
          return LineChartBarData(
            spots: dataEntriesCurveFit[index],
            isCurved: true,
            color: curveFitColors[index % colors.length],
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
    List<Color> colors = [Colors.red];
    return List<LineChartBarData>.generate(
      dataEntriesXYPlot.length,
      (index) {
        return LineChartBarData(
          spots: dataEntriesXYPlot[index],
          isCurved: true,
          color: colors[index % colors.length],
          barWidth: 1,
          dotData: const FlDotData(
            show: false,
          ),
        );
      },
    );
  }

  void resetGraph() {
    if (dataEntries.isEmpty &&
        dataEntriesXYPlot.isEmpty &&
        dataEntriesCurveFit.isEmpty) {
      return;
    }
    oscilloscopeAxesScale.setYAxisScaleMax(oscilloscopeAxesScale.yAxisScale);
    oscilloscopeAxesScale.setYAxisScaleMin(-oscilloscopeAxesScale.yAxisScale);
    oscilloscopeAxesScale.setXAxisScale(timebase);
    dataEntries = [];
    dataEntriesXYPlot = [];
    dataEntriesCurveFit = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _monitor = false;
    if (_timer.isActive) {
      _timer.cancel();
    }
    if (_wakelockEnabled) {
      WakelockPlus.disable();
    }
    _audioJack.close();
    super.dispose();
  }
}
