import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:usb_serial/usb_serial.dart';

import 'package:pslab/others/science_lab_common.dart';

class BoardStateProvider extends ChangeNotifier {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool initialisationStatus = false;
  bool pslabIsConnected = false;
  bool hasPermission = false;
  late ScienceLabCommon scienceLabCommon;
  String pslabVersionID = 'Not Connected';
  String pslabVersionIDV6 = 'PSLab V6';
  String pslabVersionIDV5 = 'PSLab V5';
  int pslabVersion = 0;
  late String exportFormat;
  bool autoStart = true;
  bool _isProcessing = false;

  BoardStateProvider() {
    scienceLabCommon = getIt.get<ScienceLabCommon>();
    exportFormat = appLocalizations.txtFormat;
  }

  Future<void> initialize() async {
    if (_isProcessing) return;
    _isProcessing = true;
    await scienceLabCommon.initialize();
    pslabIsConnected = await scienceLabCommon.openDevice();
    setPSLabVersionIDs();
    _isProcessing = false;
    if (autoStart) {
      if (Platform.isAndroid) {
        UsbSerial.usbEventStream?.listen(
          (UsbEvent usbEvent) async {
            if (usbEvent.event == UsbEvent.ACTION_USB_ATTACHED) {
              if (_isProcessing) return;
              _isProcessing = true;
              if (await attemptToConnectPSLab()) {
                pslabIsConnected = await scienceLabCommon.openDevice();
                setPSLabVersionIDs();
                _isProcessing = false;
              }
            } else if (usbEvent.event == UsbEvent.ACTION_USB_DETACHED &&
                !scienceLabCommon.isWiFiConnected()) {
              scienceLabCommon.setConnected(false);
              pslabIsConnected = false;
              pslabVersionID = 'Not Connected';
              notifyListeners();
            }
          },
        );
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

  Future<void> initializeWiFi() async {
    if (!pslabIsConnected) {
      pslabIsConnected = await scienceLabCommon.openWiFiDevice();
      setPSLabVersionIDs();
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

  Future<bool> attemptToConnectPSLab() async {
    if (scienceLabCommon.isConnected()) {
      logger.d("Device Connected Successfully");
    } else {
      await scienceLabCommon.initialize();
      if (scienceLabCommon.isDeviceFound()) {
        return true;
      }
    }
    return false;
  }
}
