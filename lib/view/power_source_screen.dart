import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/power_source_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/power_source_knob.dart';

class PowerSourceScreen extends StatefulWidget {
  final String icRecord = 'assets/icons/ic_record_white.png';
  final String powerSourceCircuit = 'assets/images/powersource_circuit.png';
  const PowerSourceScreen({super.key});

  @override
  State<StatefulWidget> createState() => _PowerSourceScreenState();
}

class _PowerSourceScreenState extends State<PowerSourceScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _showGuide = false;

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getPowerSourceContent() {
    return [
      InstrumentIntroText(text: appLocalizations.powerSourceIntro),
      InstrumentImage(imagePath: widget.powerSourceCircuit),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint3),
      InstrumentBulletPoint(text: appLocalizations.powerSourceBulletPoint4),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PowerSourceStateProvider()),
      ],
      child: Consumer<PowerSourceStateProvider>(
        builder: (context, provider, _) {
          final powerSourceCards = [
            Card(
              color: scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            appLocalizations.pinPV1,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(
                              text:
                                  '${provider.voltagePV1.toStringAsFixed(2)} V',
                            ),
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                            onSubmitted: (value) async {
                              String powerValue =
                                  value.replaceAll("V", "").trim();
                              double parsedValue =
                                  double.tryParse(powerValue) ?? 0.0;
                              await provider.setPV1(parsedValue);
                            },
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_up),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV1(
                                          provider.voltagePV1 + provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_down),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV1(
                                          provider.voltagePV1 - provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 55,
                    child: PowerSourceKnob(
                      maxValue: 1000,
                      pin: Pin.pv1,
                    ),
                  )
                ],
              ),
            ),
            Card(
              color: scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            appLocalizations.pinPV2,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(
                              text:
                                  '${provider.voltagePV2.toStringAsFixed(2)} V',
                            ),
                            textAlign: TextAlign.center,
                            onSubmitted: (value) async {
                              String powerValue =
                                  value.replaceAll("V", "").trim();
                              double parsedValue =
                                  double.tryParse(powerValue) ?? 0.0;
                              await provider.setPV2(parsedValue);
                            },
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_up),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV2(
                                          provider.voltagePV2 + provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_down),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV2(
                                          provider.voltagePV2 - provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 55,
                    child: PowerSourceKnob(
                      maxValue: 660,
                      pin: Pin.pv2,
                    ),
                  )
                ],
              ),
            ),
            Card(
              color: scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            appLocalizations.pinPV3,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(
                              text:
                                  '${provider.voltagePV3.toStringAsFixed(2)} V',
                            ),
                            textAlign: TextAlign.center,
                            onSubmitted: (value) async {
                              String powerValue =
                                  value.replaceAll("V", "").trim();
                              double parsedValue =
                                  double.tryParse(powerValue) ?? 0.0;
                              await provider.setPV3(parsedValue);
                            },
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_up),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV3(
                                          provider.voltagePV3 + provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_down),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPV3(
                                          provider.voltagePV3 - provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 55,
                    child: PowerSourceKnob(
                      maxValue: 330,
                      pin: Pin.pv3,
                    ),
                  )
                ],
              ),
            ),
            Card(
              color: scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            appLocalizations.pinPCS,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(
                              text:
                                  '${provider.currentPCS.toStringAsFixed(2)} mA',
                            ),
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                            onSubmitted: (value) async {
                              String powerValue =
                                  value.replaceAll("V", "").trim();
                              double parsedValue =
                                  double.tryParse(powerValue) ?? 0.0;
                              await provider.setPCS(parsedValue);
                            },
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: powerSourceBorderLightRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_up),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPCS(
                                          provider.currentPCS + provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 55,
                                  child: IconButton.filled(
                                    icon: Icon(Icons.arrow_drop_down),
                                    iconSize: 36,
                                    color: scaffoldBackgroundColor,
                                    onPressed: () async {
                                      await provider.setPCS(
                                          provider.currentPCS - provider.step);
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 55,
                    child: PowerSourceKnob(
                      maxValue: 330,
                      pin: Pin.pcs,
                    ),
                  )
                ],
              ),
            ),
          ];
          return Stack(
            children: [
              CommonScaffold(
                title: appLocalizations.powerSourceTitle,
                key: const Key(powerSourceScreenTitleKey),
                body: ScrollConfiguration(
                  behavior: ScrollBehavior(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return constraints.maxWidth < 600
                          ? ListView(
                              children: powerSourceCards,
                            )
                          : GridView(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.5,
                              ),
                              children: powerSourceCards,
                            );
                    },
                  ),
                ),
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.powerSource,
                  content: _getPowerSourceContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }
}
