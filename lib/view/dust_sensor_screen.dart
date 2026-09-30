import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/dust_sensor_state_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/dust_sensor_card.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/instruments_graph.dart';

class DustSensorScreen extends StatefulWidget {
  final DustSensorStateProvider? provider;

  const DustSensorScreen({super.key, this.provider});

  @override
  State<DustSensorScreen> createState() => _DustSensorScreenState();
}

class _DustSensorScreenState extends State<DustSensorScreen> {
  late final DustSensorStateProvider _provider;
  bool _showGuide = false;

  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? DustSensorStateProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.initialize());
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  List<Widget> _guideContent() => [
        InstrumentIntroText(text: appLocalizations.dustSensorGuideIntro),
        const SizedBox(height: 12),
        InstrumentIntroText(text: appLocalizations.dustSensorGuideMeasurement),
        const SizedBox(height: 16),
        Text(
          appLocalizations.dustSensorGuideWiringTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        InstrumentBulletPoint(text: appLocalizations.dustSensorGuideWiringVcc),
        InstrumentBulletPoint(text: appLocalizations.dustSensorGuideWiringGnd),
        InstrumentBulletPoint(
            text: appLocalizations.dustSensorGuideWiringSignal),
        const SizedBox(height: 12),
        InstrumentIntroText(text: appLocalizations.dustSensorGuideCalibration),
        InstrumentIntroText(
            text: appLocalizations.dustSensorGuideTroubleshooting),
        InstrumentCompatibilitySection(
          pslabRequired: true,
          note: appLocalizations.dustSensorCompatibility,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Stack(
        children: [
          CommonScaffold(
            title: appLocalizations.dustSensor,
            onGuidePressed: () => setState(() => _showGuide = true),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final card = const DustSensorCard();
                  final chart = Consumer<DustSensorStateProvider>(
                    builder: (context, provider, _) => InstrumentsGraph(
                      spots: provider.chartData,
                      minX: provider.minTime,
                      maxX: provider.maxTime,
                      timeInterval: provider.timeInterval,
                      minY: 0,
                      maxY: 5,
                      yInterval: 1,
                      xAxisLabel: appLocalizations.timeAxisLabel,
                      yAxisLabel: appLocalizations.dustSensorVoltageAxis,
                    ),
                  );

                  if (constraints.maxWidth > 900) {
                    return Row(
                      children: [
                        Expanded(flex: 40, child: card),
                        Expanded(flex: 60, child: chart),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(flex: 58, child: card),
                      Expanded(flex: 42, child: chart),
                    ],
                  );
                },
              ),
            ),
          ),
          if (_showGuide)
            InstrumentOverviewDrawer(
              instrumentName: appLocalizations.dustSensor,
              content: _guideContent(),
              onHide: () => setState(() => _showGuide = false),
            ),
        ],
      ),
    );
  }
}
