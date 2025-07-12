import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/providers/accelerometer_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/accelerometer_card.dart';

import '../theme/colors.dart';

class AccelerometerScreen extends StatefulWidget {
  const AccelerometerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AccelerometerScreenState();
}

class _AccelerometerScreenState extends State<AccelerometerScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _showGuide = false;
  static const imagePath = 'assets/images/bh1750_schematic.png';
  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getAccelerometerContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.accelerometerIntro,
      ),
      const InstrumentImage(
        imagePath: imagePath,
      ),
      InstrumentIntroText(
        text: appLocalizations.accelerometerImageDesc,
      ),
      InstrumentIntroText(
        text: appLocalizations.accelerometerSteps,
      ),
      InstrumentBulletPoint(text: appLocalizations.accelerometerBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.accelerometerBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.accelerometerBulletPoint3),
      InstrumentIntroText(text: appLocalizations.accelerometerDesc),
      InstrumentIntroText(text: appLocalizations.accelerometerNote),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AccelerometerStateProvider>(
          create: (_) => AccelerometerStateProvider()..initializeSensors(),
        ),
      ],
      child: Stack(children: [
        CommonScaffold(
            title: appLocalizations.accelerometerTitle,
            onGuidePressed: _showInstrumentGuide,
            body: SafeArea(
                child: Column(
              children: [
                Expanded(
                    child: AccelerometerCard(
                        color: xOrientationChartLineColor,
                        axis: appLocalizations.xAxis)),
                Expanded(
                    child: AccelerometerCard(
                        color: yOrientationChartLineColor,
                        axis: appLocalizations.yAxis)),
                Expanded(
                    child: AccelerometerCard(
                        color: zOrientationChartLineColor,
                        axis: appLocalizations.zAxis)),
              ],
            ))),
        if (_showGuide)
          InstrumentOverviewDrawer(
            instrumentName: appLocalizations.accelerometer,
            content: _getAccelerometerContent(),
            onHide: _hideInstrumentGuide,
          ),
      ]),
    );
  }
}
