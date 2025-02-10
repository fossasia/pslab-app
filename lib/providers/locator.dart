import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:pslab/communication/handler/android_comms_handler.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/handler/ios_comms_handler.dart';
import 'package:pslab/providers/board_state_provider.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<CommunicationHandler>(() {
    if (Platform.isAndroid) {
      return AndroidUSBCommunicationHandler();
    } else {
      return IosNoOpCommunicationHandler();
    }
  });
  getIt.registerLazySingleton<BoardStateProvider>(() => BoardStateProvider());
}
