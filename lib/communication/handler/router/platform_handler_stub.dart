import 'package:pslab/communication/handler/base.dart';

CommunicationHandler getPlatformHandler() {
  throw UnsupportedError(
      'Cannot create a handler without dart:io or dart:js_interop');
}
