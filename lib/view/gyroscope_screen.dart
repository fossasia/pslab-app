import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/gyroscope_state_provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/gyroscope_card.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';

import '../theme/colors.dart';

class GyroscopeScreen extends StatefulWidget {
  const GyroscopeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _GyroscopeScreenState();
}

class _GyroscopeScreenState extends State<GyroscopeScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GyroscopeProvider>(
          create: (_) => GyroscopeProvider()..initializeSensors(),
        ),
      ],
      child: CommonScaffold(
        title: gyroscopeTitle,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GyroscopeCard(
                    color: xOrientationChartLineColor, axis: xAxis),
              ),
              Expanded(
                child: GyroscopeCard(
                    color: yOrientationChartLineColor, axis: yAxis),
              ),
              Expanded(
                child: GyroscopeCard(
                    color: zOrientationChartLineColor, axis: zAxis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
