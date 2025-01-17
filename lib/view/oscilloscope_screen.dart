import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/channel_parameters_widget.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/data_analysis_widget.dart';
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

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OscilloscopeStateProvider()),
      ],
      child: SafeArea(
        child: CommonScaffold(
          title: 'Oscilloscope',
          body: Container(
            margin: const EdgeInsets.only(left: 5, top: 5),
            child: Row(
              children: [
                Container(
                  width: 310.w,
                  margin: const EdgeInsets.only(right: 5),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 380.h,
                        child: LineChart(
                          LineChartData(
                            backgroundColor: Colors.black,
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Consumer<OscilloscopeStateProvider>(
                          builder: (context, provider, _) {
                            switch (provider.selectedIndex) {
                              case 0:
                                return const ChannelParametersWidget();
                              case 1:
                                return const TimebaseTriggerWidget();
                              case 2:
                                return const DataAnalysisWidget(); // Replace with your widget for Tab 3
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
                const Expanded(
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
