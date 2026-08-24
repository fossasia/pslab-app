import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/settings_config_provider.dart';
import 'package:pslab/others/science_lab_common.dart';
import 'package:pslab/communication/handler/wifi_comms_handler.dart';
import 'package:pslab/communication/handler/comms_handler.dart';

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

  String wifiHost = '192.168.4.1';

  final ValueNotifier<String?> legacyFirmwareNotifier = ValueNotifier(null);

  static const EventChannel _androidUsbEventChannel =
      EventChannel('io.pslab/usb_events');
  Timer? _desktopHotplugTimer;

  BoardStateProvider() {
    scienceLabCommon = getIt.get<ScienceLabCommon>();
    configProvider = SettingsConfigProvider();
  }

  void setWifiHost(String host) {
    wifiHost = host;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isProcessing) return;
    _isProcessing = true;

    if (!scienceLabCommon.isConnected()) {
      await scienceLabCommon.initialize();

      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        bool success = await _connectToDesktopDynamic();
        if (!success) {
          logger.w("PSLab not found on any available COM port.");
        }
      } else {
        bool portOpened = await scienceLabCommon.openDevice();
        if (portOpened) {
          await _validateHandshake();
        }
      }
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
        _resetConnectionState();
      }
    });
  }

  Future<bool> _connectToDesktopDynamic() async {
    if (ScienceLabCommon.communicationHandler is! PSLabCommunicationHandler)
      return false;

    final comms =
        ScienceLabCommon.communicationHandler as PSLabCommunicationHandler;
    List<String> ports = rust_api.getAvailablePorts();

    for (String port in ports) {
      try {
        logger.d("Testing port $port for PSLab handshake...");
        comms.targetPortName = port;
        bool portOpened = await scienceLabCommon.openDevice();

        if (portOpened) {
          await setPSLabVersionIDs();

          if (pslabVersionID == pslabVersionIDV6 ||
              pslabVersionID == pslabVersionIDV5) {
            logger.i("Found PSLab on $port!");
            pslabIsConnected = true;
            await fetchFirmwareVersion();
            notifyListeners();
            return true;
          } else {
            logger.w(
                "Device on $port failed handshake. Closing and moving to next port...");
            comms.close();
            _resetConnectionState();
          }
        }
      } catch (e) {
        logger.w("Exception while testing $port: $e");
        comms.close();
        _resetConnectionState();
      }
    }

    comms.targetPortName = null;
    return false;
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
          if (!kIsWeb &&
              (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
            await _connectToDesktopDynamic();
          } else {
            bool portOpened = await scienceLabCommon.openDevice();
            if (portOpened) {
              await _validateHandshake();
            }
          }
        }
      } catch (e) {
        logger.e("Error auto-connecting on USB Attach: $e");
      } finally {
        _isProcessing = false;
        notifyListeners();
      }
    } else if (isDetached && !scienceLabCommon.isWiFiConnected()) {
      _resetConnectionState();
    }
  }

  Future<void> initializeWiFi() async {
    if (!pslabIsConnected) {
      if (ScienceLabCommon.communicationHandler is! WifiCommsHandler) {
        ScienceLabCommon.communicationHandler = WifiCommsHandler(
          host: wifiHost,
        );
        scienceLabCommon.getScienceLab().mCommunicationHandler =
            ScienceLabCommon.communicationHandler;
      }
      bool portOpened = await scienceLabCommon.openWiFiDevice();
      if (portOpened) {
        await _validateHandshake();
      }
    }
  }

  Future<void> _validateHandshake() async {
    await setPSLabVersionIDs();

    if (pslabVersion == 0 || pslabVersionID == 'Not Connected') {
      logger.w(
          "Port opened, but device failed the Version Handshake. Rejecting generic device.");
      _resetConnectionState();
    } else {
      logger.i("Handshake successful: $pslabVersionID");
      pslabIsConnected = true;
      await fetchFirmwareVersion();
    }
    notifyListeners();
  }

  void _resetConnectionState() {
    scienceLabCommon.setConnected(false);
    pslabIsConnected = false;
    pslabVersionID = 'Not Connected';
    pslabVersion = 0;
    pslabFirmwareVersion = 0;
    notifyListeners();
  }

  Future<void> setPSLabVersionIDs() async {
    String rawVersion = await getIt.get<ScienceLab>().getVersion();

    if (rawVersion == pslabVersionIDV6) {
      pslabVersionID = pslabVersionIDV6;
      pslabVersion = 6;
    } else if (rawVersion == pslabVersionIDV5) {
      pslabVersionID = pslabVersionIDV5;
      pslabVersion = 5;
    } else {
      pslabVersionID = 'Not Connected';
      pslabVersion = 0;
    }
  }

  Future<void> fetchFirmwareVersion() async {
    if (getIt.get<ScienceLab>().isConnected()) {
      pslabFirmwareVersion =
          await getIt.get<ScienceLab>().mPacketHandler.getFirmwareVersion();
    }
    if (pslabFirmwareVersion < 3 && pslabFirmwareVersion != 0) {
      legacyFirmwareNotifier.value = "LegacyFirmwareDetected";
    }
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
