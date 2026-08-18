import 'dart:async';
import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/src/rust/api/bootloader.dart';
import 'package:pslab/src/rust/api/simple.dart' as rust_api;

class NativeFirmwareFlasher {
  final CommunicationHandler handler;
  final Function(double progress, String status) onProgress;
  final Function() onSuccess;
  final Function(String error) onError;

  StreamSubscription<FlashState>? _subscription;

  NativeFirmwareFlasher({
    required this.handler,
    required this.onProgress,
    required this.onSuccess,
    required this.onError,
  });

  Future<void> preparePort() async {
    await handler.initialize();
    await handler.open();
    rust_api.setDtr(state: false);
    rust_api.setRts(state: false);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void startFlashing(String hexStr) {
    try {
      _subscription?.cancel();
      _subscription = flashFirmware(hexStr: hexStr).listen(
        (state) {
          if (state is FlashState_Connecting) {
            onProgress(0.05, "Connecting at 460800 baud...");
          } else if (state is FlashState_Erasing) {
            onProgress(0.20, "Erasing Flash Memory...");
          } else if (state is FlashState_Writing) {
            double progress = 0.20 + (state.progressPercent / 100.0 * 0.70);
            onProgress(progress, "Writing Flash: ${state.progressPercent}%");
          } else if (state is FlashState_Verifying) {
            onProgress(0.95, "Verifying On-Board Checksum...");
          } else if (state is FlashState_Finished) {
            onProgress(
                1.0, "Flashing Successful! Reset or power cycle the device.");
            onSuccess();
          } else if (state is FlashState_Error) {
            onError(state.message);
          }
        },
        onError: (err) {
          onError(err.toString());
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
