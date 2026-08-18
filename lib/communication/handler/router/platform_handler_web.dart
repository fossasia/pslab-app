import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/handler/web_comms_handler.dart';

CommunicationHandler getPlatformHandler() {
  return WebCommsHandler();
}
