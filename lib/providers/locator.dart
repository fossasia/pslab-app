import 'package:get_it/get_it.dart';
import 'package:pslab/providers/board_state_provider.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<BoardStateProvider>(() => BoardStateProvider());
}
