import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/accelerometer_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/accelerometer_card.dart';

class AccelerometerScreen extends StatefulWidget {
  const AccelerometerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AccelerometerScreenState();
}

class _AccelerometerScreenState extends State<AccelerometerScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AccelerometerStateProvider>(
          create: (_) => AccelerometerStateProvider()..initializeSensors(),
        ),
      ],
      child: CommonScaffold(
          title: accelerometer,
          body: SafeArea(
              child: Column(
            children: [
              Expanded(
                  child: AccelerometerCard(color: Colors.yellow, axis: xAxis)),
              Expanded(
                  child: AccelerometerCard(color: Colors.purple, axis: yAxis)),
              Expanded(
                  child: AccelerometerCard(color: Colors.green, axis: zAxis)),
            ],
          ))),
    );
  }
}
