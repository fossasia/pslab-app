import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/luxmeter_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/luxmeter_card.dart';

class LuxMeterScreen extends StatefulWidget {
  const LuxMeterScreen({super.key});
  @override
  State<StatefulWidget> createState() => _LuxMeterScreenState();
}

class _LuxMeterScreenState extends State<LuxMeterScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LuxMeterStateProvider>(
          create: (_) => LuxMeterStateProvider()..initializeSensors(),
        ),
      ],
      child: CommonScaffold(
        title: luxMeterTitle,
        body: const SafeArea(
          child: LuxMeterCard(),
        ),
      ),
    );
  }
}
