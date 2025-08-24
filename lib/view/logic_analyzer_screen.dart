import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/logic_analyzer_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/logic_analyzer_channel_selection.dart';
import 'package:pslab/view/widgets/logic_analyzer_graph.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

class LogicAnalyzerScreen extends StatefulWidget {
  const LogicAnalyzerScreen({super.key});
  final logicAnalyzerCircuit = 'assets/images/logic_analyzer_circuit.png';

  @override
  State<StatefulWidget> createState() => _LogicAnalyzerScreenState();
}

class _LogicAnalyzerScreenState extends State<LogicAnalyzerScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _showGuide = false;

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getLogicAnalyzerContent() {
    return [
      InstrumentImage(imagePath: widget.logicAnalyzerCircuit),
    ];
  }

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
        ChangeNotifierProvider(
          create: (context) => LogicAnalyzerStateProvider(),
        ),
      ],
      child: Consumer<LogicAnalyzerStateProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              CommonScaffold(
                title: appLocalizations.logicAnalyzerTitle,
                body: SafeArea(
                  minimum: const EdgeInsets.only(right: 0, bottom: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: chartBackgroundColor,
                    ),
                    padding: const EdgeInsets.only(bottom: 5, top: 5),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 73,
                          child: LogicAnalyzerGraph(),
                        ),
                        Expanded(
                          flex: 27,
                          child: LogicAnalyzerChannelSelection(),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.save, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.info, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showGuide = !_showGuide;
                      });
                    },
                  ),
                  IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {}),
                ],
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.logicAnalyzer,
                  content: _getLogicAnalyzerContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }
}
