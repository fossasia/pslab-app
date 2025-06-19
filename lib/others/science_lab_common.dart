import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/socket_client.dart';
import 'package:pslab/others/logger_service.dart';

class ScienceLabCommon {
  static late ScienceLab _scienceLab;
  static late CommunicationHandler communicationHandler;
  static late SocketClient _socketClient;

  ScienceLabCommon(CommunicationHandler mCommunicationHandler) {
    communicationHandler = mCommunicationHandler;
    _scienceLab = ScienceLab(communicationHandler);
    _socketClient = _scienceLab.mSocketClient;
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

  Future<bool> openWiFiDevice() async {
    await _scienceLab.connectWiFi();
    return _socketClient.isConnected();
  }

  void setConnected(bool connected) {
    communicationHandler.connected = connected;
  }

  bool isConnected() {
    return communicationHandler.isConnected();
  }

  bool isDeviceFound() {
    return communicationHandler.isDeviceFound();
  }

  bool isWiFiConnected() {
    return _socketClient.isConnected();
  }

  void setWiFiConnected(bool connected) {
    _socketClient.setConnected(connected);
  }
}
