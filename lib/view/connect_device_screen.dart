import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/colors.dart';

class ConnectDeviceScreen extends StatefulWidget {
  const ConnectDeviceScreen({super.key});
  final String iconUsbDisconnected =
      'assets/icons/icons_usb_disconnected_100.png';
  final String iconUsbConnected = 'assets/icons/icons8_usb_connected_100.png';
  final String iconWifiConnected = 'assets/icons/icons8_wifi_connected_100.png';

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ConnectDeviceScreen> {
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 2,
      title: connectDevice,
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
                                ? widget.iconWifiConnected
                                : widget.iconUsbConnected)
                            : widget.iconUsbDisconnected,
                        width: 80,
                        height: 80,
                      ),
                    ),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(
                            top: 20, bottom: 60, left: 40, right: 40),
                        child: Text(
                          provider.pslabIsConnected
                              ? '$deviceConnected\n\n${provider.pslabVersionID}'
                              : noDeviceFound,
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
                      visible: provider.pslabIsConnected ? false : true,
                      child: Container(
                        margin: const EdgeInsets.only(
                            left: 40, right: 40, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                stepsToConnect[0],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              stepsToConnect[1],
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              stepsToConnect[2],
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              stepsToConnect[3],
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: provider.pslabIsConnected ? false : true,
                      child: Center(
                        child: Text(
                          bluetoothWifiConnection,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: provider.pslabIsConnected ? false : true,
                      child: Container(
                        margin: const EdgeInsets.only(top: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                backgroundColor: primaryRed,
                                foregroundColor: buttonForegroundColor,
                              ),
                              onPressed: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  bluetooth,
                                  style: TextStyle(color: buttonTextColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                backgroundColor: primaryRed,
                                foregroundColor: buttonForegroundColor,
                              ),
                              onPressed: () async {
                                await provider.initializeWiFi();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  wifi,
                                  style: TextStyle(color: buttonTextColor),
                                ),
                              ),
                            ),
                          ],
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
                            await launchUrl(Uri.parse(pslabUrl));
                          },
                          child: Text(
                            whatisPslab,
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
