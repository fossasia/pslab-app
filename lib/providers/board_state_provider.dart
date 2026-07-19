import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/settings_config_provider.dart';
import 'package:pslab/others/science_lab_common.dart';

import 'package:pslab/src/rust/api/simple.dart' as rust_api;

class BoardStateProvider extends ChangeNotifier {
  late SettingsConfigProvider configProvider;
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  bool initialisationStatus = false;
  bool pslabIsConnected = false;
  bool hasPermission = false;
  late ScienceLabCommon scienceLabCommon;
  String pslabVersionID = 'Not Connected';
  String pslabVersionIDV6 = 'PSLab V6';
  String pslabVersionIDV5 = 'PSLab V5';
  int pslabVersion = 0;
  int pslabFirmwareVersion = 0;
  bool _isProcessing = false;

  final ValueNotifier<String?> legacyFirmwareNotifier = ValueNotifier(null);

  static const EventChannel _androidUsbEventChannel =
      EventChannel('io.pslab/usb_events');
  Timer? _desktopHotplugTimer;

  BoardStateProvider() {
    scienceLabCommon = getIt.get<ScienceLabCommon>();
    configProvider = SettingsConfigProvider();
  }

  Future<void> initialize() async {
    if (_isProcessing) return;
    _isProcessing = true;
    if (!scienceLabCommon.isConnected()) {
      await scienceLabCommon.initialize();
      pslabIsConnected = await scienceLabCommon.openDevice();
      await setPSLabVersionIDs();
      await fetchFirmwareVersion();
    }
    _isProcessing = false;

    if (configProvider.config.autoStart && !kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _androidUsbEventChannel
            .receiveBroadcastStream()
            .listen(_handleUsbEvent);
      } else if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        _startDesktopMonitor();
      }
    }

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        scienceLabCommon.setWiFiConnected(false);
        pslabIsConnected = false;
        pslabVersionID = 'Not Connected';
        notifyListeners();
      }
    });
  }

  void _startDesktopMonitor() {
    bool wasConnected = false;
    _desktopHotplugTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool isConnected = rust_api.checkDesktopDevicePresent();

      if (isConnected && !wasConnected) {
        _handleUsbEvent("ATTACHED");
      } else if (!isConnected && wasConnected) {
        _handleUsbEvent("DETACHED");
      }
      wasConnected = isConnected;
    });
  }

  Future<void> _handleUsbEvent(dynamic event) async {
    final String eventStr = event.toString();

    final bool isAttached = eventStr == "ATTACHED" ||
        eventStr == "android.hardware.usb.action.USB_DEVICE_ATTACHED";
    final bool isDetached = eventStr == "DETACHED" ||
        eventStr == "android.hardware.usb.action.USB_DEVICE_DETACHED";

    if (isAttached) {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        if (!scienceLabCommon.isConnected() && await attemptToConnectPSLab()) {
          pslabIsConnected = await scienceLabCommon.openDevice();
          await setPSLabVersionIDs();
          await fetchFirmwareVersion();
        }
      } catch (e) {
        logger.e("Error auto-connecting on USB Attach: $e");
      } finally {
        _isProcessing = false;
        notifyListeners();
      }
    } else if (isDetached && !scienceLabCommon.isWiFiConnected()) {
      scienceLabCommon.setConnected(false);
      pslabIsConnected = false;
      pslabVersionID = 'Not Connected';
      notifyListeners();
    }
  }

  Future<void> initializeWiFi() async {
    if (!pslabIsConnected) {
      pslabIsConnected = await scienceLabCommon.openWiFiDevice();
      await setPSLabVersionIDs();
      await fetchFirmwareVersion();
    }
  }

  Future<void> setPSLabVersionIDs() async {
    pslabVersionID = await getIt.get<ScienceLab>().getVersion();
    if (pslabVersionID == pslabVersionIDV6) {
      pslabVersion = 6;
    } else if (pslabVersionID == pslabVersionIDV5) {
      pslabVersion = 5;
    }
    notifyListeners();
  }

  Future<void> fetchFirmwareVersion() async {
    if (getIt.get<ScienceLab>().isConnected()) {
      pslabFirmwareVersion =
          await getIt.get<ScienceLab>().mPacketHandler.getFirmwareVersion();
    }
    if (pslabFirmwareVersion < 3 && pslabFirmwareVersion != 0) {
      legacyFirmwareNotifier.value = "LegacyFirmwareDetected";
    }
    notifyListeners();
  }

  Future<bool> attemptToConnectPSLab() async {
    if (scienceLabCommon.isConnected()) {
      logger.d("Device Connected Successfully");
      return true;
    } else {
      await scienceLabCommon.initialize();
      if (scienceLabCommon.isDeviceFound()) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _desktopHotplugTimer?.cancel();
    super.dispose();
  }
}
