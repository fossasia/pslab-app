import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:usb_serial/usb_serial.dart';

import '../others/science_lab_common.dart';

class BoardStateProvider extends ChangeNotifier {
  bool initialisationStatus = false;
  bool pslabIsConnected = false;
  bool hasPermission = false;
  late CommunicationHandler communicationHandler;
  late ScienceLabCommon scienceLabCommon;
  String pslabVersionID = 'Not Connected';

  Future<void> initialize() async {
    scienceLabCommon = ScienceLabCommon();
    communicationHandler = GetIt.instance.get<CommunicationHandler>();
    await communicationHandler.initialize();
    pslabIsConnected = await scienceLabCommon.openDevice(communicationHandler);
    setPSLabVersionIDs();
    UsbSerial.usbEventStream?.listen((UsbEvent usbEvent) async {
      if (usbEvent.event == UsbEvent.ACTION_USB_ATTACHED) {
        if (await attemptToConnectPSLab()) {
          pslabIsConnected =
              await scienceLabCommon.openDevice(communicationHandler);
          setPSLabVersionIDs();
        }
      } else if (usbEvent.event == UsbEvent.ACTION_USB_DETACHED) {
        communicationHandler.connected = false;
        pslabIsConnected = false;
        pslabVersionID = 'Not Connected';
        notifyListeners();
      }
    });
  }

  Future<void> setPSLabVersionIDs() async {
    pslabVersionID = await ScienceLabCommon.scienceLab.getVersion();
    notifyListeners();
  }

  Future<bool> attemptToConnectPSLab() async {
    scienceLabCommon = ScienceLabCommon();
    if (communicationHandler.isConnected()) {
      logger.d("Device Connected Successfully");
    } else {
      communicationHandler = CommunicationHandler();
      await communicationHandler.initialize();
      if (communicationHandler.isDeviceFound()) {
        return true;
      }
    }
    return false;
  }
}
