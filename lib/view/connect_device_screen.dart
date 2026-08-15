import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
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

class _HomeScreenState extends State<ConnectDeviceScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  bool _isConnectingWifi = false;

  @override
  void initState() {
    super.initState();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 6,
      ),
    );
  }

  Future<void> _connectWifi(BoardStateProvider provider) async {
    provider.setWifiHost("192.168.4.1");

    setState(() {
      _isConnectingWifi = true;
    });

    _showSnackBar(appLocalizations.connectingToWifi);

    try {
      await provider.initializeWiFi();

      if (!mounted) return;

      if (provider.pslabIsConnected) {
        _showSnackBar("${appLocalizations.wifiConnectionSuccess} (WebSockets)");
      } else {
        _showSnackBar(appLocalizations.wifiConnectionFailed);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(appLocalizations.wifiConnectionFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingWifi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 2,
      title: appLocalizations.connectDevice,
      body: Consumer<BoardStateProvider>(
        builder: (context, provider, _) {
          final bool isWifiConnected =
              provider.scienceLabCommon.isWiFiConnected();

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (provider.pslabIsConnected) ...[
                            Center(
                              child: Image.asset(
                                isWifiConnected
                                    ? ConnectDeviceScreen.iconWifiConnected
                                    : ConnectDeviceScreen.iconUsbConnected,
                                width: 90,
                                height: 90,
                              ),
                            ),
                            Center(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  '${appLocalizations.deviceConnected} via ${isWifiConnected ? "Wi-Fi" : "USB"}\n\nFirmware: ${provider.pslabVersionID}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  appLocalizations.noDeviceFound,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.only(
                                      top: 30, bottom: 20, left: 20, right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: primaryRed, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.cable,
                                              color: Colors.black87, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            appLocalizations.usbTitle,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _stepText(appLocalizations.usbStep1),
                                      const SizedBox(height: 8),
                                      _stepText(appLocalizations.usbStep2),
                                      const SizedBox(height: 8),
                                      _stepText(appLocalizations.usbStep3),
                                      const SizedBox(height: 8),
                                      _stepText(appLocalizations.usbStep4),
                                      const SizedBox(height: 8),
                                      _stepText(appLocalizations.usbStep5),
                                      const SizedBox(height: 20),
                                      const Divider(thickness: 1),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          const Icon(Icons.wifi,
                                              color: Colors.black87, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            appLocalizations.wifiTitle,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _stepText(appLocalizations.wifiStep1),
                                      const SizedBox(height: 8),
                                      _stepText(appLocalizations.wifiStep2),
                                      const SizedBox(height: 8),
                                      _stepText(appLocalizations.wifiStep3),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  top: 2.0, right: 8.0),
                                              child: Icon(
                                                  Icons.check_circle_outline,
                                                  size: 16,
                                                  color: Colors.black87),
                                            ),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    height: 1.4,
                                                    color: Colors.black,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                        text: appLocalizations
                                                            .wifiFlashingSetupCheck),
                                                    WidgetSpan(
                                                      alignment:
                                                          PlaceholderAlignment
                                                              .baseline,
                                                      baseline: TextBaseline
                                                          .alphabetic,
                                                      child: InkWell(
                                                        onTap: () async {
                                                          final uri = Uri.parse(
                                                              appLocalizations
                                                                  .wifiFlashingSetupLinkUrl);
                                                          if (await canLaunchUrl(
                                                              uri)) {
                                                            await launchUrl(
                                                                uri);
                                                          } else {
                                                            logger.e(
                                                                'Could not launch URL');
                                                          }
                                                        },
                                                        child: Text(
                                                          appLocalizations
                                                              .wifiFlashingSetupLinkText,
                                                          style: TextStyle(
                                                            color: primaryRed,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const TextSpan(text: "."),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _stepText(appLocalizations.wifiStep4),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            backgroundColor: primaryRed,
                                            foregroundColor:
                                                buttonForegroundColor,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            elevation: 0,
                                          ),
                                          onPressed: _isConnectingWifi
                                              ? null
                                              : () => _connectWifi(provider),
                                          child: _isConnectingWifi
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  appLocalizations
                                                      .connectWifiButton,
                                                  style: TextStyle(
                                                    color: buttonTextColor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 1,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        appLocalizations.stepsToConnectTitle,
                                        style: TextStyle(
                                          color: primaryRed,
                                          fontStyle: FontStyle.normal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _stepText(String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2.0, right: 8.0),
        child:
            Icon(Icons.check_circle_outline, size: 16, color: Colors.black87),
      ),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.black,
          ),
        ),
      ),
    ],
  );
}
