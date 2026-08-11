import 'package:flutter/foundation.dart';
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

class _HomeScreenState extends State<ConnectDeviceScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  bool _isConnectingWifi = false;
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BoardStateProvider>(context, listen: false);
      _ipController.text = provider.wifiHost;

      provider.setUseWebSockets(kIsWeb);
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
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
    provider.setWifiHost(_ipController.text.trim());

    setState(() {
      _isConnectingWifi = true;
    });

    _showSnackBar(appLocalizations.connectingToWifi);

    try {
      await provider.initializeWiFi();

      if (!mounted) return;

      if (provider.pslabIsConnected) {
        String protocol = provider.useWebSockets ? "WebSockets" : "TCP";
        _showSnackBar("${appLocalizations.wifiConnectionSuccess} ($protocol)");
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
                          Center(
                            child: Image.asset(
                              provider.pslabIsConnected
                                  ? (provider.scienceLabCommon.isWiFiConnected()
                                      ? ConnectDeviceScreen.iconWifiConnected
                                      : ConnectDeviceScreen.iconUsbConnected)
                                  : ConnectDeviceScreen.iconUsbDisconnected,
                              width: 90,
                              height: 90,
                            ),
                          ),
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                provider.pslabIsConnected
                                    ? '${appLocalizations.deviceConnected}\n\n${provider.pslabVersionID}'
                                    : appLocalizations.noDeviceFound,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: usbConnectionColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: !provider.pslabIsConnected,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: primaryRed, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.cable,
                                          color: primaryRed, size: 24),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          appLocalizations.stepsToConnectTitle,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _stepText(
                                      appLocalizations.step1ConnectMicroUsb),
                                  const SizedBox(height: 12),
                                  _stepText(appLocalizations.step2ConnectOtg),
                                  const SizedBox(height: 12),
                                  _stepText(appLocalizations.step3ConnectPhone),
                                  const SizedBox(height: 12),
                                  _stepText(
                                      appLocalizations.step4ConnectWireless),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Visibility(
                            visible: !provider.pslabIsConnected,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: primaryRed, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.wifi,
                                          color: Colors.black, size: 24),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Wi-Fi Connection",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _ipController,
                                    style: const TextStyle(color: Colors.black),
                                    decoration: InputDecoration(
                                      labelText: 'IP Address',
                                      labelStyle: const TextStyle(
                                          color: Colors.black54),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: primaryRed,
                                          width: 1.5,
                                        ),
                                      ),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        backgroundColor: primaryRed,
                                        foregroundColor: buttonForegroundColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        elevation: 0,
                                      ),
                                      onPressed: _isConnectingWifi
                                          ? null
                                          : () => _connectWifi(provider),
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
                                              appLocalizations.wifi
                                                  .toUpperCase(),
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
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                              top: 35,
                              left: 60,
                              right: 60,
                            ),
                            child: Divider(color: dividerColor, height: 1),
                          ),
                          Center(
                            child: Container(
                              margin:
                                  const EdgeInsets.only(top: 20, bottom: 10),
                              padding: const EdgeInsets.all(10),
                              child: GestureDetector(
                                onTap: () async {
                                  final uri =
                                      Uri.parse(appLocalizations.pslabUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  } else {
                                    logger.e(
                                      'Could not launch ${appLocalizations.pslabUrl}',
                                    );
                                  }
                                },
                                child: Text(
                                  appLocalizations.whatIsPslab,
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 1.5,
                                    decorationColor: primaryRed,
                                    color: primaryRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
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
