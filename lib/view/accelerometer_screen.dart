import 'package:flutter/material.dart';
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
    return const CommonScaffold(
        title: 'Accelerometer',
        body: SafeArea(
            child: Column(
          children: [
            Expanded(child: AccelerometerCard(color: Colors.yellow, axis: 'x')),
            Expanded(child: AccelerometerCard(color: Colors.purple, axis: 'y')),
            Expanded(child: AccelerometerCard(color: Colors.green, axis: 'z')),
          ],
        )));
  }
}
