import 'package:get_it/get_it.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/handler/io_router.dart'
    if (dart.library.js_interop) 'package:pslab/communication/handler/web_router.dart';

import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/socket_client.dart';
import 'package:pslab/others/science_lab_common.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/providers/sht21_provider.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<CommunicationHandler>(
      () => getCommunicationHandler());

  getIt.registerLazySingleton<SocketClient>(() => SocketClient());
  getIt.registerLazySingleton<ScienceLabCommon>(
      () => ScienceLabCommon(getIt.get<CommunicationHandler>()));
  getIt.registerLazySingleton<ScienceLab>(
      () => getIt.get<ScienceLabCommon>().getScienceLab());
  getIt.registerLazySingleton<BoardStateProvider>(() => BoardStateProvider());
  getIt.registerLazySingleton<SHT21Provider>(() => SHT21Provider());
}

void registerAppLocalizations(AppLocalizations appLocalizations) {
  if (getIt.isRegistered<AppLocalizations>()) {
    getIt.unregister<AppLocalizations>();
  }
  getIt.registerLazySingleton<AppLocalizations>(() => appLocalizations);
}
