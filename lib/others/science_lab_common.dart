import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class ScienceLabCommon {
  static late ScienceLab _scienceLab;
  static late CommunicationHandler communicationHandler;

  ScienceLabCommon(CommunicationHandler mCommunicationHandler) {
    communicationHandler = mCommunicationHandler;
    _scienceLab = ScienceLab(communicationHandler);
  }

  ScienceLab getScienceLab() {
    return _scienceLab;
  }

  Future<bool> openDevice() async {
    await _scienceLab.connect();
    if (!_scienceLab.isConnected()) {
      logger.d("Error in connection");
      return false;
    }
    return true;
  }

  Future<void> initialize() {
    return communicationHandler.initialize();
  }

  void setConnected() {
    communicationHandler.connected = true;
  }

  bool isConnected() {
    return communicationHandler.isConnected();
  }

  bool isDeviceFound() {
    return communicationHandler.isDeviceFound();
  }
}
