import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pslab/view/pin_layout_screen.dart';

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
  String _selectedDevice = 'PSLab';
  bool _isConnectingWifi = false;
  bool _isConnectingLabrador = false;
  bool _isConnectingPslab = false;

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

  Future<void> _connectLabrador(BoardStateProvider provider) async {
    setState(() => _isConnectingLabrador = true);
    _showSnackBar(appLocalizations.connectingToLabrador);
    try {
      bool success = false;
      if (kIsWeb) {
        success = await provider.connectLabradorWeb();
      } else {
        await provider.initialize();
        success = provider.pslabIsConnected && provider.isLabrador;
      }
      if (!mounted) return;
      if (success || (provider.pslabIsConnected && provider.isLabrador)) {
        _showSnackBar(appLocalizations.connectedToLabradorSuccess);
      } else {
        final err = provider.lastError ?? "";
        _showSnackBar(
            "${appLocalizations.couldNotConnectToLabrador}${err.isNotEmpty ? ': $err' : ''}");
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("${appLocalizations.connectionError}$e");
    } finally {
      if (mounted) {
        setState(() => _isConnectingLabrador = false);
      }
    }
  }

  Future<void> _connectPslab(BoardStateProvider provider) async {
    setState(() => _isConnectingPslab = true);
    _showSnackBar(appLocalizations.connectingToPslab);
    try {
      await provider.initialize();
      if (!mounted) return;
      if (provider.pslabIsConnected) {
        _showSnackBar(appLocalizations.deviceConnected);
      } else {
        _showSnackBar(appLocalizations.noDeviceFound);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("${appLocalizations.connectionError}$e");
    } finally {
      if (mounted) {
        setState(() => _isConnectingPslab = false);
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
          final String displayDeviceName =
              (provider.pslabVersionID == 'PSLab Pico' ||
                      provider.pslabVersion == 7)
                  ? appLocalizations.pslabMini
                  : provider.pslabVersionID;
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
                            _buildConnectedDeviceCard(
                              context,
                              provider,
                              isWifiConnected,
                              displayDeviceName,
                            ),
                            const SizedBox(height: 18),
                            _buildBoardSpecificationsCard(
                              context,
                              provider,
                              displayDeviceName,
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
                                  margin: const EdgeInsets.only(top: 14),
                                  padding: const EdgeInsets.only(
                                      top: 28, bottom: 20, left: 20, right: 20),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.cable,
                                                color: Colors.black87,
                                                size: 20,
                                              ),
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
                                          Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: primaryRed,
                                                  width: 1.5),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _selectedDevice,
                                                icon: Icon(
                                                    Icons.arrow_drop_down,
                                                    color: primaryRed,
                                                    size: 22),
                                                isDense: true,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'PSLab',
                                                    child: Text('PSLab'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'EspoTek Labrador',
                                                    child: Text(
                                                        'EspoTek Labrador'),
                                                  ),
                                                ],
                                                onChanged: (String? val) {
                                                  if (val != null) {
                                                    setState(() =>
                                                        _selectedDevice = val);
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (_selectedDevice == 'PSLab') ...[
                                        _stepText(appLocalizations.usbStep1),
                                        const SizedBox(height: 8),
                                        _stepText(appLocalizations.usbStep2),
                                        const SizedBox(height: 8),
                                        _stepText(appLocalizations.usbStep3),
                                        const SizedBox(height: 8),
                                        _stepText(appLocalizations.usbStep4),
                                        const SizedBox(height: 8),
                                        _stepText(appLocalizations.usbStep5),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              backgroundColor: primaryRed,
                                              foregroundColor:
                                                  buttonForegroundColor,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              elevation: 0,
                                            ),
                                            icon: _isConnectingPslab
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Icon(Icons.usb,
                                                    color: Colors.white,
                                                    size: 20),
                                            label: Text(
                                              _isConnectingPslab
                                                  ? appLocalizations.connecting
                                                  : (kIsWeb
                                                      ? appLocalizations
                                                          .connectPslabWebSerial
                                                      : appLocalizations
                                                          .connectPslab),
                                              style: TextStyle(
                                                color: buttonTextColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            onPressed: _isConnectingPslab
                                                ? null
                                                : () => _connectPslab(provider),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        const Divider(thickness: 1),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            const Icon(Icons.wifi,
                                                color: Colors.black87,
                                                size: 20),
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
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
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
                                                                  FontWeight
                                                                      .bold,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ] else ...[
                                        _stepText(
                                            appLocalizations.labradorStep1),
                                        const SizedBox(height: 10),
                                        _stepText(
                                            appLocalizations.labradorStep2),
                                        const SizedBox(height: 10),
                                        _stepText(
                                            appLocalizations.labradorStep3),
                                        const SizedBox(height: 10),
                                        _stepText(
                                            appLocalizations.labradorStep4),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              backgroundColor: primaryRed,
                                              foregroundColor:
                                                  buttonForegroundColor,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              elevation: 0,
                                            ),
                                            icon: _isConnectingLabrador
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.developer_board,
                                                    color: Colors.white,
                                                    size: 20),
                                            label: Text(
                                              _isConnectingLabrador
                                                  ? appLocalizations.connecting
                                                  : (kIsWeb
                                                      ? appLocalizations
                                                          .connectLabradorWebUSB
                                                      : appLocalizations
                                                          .connectLabrador),
                                              style: TextStyle(
                                                color: buttonTextColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            onPressed: _isConnectingLabrador
                                                ? null
                                                : () =>
                                                    _connectLabrador(provider),
                                          ),
                                        ),
                                      ],
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
                                        appLocalizations.connectingToDevice,
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

  Widget _buildConnectedDeviceCard(
    BuildContext context,
    BoardStateProvider provider,
    bool isWifiConnected,
    String displayDeviceName,
  ) {
    final bool isLabrador = provider.isLabrador ||
        provider.pslabVersion == 8 ||
        provider.pslabVersionID.toLowerCase().contains('labrador');
    final bool isV6 =
        provider.pslabVersion == 6 || provider.pslabVersionID.contains('V6');
    final bool isV5 =
        provider.pslabVersion == 5 || provider.pslabVersionID.contains('V5');
    final bool isMini = provider.pslabVersion == 7 ||
        provider.pslabVersionID.toLowerCase().contains('pico') ||
        provider.pslabVersionID.toLowerCase().contains('mini') ||
        displayDeviceName == appLocalizations.pslabMini;

    final String resolvedBoardName;
    if (isLabrador) {
      resolvedBoardName = 'EspoTek Labrador';
    } else if (isV6) {
      resolvedBoardName = 'PSLab V6';
    } else if (isV5) {
      resolvedBoardName = 'PSLab V5';
    } else if (isMini) {
      resolvedBoardName = appLocalizations.pslabMini;
    } else if (displayDeviceName.isNotEmpty &&
        displayDeviceName != 'Not Connected') {
      resolvedBoardName = displayDeviceName;
    } else {
      resolvedBoardName = 'PSLab';
    }

    final String connectionMethod = isWifiConnected
        ? 'Wi-Fi'
        : (kIsWeb && provider.isLabrador
            ? 'WebUSB'
            : (kIsWeb ? 'Web Serial' : 'USB'));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          padding:
              const EdgeInsets.only(top: 26, bottom: 20, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryRed, width: 1.5),
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
              Text(
                resolvedBoardName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                appLocalizations.deviceConnectedVia(
                  appLocalizations.deviceConnected,
                  connectionMethod,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  onPressed: () {
                    provider.disconnect();
                  },
                  child: Text(
                    appLocalizations.disconnectDevice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appLocalizations.deviceConnected,
                    style: TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoardSpecificationsCard(
    BuildContext context,
    BoardStateProvider provider,
    String displayDeviceName,
  ) {
    final bool isLabrador = provider.isLabrador ||
        provider.pslabVersion == 8 ||
        provider.pslabVersionID.toLowerCase().contains('labrador');
    final bool isV5 =
        provider.pslabVersion == 5 || provider.pslabVersionID.contains('V5');
    final bool isMini = provider.pslabVersion == 7 ||
        provider.pslabVersionID.toLowerCase().contains('pico') ||
        provider.pslabVersionID.toLowerCase().contains('mini') ||
        displayDeviceName == appLocalizations.pslabMini;

    final List<_BoardSpecBullet> bullets;
    if (isLabrador) {
      bullets = [
        _BoardSpecBullet(
          label: appLocalizations.specLabelMicrocontroller,
          detail: appLocalizations.specLabradorMcuDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelOperatingVoltage,
          detail: appLocalizations.specLabradorVoltageDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelPowerSupplyOutput,
          detail: appLocalizations.specLabradorPsuDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.oscilloscope,
          detail: appLocalizations.specLabradorOscilloscopeDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.waveGenerator,
          detail: appLocalizations.specLabradorWaveGenDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.logicAnalyzer,
          detail: appLocalizations.specLabradorLogicAnalyzerDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.digitalOutputs,
          detail: appLocalizations.specLabradorDigitalOutputsDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.multimeter,
          detail: appLocalizations.specLabradorMultimeterDetail,
        ),
      ];
    } else if (isMini) {
      bullets = [
        _BoardSpecBullet(
          label: appLocalizations.specLabelMainProcessor,
          detail: appLocalizations.specMiniProcessorDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelOperatingVoltage,
          detail: appLocalizations.specMiniVoltageDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelPowerRails,
          detail: appLocalizations.specMiniPowerRailsDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.oscilloscope,
          detail: appLocalizations.specMiniOscilloscopeDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.waveGenerator,
          detail: appLocalizations.specMiniWaveGenDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.logicAnalyzer,
          detail: appLocalizations.specMiniLogicAnalyzerDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelBusesAndExpansion,
          detail: appLocalizations.specMiniBusesDetail,
        ),
      ];
    } else if (isV5) {
      bullets = [
        _BoardSpecBullet(
          label: appLocalizations.specLabelMainProcessor,
          detail: appLocalizations.specV5ProcessorDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelOperatingVoltage,
          detail: appLocalizations.specV5VoltageDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelProgrammableVoltages,
          detail: appLocalizations.specV5ProgrammableVoltagesDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelCurrentSourcePcs,
          detail: appLocalizations.specV5CurrentSourceDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.oscilloscope,
          detail: appLocalizations.specV5OscilloscopeDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.waveGenerator,
          detail: appLocalizations.specV5WaveGenDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.logicAnalyzer,
          detail: appLocalizations.specV5LogicAnalyzerDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.multimeter,
          detail: appLocalizations.specV5MultimeterDetail,
        ),
      ];
    } else {
      bullets = [
        _BoardSpecBullet(
          label: appLocalizations.specLabelMainProcessor,
          detail: appLocalizations.specV6ProcessorDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelWirelessModule,
          detail: appLocalizations.specV6WirelessModuleDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelOperatingVoltage,
          detail: appLocalizations.specV6VoltageDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelProgrammableVoltages,
          detail: appLocalizations.specV6ProgrammableVoltagesDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelCurrentSourcePcs,
          detail: appLocalizations.specV6CurrentSourceDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.oscilloscope,
          detail: appLocalizations.specV6OscilloscopeDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.waveGenerator,
          detail: appLocalizations.specV6WaveGenDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.logicAnalyzer,
          detail: appLocalizations.specV6LogicAnalyzerDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.multimeter,
          detail: appLocalizations.specV6MultimeterDetail,
        ),
        _BoardSpecBullet(
          label: appLocalizations.specLabelCommunicationInterfaces,
          detail: appLocalizations.specV6CommunicationDetail,
        ),
      ];
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          padding:
              const EdgeInsets.only(top: 26, bottom: 18, left: 18, right: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryRed, width: 1.5),
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
              ...bullets.map(
                  (bullet) => _buildBulletPoint(bullet.label, bullet.detail)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryRed,
                    side: BorderSide(color: primaryRed, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PSLabPinLayoutScreen(),
                      ),
                    );
                  },
                  child: Text(
                    appLocalizations.viewPinLayout,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryRed,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                appLocalizations.boardSpecifications,
                style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String label, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0, right: 8.0),
            child: Text(
              '•',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: detail,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardSpecBullet {
  final String label;
  final String detail;

  const _BoardSpecBullet({
    required this.label,
    required this.detail,
  });
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
