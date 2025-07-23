import 'package:flutter/widgets.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';

class WaveGeneratorScreen extends StatefulWidget {
  const WaveGeneratorScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WaveGeneratorScreenState();
}

class _WaveGeneratorScreenState extends State<WaveGeneratorScreen> {
  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Wave Generator',
      body: Container(),
    );
  }
}
