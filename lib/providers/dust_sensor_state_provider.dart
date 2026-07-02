import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../communication/science_lab.dart';
import '../l10n/app_localizations.dart';
import '../others/logger_service.dart';
import 'dust_sensor_config_provider.dart';
import 'locator.dart';

class DustSensorStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  double _currentPM25 = 0.0;
  double _currentPM10 = 0.0;

  final List<int> _uartBuffer = [];

  Timer? _timeTimer;
  Timer? _dustTimer;

  final List<double> _pm25Data = [];
  final List<double> _pm10Data = [];
  final List<double> _timeData = [];

  final List<FlSpot> pm25ChartData = [];
  final List<FlSpot> pm10ChartData = [];

  double _startTime = 0;
  double _currentTime = 0;
  final int _chartMaxLength = 50;

  double _pm25Min = 0;
  double _pm25Max = 0;
  double _pm25Sum = 0;
  int _dataCount = 0;

  bool _isRecording = false;
  List<List<dynamic>> _recordedData = [];
  bool _isPlayingBack = false;
  List<List<dynamic>>? _playbackData;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  bool _isPlaybackPaused = false;

  bool get isRecording => _isRecording;
  bool get isPlayingBack => _isPlayingBack;
  bool get isPlaybackPaused => _isPlaybackPaused;

  DustSensorConfigProvider? _configProvider;

  Function(String)? onSensorError;
  Function? onPlaybackEnd;

  Position? currentPosition;
  StreamSubscription? _locationStream;

  void setConfigProvider(DustSensorConfigProvider configProvider) {
    _configProvider = configProvider;
  }

  DustSensorConfigProvider? get configProvider => _configProvider;

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

  Future<void> testSingleUARTRead() async {
    ScienceLab scienceLab = getIt.get<ScienceLab>();

    logger.i("--- STARTING SINGLE UART TEST ---");

    if (!scienceLab.isConnected()) {
      logger.e("TEST: ScienceLab is not connected!");
      return;
    }

    try {
      // 1. Wait 2 seconds. The SDS011 sends data once every 1 second.
      // This guarantees that at least one packet should be waiting in the PSLab buffer.
      logger.i("TEST: Waiting 2 seconds to let SDS011 send data...");
      await Future.delayed(const Duration(seconds: 2));

      // 2. Check available bytes
      logger.i("TEST: Requesting available byte count...");
      int available = await scienceLab.getUART2BytesAvailable();
      logger.i("TEST: PSLab reports $available bytes available.");

      // 3. Read if available
      if (available > 0) {
        List<int> rxBytes = await scienceLab.readUARTBytes(available);
        logger.i("TEST: Successfully read $available bytes.");

        // Convert to HEX string for easy reading in the console
        String hexString = rxBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
        logger.i("TEST: RAW DATA (HEX): $hexString");

        if (rxBytes.contains(0xAA)) {
          logger.i("TEST: SUCCESS! Found SDS011 Start Byte (0xAA) in the stream.");
        } else {
          logger.w("TEST: Data received, but no 0xAA start byte. Is baud rate correct? Are RX/TX swapped?");
        }
      } else {
        logger.w("TEST: No data available. The sensor might be asleep, or TX/RX are disconnected.");
      }
    } catch (e) {
      logger.e("TEST: Exception during single read: $e");
    }

    logger.i("--- END SINGLE UART TEST ---");
  }



  void initializeSensors({Function(String)? onError}) async {
    onSensorError = onError;

    try {
      ScienceLab scienceLab = getIt.get<ScienceLab>();

      // 1. Configure the UART port on the PSLab to 9600 baud
      await scienceLab.configureUART(baudRate: 9600);
      await Future.delayed(const Duration(milliseconds: 500));

      // Give the sensor a second to spin up the fan and stabilize [cite: 314]
      await Future.delayed(const Duration(seconds: 1));
      // ---------------------------------------------------------

      _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

      // 2. Start Time Tracking Timer
      _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPlayingBack) {
          _currentTime =
              (DateTime.now().millisecondsSinceEpoch / 1000.0) - _startTime;
          _updateData();
          notifyListeners();
        }
      });

      // 3. Start UART Polling Timer (Runs every 1 second)
      _dustTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!scienceLab.isConnected()) return;

        int available = await scienceLab.getUART2BytesAvailable();

        if (available > 0) {
          List<int> rxBytes = await scienceLab.readUARTBytes(available);
          String hexData = rxBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
          logger.i("📥 RECEIVED DATA: $hexData");
          _uartBuffer.addAll(rxBytes);
        }

        // 4. Process the continuous buffer
        while (_uartBuffer.length >= 10) {
          int headerIdx = _uartBuffer.indexOf(0xAA);

          if (headerIdx == -1) {
            _uartBuffer.clear();
            break;
          }

          if (headerIdx > 0) {
            _uartBuffer.removeRange(0, headerIdx);
          }

          if (_uartBuffer.length >= 10) {
            if (_uartBuffer[9] != 0xAB) {
              _uartBuffer.removeAt(0);
              continue;
            }

            final frame = _uartBuffer.sublist(0, 10);
            _uartBuffer.removeRange(0, 10);

            if (frame[1] != 0xC0) continue;

            int checksum = 0;
            for (int i = 2; i <= 7; i++) {
              checksum += frame[i];
            }

            if ((checksum & 0xFF) == frame[8]) {
              _currentPM25 = ((frame[3] * 256) + frame[2]) / 10.0;
              _currentPM10 = ((frame[5] * 256) + frame[4]) / 10.0;

              logger.d("SDS011 Valid Reading -> PM2.5: $_currentPM25, PM10: $_currentPM10");
              notifyListeners();
            } else {
              logger.w("SDS011: Checksum error on received frame.");
            }
          }
        }
      });
    } catch (e) {
      logger.e("Dust sensor initialization error: $e");
      _handleSensorError(e);
    }
  }

  void _handleSensorError(dynamic error) {
    onSensorError?.call("Unable to access SDS011 sensor via UART");
    logger.e("Dust sensor error: $error");
  }

  void disposeSensors() async {
    _timeTimer?.cancel();
    _dustTimer?.cancel();
  }

  void startPlayback(List<List<dynamic>> data) {
    if (data.length <= 1) return;

    _isPlayingBack = true;
    _isPlaybackPaused = false;
    _playbackData = data;
    _playbackIndex = 1;

    _timeTimer?.cancel();
    _dustTimer?.cancel();

    _pm25Data.clear();
    _pm10Data.clear();
    pm25ChartData.clear();
    pm10ChartData.clear();
    _timeData.clear();
    _startTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _currentTime = 0;
    _pm25Sum = 0;
    _dataCount = 0;

    _startPlaybackTimer();
    notifyListeners();
  }

  void _startPlaybackTimer() {
    if (_playbackIndex >= _playbackData!.length) {
      stopPlayback();
      return;
    }

    final currentRow = _playbackData![_playbackIndex];
    if (currentRow.length > 3) {
      _currentPM25 = double.tryParse(currentRow[2].toString()) ?? 0.0;
      _currentPM10 = double.tryParse(currentRow[3].toString()) ?? 0.0;
      _currentTime = (_playbackIndex - 1).toDouble();
      _updateData();
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

    _pm25Data.clear();
    _pm10Data.clear();
    pm25ChartData.clear();
    pm10ChartData.clear();
    _timeData.clear();
    _pm25Sum = 0;
    _dataCount = 0;
    _currentPM25 = 0.0;
    _currentPM10 = 0.0;
    _currentTime = 0;
    notifyListeners();
    onPlaybackEnd?.call();
  }

  void pausePlayback() {
    if (_isPlayingBack) {
      _isPlaybackPaused = true;
      _playbackTimer?.cancel();
      notifyListeners();
    }
  }

  void resumePlayback() {
    if (_isPlayingBack && _isPlaybackPaused) {
      _isPlaybackPaused = false;
      _startPlaybackTimer();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _playbackTimer?.cancel();
    disposeSensors();
    super.dispose();
  }

  void _updateData() {
    final pm25 = _currentPM25;
    final pm10 = _currentPM10;
    final time = _currentTime;
    if (_isRecording) {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      _recordedData.add([
        now.millisecondsSinceEpoch.toString(),
        dateFormat.format(now),
        pm25.toStringAsFixed(2),
        pm10.toStringAsFixed(2),
        _configProvider!.config.includeLocationData
            ? currentPosition?.latitude.toString() ?? 0
            : 0,
        _configProvider!.config.includeLocationData
            ? currentPosition?.longitude.toString() ?? 0
            : 0
      ]);
    }

    _pm25Data.add(pm25);
    _pm10Data.add(pm10);
    _timeData.add(time);
    _pm25Sum += pm25;
    _dataCount++;

    if (_pm25Data.length > _chartMaxLength) {
      final removedPM25 = _pm25Data.removeAt(0);
      _pm10Data.removeAt(0);
      _timeData.removeAt(0);
      _pm25Sum -= removedPM25;
      _dataCount--;
    }

    if (_pm25Data.isNotEmpty) {
      _pm25Min = _pm25Data.reduce(min);
      _pm25Max = _pm25Data.reduce(max);
    }

    pm25ChartData.clear();
    pm10ChartData.clear();

    for (int i = 0; i < _pm25Data.length; i++) {
      pm25ChartData.add(FlSpot(_timeData[i], _pm25Data[i]));
      pm10ChartData.add(FlSpot(_timeData[i], _pm10Data[i]));
    }
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (_configProvider!.config.includeLocationData) {
      await _startGeoLocationUpdates();
    }
    _isRecording = true;
    _recordedData = [
      ['Timestamp', 'DateTime', 'PM2.5', 'PM10', 'Latitude', 'Longitude']
    ];
    notifyListeners();
  }

  List<List<dynamic>> stopRecording() {
    if (_locationStream != null) {
      _locationStream!.cancel();
    }
    _isRecording = false;
    notifyListeners();
    return _recordedData;
  }

  double getCurrentDust() => _currentPM25;
  double getCurrentPM10() => _currentPM10;
  double getMinDust() => _pm25Min;
  double getMaxDust() => _pm25Max;
  double getAverageDust() => _dataCount > 0 ? _pm25Sum / _dataCount : 0.0;

  String getAirQuality() {
    if (_currentPM25 < 15.0) return appLocalizations.good;
    if (_currentPM25 < 35.0) return appLocalizations.moderate;
    if (_currentPM25 < 55.0) return appLocalizations.unhealthy;
    return appLocalizations.hazardous;
  }

  List<FlSpot> getDustChartData() => pm25ChartData;
  List<FlSpot> getPM10ChartData() => pm10ChartData;
  int getDataLength() => pm25ChartData.length;
  double getCurrentTime() => _currentTime;
  double getMaxTime() => _timeData.isNotEmpty ? _timeData.last : 0;
  double getMinTime() => _timeData.isNotEmpty ? _timeData.first : 0;
  double getTimeInterval() {
    if (_currentTime <= 10) return 2;
    if (_currentTime <= 30) return 5;
    return 10;
  }
}
