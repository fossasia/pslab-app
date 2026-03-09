import 'dart:io';
import 'base.dart';
import 'android_comms_handler.dart';
import 'desktop_comms_handler.dart';
import 'ios_comms_handler.dart';

CommunicationHandler getCommunicationHandler() {
  if (Platform.isAndroid) {
    return AndroidUSBCommunicationHandler();
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return DesktopUSBCommunicationHandler();
  } else {
    return IosNoOpCommunicationHandler();
  }
}
