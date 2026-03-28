import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/colors.dart';

class ConnectDeviceScreen extends StatefulWidget {
  const ConnectDeviceScreen({super.key});

  static const String iconUsbDisconnected =
      'assets/icons/icons_usb_disconnected_100.png';
  static const String iconUsbConnected =
      'assets/icons/icons8_usb_connected_100.png';
  static const String iconWifiConnected =
      'assets/icons/icons8_wifi_connected_100.png';

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

Widget _stepText(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      height: 1.35,
    ),
  );
}

class _HomeScreenState extends State<ConnectDeviceScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _isConnectingWifi = false;

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _connectWifi(BoardStateProvider provider) async {
    setState(() {
      _isConnectingWifi = true;
    });

    _showSnackBar(appLocalizations.connectingToWifi);

    try {
      await provider.initializeWiFi();

      if (!mounted) return;

      if (provider.pslabIsConnected) {
        _showSnackBar(
          appLocalizations.wifiConnectionSuccess,
          backgroundColor: Theme.of(context).colorScheme.primary,
        );
      } else {
        _showSnackBar(
          appLocalizations.wifiConnectionFailed,
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        appLocalizations.wifiConnectionFailed,
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingWifi = false;
        });
      }
    }
  }

  Future<void> _connectUSB(BoardStateProvider provider) async {
    try {
      final success = await provider.connectUSB();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device connected successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to connect device")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 2,
      title: appLocalizations.connectDevice,
      body: Consumer<BoardStateProvider>(
        builder: (context, provider, _) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: Image.asset(
                        provider.pslabIsConnected
                            ? (provider.scienceLabCommon.isWiFiConnected()
                                ? ConnectDeviceScreen.iconWifiConnected
                                : ConnectDeviceScreen.iconUsbConnected)
                            : ConnectDeviceScreen.iconUsbDisconnected,
                        width: 80,
                        height: 80,
                      ),
                    ),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(
                            top: 20, bottom: 24, left: 40, right: 40),
                        child: Text(
                          provider.pslabIsConnected
                              ? '${appLocalizations.deviceConnected}\n\n${provider.pslabVersionID}'
                              : appLocalizations.noDeviceFound,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: usbConnectionColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: !provider.pslabIsConnected,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appLocalizations.stepsToConnectTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _stepText(appLocalizations.step1ConnectMicroUsb),
                              const SizedBox(height: 8),
                              _stepText(appLocalizations.step2ConnectOtg),
                              const SizedBox(height: 8),
                              _stepText(appLocalizations.step3ConnectPhone),
                              const SizedBox(height: 8),
                              _stepText(appLocalizations.step4ConnectWireless),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: !provider.pslabIsConnected,
                      child: Center(
                        child: Text(
                          appLocalizations.wifiConnection,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: !provider.pslabIsConnected,
                      child: Container(
                        margin: const EdgeInsets.only(top: 15),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            backgroundColor: primaryRed,
                            foregroundColor: buttonForegroundColor,
                          ),
                          onPressed: _isConnectingWifi
                              ? null
                              : () => _connectWifi(provider),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: _isConnectingWifi
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    appLocalizations.wifi.toUpperCase(),
                                    style: TextStyle(color: buttonTextColor),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (kIsWeb)
                      Visibility(
                        visible: !provider.pslabIsConnected,
                        child: Container(
                          margin: const EdgeInsets.only(top: 15),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              backgroundColor: primaryRed,
                              foregroundColor: buttonForegroundColor,
                            ),
                            onPressed: provider.isProcessing
                                ? null
                                : () => _connectUSB(provider),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: provider.isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'CONNECT USB',
                                      style: TextStyle(color: buttonTextColor),
                                    ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin:
                          const EdgeInsets.only(top: 30, left: 120, right: 120),
                      child: Divider(color: dividerColor, height: 1),
                    ),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(10),
                        child: GestureDetector(
                          onTap: () async {
                            await launchUrl(
                                Uri.parse(appLocalizations.pslabUrl));
                          },
                          child: Text(
                            appLocalizations.whatIsPslab,
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationThickness: 1,
                              decorationColor: primaryRed,
                              color: primaryRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
