import 'package:flutter/cupertino.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:usb_serial/usb_serial.dart';

import 'package:pslab/others/science_lab_common.dart';

class BoardStateProvider extends ChangeNotifier {
  bool initialisationStatus = false;
  bool pslabIsConnected = false;
  bool hasPermission = false;
  late ScienceLabCommon scienceLabCommon;
  String pslabVersionID = 'Not Connected';

  BoardStateProvider() {
    scienceLabCommon = getIt.get<ScienceLabCommon>();
  }

  Future<void> initialize() async {
    await scienceLabCommon.initialize();
    pslabIsConnected = await scienceLabCommon.openDevice();
    setPSLabVersionIDs();
    UsbSerial.usbEventStream?.listen(
      (UsbEvent usbEvent) async {
        if (usbEvent.event == UsbEvent.ACTION_USB_ATTACHED) {
          if (await attemptToConnectPSLab()) {
            pslabIsConnected = await scienceLabCommon.openDevice();
            setPSLabVersionIDs();
          }
        } else if (usbEvent.event == UsbEvent.ACTION_USB_DETACHED) {
          scienceLabCommon.setConnected(false);
          pslabIsConnected = false;
          pslabVersionID = 'Not Connected';
          notifyListeners();
        }
      },
    );
  }

  Future<void> setPSLabVersionIDs() async {
    pslabVersionID = await getIt.get<ScienceLab>().getVersion();
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
