import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/channel_parameters_widget.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/data_analysis_widget.dart';
import 'package:pslab/view/widgets/measurements_list.dart';
import 'package:pslab/view/widgets/oscilloscope_graph.dart';
import 'package:pslab/view/widgets/oscilloscope_screen_tabs.dart';
import 'package:pslab/view/widgets/timebase_trigger_widget.dart';
import 'package:pslab/view/widgets/xyplot_widget.dart';

import '../providers/oscilloscope_state_provider.dart';

class OscilloscopeScreen extends StatefulWidget {
  final String icRecord = 'assets/icons/ic_record_white.png';
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
      child: Consumer<OscilloscopeStateProvider>(
        builder: (context, provider, _) {
          return CommonScaffold(
            title: 'Oscilloscope',
            body: SafeArea(
              minimum: const EdgeInsets.only(right: 0, bottom: 0),
              child: Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                child: Row(
                  children: [
                    Expanded(
                      flex: 87,
                      child: Container(
                        margin: const EdgeInsets.only(right: 5),
                        child: Stack(
                          children: [
                            Column(
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
                                  child:
                                      Selector<OscilloscopeStateProvider, int>(
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
                            provider.isMeasurementsChecked
                                ? Positioned(
                                    right: 0,
                                    top: 0,
                                    child: SizedBox(
                                        width: 135,
                                        child: MeasurementsList(
                                            dataParamsChannels:
                                                provider.dataParamsChannels)),
                                  )
                                : const SizedBox.shrink(),
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
            actions: [
              TextButton(
                onPressed: () {
                  if ((((provider.isCH1Selected ||
                                  provider.isCH2Selected ||
                                  provider.isCH3Selected ||
                                  provider.isMICSelected) &&
                              getIt<ScienceLab>().isConnected()) ||
                          provider.isInBuiltMICSelected) &&
                      !provider.autoScale()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(noSignal),
                      ),
                    );
                  }
                },
                child: Text(autoScale,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              IconButton(
                icon: provider.isRunning
                    ? const Icon(
                        Icons.pause,
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                onPressed: () {
                  if (provider.isRunning) {
                    provider.isRunning = false;
                  } else {
                    provider.isRunning = true;
                  }
                  setState(
                    () {},
                  );
                },
              ),
              IconButton(
                icon: Image.asset(
                  widget.icRecord,
                  width: 24,
                  height: 24,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.info, color: Colors.white),
                onPressed: () {},
              ),
              PopupMenuButton<CheckboxListTile>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {},
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<CheckboxListTile>(
                    child: CheckboxListTile(
                      title: Text(automatedMeasurements),
                      value: provider.isMeasurementsChecked,
                      onChanged: (bool? newValue) {
                        setState(() {
                          provider.isMeasurementsChecked = newValue ?? false;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
