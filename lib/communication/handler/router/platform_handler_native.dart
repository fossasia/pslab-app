import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/handler/comms_handler.dart';

CommunicationHandler getPlatformHandler() {
  return PSLabCommunicationHandler();
}
