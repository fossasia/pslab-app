import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/channel_parameters_widget.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/data_analysis_widget.dart';
import 'package:pslab/view/widgets/oscilloscope_graph.dart';
import 'package:pslab/view/widgets/oscilloscope_screen_tabs.dart';
import 'package:pslab/view/widgets/timebase_trigger_widget.dart';
import 'package:pslab/view/widgets/xyplot_widget.dart';

import '../providers/oscilloscope_state_provider.dart';

class OscilloscopeScreen extends StatefulWidget {
  const OscilloscopeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _OscilloscopeScreenState();
}

class _OscilloscopeScreenState extends State<OscilloscopeScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
    super.initState();
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _setPortraitOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OscilloscopeStateProvider>(
          create: (_) => OscilloscopeStateProvider(),
        ),
      ],
      child: SafeArea(
        child: CommonScaffold(
          title: 'Oscilloscope',
          body: Container(
            margin: const EdgeInsets.only(left: 5, top: 5),
            child: Row(
              children: [
                Expanded(
                  flex: 87,
                  child: Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 66,
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 20),
                            color: Colors.black,
                            child: const OscilloscopeGraph(),
                          ),
                        ),
                        Expanded(
                          flex: 34,
                          child: Selector<OscilloscopeStateProvider, int>(
                            selector: (context, provider) =>
                                provider.selectedIndex,
                            builder: (context, selectedIndex, _) {
                              switch (selectedIndex) {
                                case 0:
                                  return const ChannelParametersWidget();
                                case 1:
                                  return const TimebaseTriggerWidget();
                                case 2:
                                  return const DataAnalysisWidget();
                                case 3:
                                  return const XYPlotWidget();
                                default:
                                  return const ChannelParametersWidget();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  flex: 13,
                  child: OscilloscopeScreenTabs(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
