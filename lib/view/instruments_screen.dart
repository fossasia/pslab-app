import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/applications_list_item.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});
  @override
  State<StatefulWidget> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  List<int> _filteredIndices = <int>[];
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late List<String> instrumentHeadings;
  late List<String> instrumentDesc;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/oscilloscope') {
          Navigator.popUntil(context, ModalRoute.withName('/oscilloscope'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/oscilloscope',
            (route) => route.isFirst,
          );
        }
        break;
      case 1:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/multimeter') {
          Navigator.popUntil(context, ModalRoute.withName('/multimeter'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/multimeter',
            (route) => route.isFirst,
          );
        }
        break;
      case 2:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/logicAnalyzer') {
          Navigator.popUntil(context, ModalRoute.withName('/logicAnalyzer'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/logicAnalyzer',
            (route) => route.isFirst,
          );
        }
        break;
      case 6:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/luxmeter') {
          Navigator.popUntil(context, ModalRoute.withName('/luxmeter'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/luxmeter',
            (route) => route.isFirst,
          );
        }
        break;
      case 7:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/accelerometer') {
          Navigator.popUntil(context, ModalRoute.withName('/accelerometer'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/accelerometer',
            (route) => route.isFirst,
          );
        }
        break;
      case 8:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/barometer') {
          Navigator.popUntil(context, ModalRoute.withName('/barometer'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/barometer',
            (route) => route.isFirst,
          );
        }
        break;
      case 10:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/gyroscope') {
          Navigator.popUntil(context, ModalRoute.withName('/gyroscope'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/gyroscope',
            (route) => route.isFirst,
          );
        }
        break;
      case 12:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/roboticArm') {
          Navigator.popUntil(context, ModalRoute.withName('/roboticArm'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/roboticArm',
            (route) => route.isFirst,
          );
        }
        break;
      case 15:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/soundmeter') {
          Navigator.popUntil(context, ModalRoute.withName('/soundmeter'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/soundmeter',
            (route) => route.isFirst,
          );
        }
        break;
      default:
        break;
    }
  }

  void _filterInstruments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIndices =
            List<int>.generate(instrumentHeadings.length, (index) => index);
      } else {
        _filteredIndices = List.generate(instrumentHeadings.length, (i) => i)
            .where((i) => instrumentHeadings[i]
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    instrumentHeadings = [
      appLocalizations.oscilloscope,
      appLocalizations.multimeter,
      appLocalizations.logicAnalyzer,
      appLocalizations.sensors,
      appLocalizations.waveGenerator,
      appLocalizations.powerSource,
      appLocalizations.luxMeter,
      appLocalizations.accelerometer,
      appLocalizations.barometer,
      appLocalizations.compass,
      appLocalizations.gyroscope,
      appLocalizations.thermometer,
      appLocalizations.roboticArm,
      appLocalizations.gasSensor,
      appLocalizations.dustSensor,
      appLocalizations.soundMeter,
    ];
    instrumentDesc = [
      appLocalizations.oscilloscopeDesc,
      appLocalizations.multimeterDesc,
      appLocalizations.logicAnalyzerDesc,
      appLocalizations.sensorsDesc,
      appLocalizations.waveGeneratorDesc,
      appLocalizations.powerSourceDesc,
      appLocalizations.luxMeterDesc,
      appLocalizations.accelerometerDesc,
      appLocalizations.barometerDesc,
      appLocalizations.compassDesc,
      appLocalizations.gyroscopeDesc,
      appLocalizations.thermometerDesc,
      appLocalizations.roboticArmDesc,
      appLocalizations.gasSensorDesc,
      appLocalizations.dustSensorDesc,
      appLocalizations.soundMeterDesc,
    ];
    _filteredIndices =
        List<int>.generate(instrumentHeadings.length, (index) => index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
    Permission.microphone.request();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 0,
      title: appLocalizations.instrumentsTitle,
      showSearch: true,
      onSearchChanged: _filterInstruments,
      searchHint: appLocalizations.searchInstrumentsHint,
      body: SafeArea(
        child: _filteredIndices.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.noInstrumentsFoundMessage,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(179),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.tryDifferentSearchSuggestion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(128),
                          ),
                    ),
                  ],
                ),
              )
            : ScrollConfiguration(
                behavior: const ScrollBehavior(),
                child: ListView.builder(
                  itemCount: _filteredIndices.length,
                  itemBuilder: (context, index) {
                    final int originalIndex = _filteredIndices[index];
                    return GestureDetector(
                      onTap: () => _onItemTapped(originalIndex),
                      child: ApplicationsListItem(
                        heading: instrumentHeadings[originalIndex],
                        description: instrumentDesc[originalIndex],
                        instrumentIcon: instrumentIcons[originalIndex],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
