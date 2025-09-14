import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:pslab/communication/handler/desktop_comms_handler.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/communication/handler/android_comms_handler.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/handler/ios_comms_handler.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/socket_client.dart';
import 'package:pslab/others/science_lab_common.dart';
import 'package:pslab/providers/board_state_provider.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<CommunicationHandler>(() {
    if (Platform.isAndroid) {
      return AndroidUSBCommunicationHandler();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return DesktopUSBCommunicationHandler();
    } else {
      return IosNoOpCommunicationHandler();
    }
  });
  getIt.registerLazySingleton<SocketClient>(() => SocketClient());
  getIt.registerLazySingleton<ScienceLabCommon>(
      () => ScienceLabCommon(getIt.get<CommunicationHandler>()));
  getIt.registerLazySingleton<ScienceLab>(
      () => getIt.get<ScienceLabCommon>().getScienceLab());
  getIt.registerLazySingleton<BoardStateProvider>(() => BoardStateProvider());
}

void registerAppLocalizations(AppLocalizations appLocalizations) {
  if (getIt.isRegistered<AppLocalizations>()) {
    getIt.unregister<AppLocalizations>();
  }
  getIt.registerLazySingleton<AppLocalizations>(() => appLocalizations);
}
