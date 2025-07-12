import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/gyroscope_state_provider.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/gyroscope_card.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import '../theme/colors.dart';

class GyroscopeScreen extends StatefulWidget {
  const GyroscopeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _GyroscopeScreenState();
}

class _GyroscopeScreenState extends State<GyroscopeScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _showGuide = false;
  static const imagePath = 'assets/images/gyroscope_axes_orientation.png';
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

  List<Widget> _getGyroscopeContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.gyroscopeIntro,
      ),
      const InstrumentImage(
        imagePath: imagePath,
        height: 200.0,
      ),
      InstrumentIntroText(
        text: appLocalizations.gyroscopeDesc,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GyroscopeProvider>(
          create: (_) => GyroscopeProvider()..initializeSensors(),
        ),
      ],
      child: Stack(children: [
        CommonScaffold(
          title: appLocalizations.gyroscopeTitle,
          onGuidePressed: _showInstrumentGuide,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: GyroscopeCard(
                      color: xOrientationChartLineColor,
                      axis: appLocalizations.xAxis),
                ),
                Expanded(
                  child: GyroscopeCard(
                      color: yOrientationChartLineColor,
                      axis: appLocalizations.yAxis),
                ),
                Expanded(
                  child: GyroscopeCard(
                      color: zOrientationChartLineColor,
                      axis: appLocalizations.zAxis),
                ),
              ],
            ),
          ),
        ),
        if (_showGuide)
          InstrumentOverviewDrawer(
            instrumentName: appLocalizations.gyroscopeTitle,
            content: _getGyroscopeContent(),
            onHide: _hideInstrumentGuide,
          ),
      ]),
    );
  }
}
