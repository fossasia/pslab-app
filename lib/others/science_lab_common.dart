import 'package:pslab/communication/communication_handler.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/others/logger_service.dart';

class ScienceLabCommon {
  static late ScienceLab scienceLab;
  bool connected = false;

  ScienceLabCommon._privateConstructor();

  static final ScienceLabCommon _instance =
      ScienceLabCommon._privateConstructor();

  factory ScienceLabCommon() => _instance;

  Future<bool> openDevice(CommunicationHandler communicationHandler) async {
    scienceLab = ScienceLab(communicationHandler);
    await scienceLab.connect();
    if (!scienceLab.isConnected()) {
      logger.d("Error in connection");
      return false;
    }
    connected = true;
    return true;
  }
}
