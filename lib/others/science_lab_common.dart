import 'package:pslab/communication/communication_handler.dart';
import 'package:pslab/communication/science_lab.dart';

class ScienceLabCommon {
  static ScienceLab? scienceLab;
  bool connected = false;

  ScienceLabCommon._privateConstructor();

  static final ScienceLabCommon _instance =
      ScienceLabCommon._privateConstructor();

  factory ScienceLabCommon() => _instance;

  Future<bool> openDevice(CommunicationHandler communicationHandler) async {
    scienceLab = ScienceLab(communicationHandler);
    await scienceLab!.connect();
    if (!scienceLab!.isConnected()) {
      print("Error in connection");
      return false;
    }
    connected = true;
    return true;
  }
}
