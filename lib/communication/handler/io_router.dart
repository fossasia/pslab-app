import 'dart:io';
import 'base.dart';
import 'comms_handler.dart';
import 'ios_comms_handler.dart';

CommunicationHandler getCommunicationHandler() {
  if (Platform.isAndroid ||
      Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS) {
    return PSLabCommunicationHandler();
  } else {
    return IosNoOpCommunicationHandler();
  }
}
