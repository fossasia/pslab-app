import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/providers/accelerometer_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/accelerometer_card.dart';

import '../providers/accelerometer_config_provider.dart';
import '../theme/colors.dart';
import 'accelerometer_config_screen.dart';

class AccelerometerScreen extends StatefulWidget {
  const AccelerometerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AccelerometerScreenState();
}

class _AccelerometerScreenState extends State<AccelerometerScreen> {
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
        text: accelerometerIntro,
      ),
      const InstrumentImage(
        imagePath: imagePath,
      ),
      InstrumentIntroText(
        text: accelerometerImageDesc,
      ),
      InstrumentIntroText(
        text: accelerometerSteps,
      ),
      InstrumentBulletPoint(text: accelerometerBulletPoint1),
      InstrumentBulletPoint(text: accelerometerBulletPoint2),
      InstrumentBulletPoint(text: accelerometerBulletPoint3),
      InstrumentIntroText(text: accelerometerDesc),
      InstrumentIntroText(text: accelerometerNote),
    ];
  }

  void _showOptionsMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        0,
        0,
        MediaQuery.of(context).size.height,
      ),
      items: [
        PopupMenuItem(
          value: 'show_logged_data',
          child: Text(showLoggedData),
        ),
        PopupMenuItem(
          value: 'accelerometer_config',
          child: Text(accelerometerConfigurations),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            // TODO
            break;
          case 'accelerometer_config':
            _navigateToConfig();
            break;
        }
      }
    });
  }

  void _navigateToConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => AccelerometerConfigProvider(),
          child: const AccelerometerConfigScreen(),
        ),
      ),
    );
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
            title: accelerometer,
            onGuidePressed: _showInstrumentGuide,
            onOptionsPressed: _showOptionsMenu,
            body: SafeArea(
                child: Column(
              children: [
                Expanded(
                    child: AccelerometerCard(
                        color: xOrientationChartLineColor, axis: xAxis)),
                Expanded(
                    child: AccelerometerCard(
                        color: yOrientationChartLineColor, axis: yAxis)),
                Expanded(
                    child: AccelerometerCard(
                        color: zOrientationChartLineColor, axis: zAxis)),
              ],
            ))),
        if (_showGuide)
          InstrumentOverviewDrawer(
            instrumentName: accelerometer,
            content: _getAccelerometerContent(),
            onHide: _hideInstrumentGuide,
          ),
      ]),
    );
  }
}
