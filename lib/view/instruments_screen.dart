import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/applications_list_item.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});
  @override
  State<StatefulWidget> createState() => _InstrumentsScreenState();
}

class _InstrumentData {
  final String heading;
  final String description;
  final String name;

  _InstrumentData(this.heading, this.description, this.name);
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  List<int> _filteredIndices = <int>[];
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late List<_InstrumentData> _instrumentDatas;

  void _onItemTapped(int index) {
    _InstrumentData instrument = _instrumentDatas[index];

    if (Navigator.canPop(context) &&
        ModalRoute.of(context)?.settings.name == instrument.name) {
      Navigator.popUntil(context, ModalRoute.withName(instrument.name));
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        instrument.name,
        (route) => route.isFirst,
      );
    }
  }

  void _filterInstruments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIndices =
            List<int>.generate(_instrumentDatas.length, (index) => index);
      } else {
        _filteredIndices = List.generate(_instrumentDatas.length, (i) => i)
            .where((i) => _instrumentDatas[i]
                .heading
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getIt.get<BoardStateProvider>().legacyFirmwareNotifier.addListener(() {
      if (getIt.get<BoardStateProvider>().legacyFirmwareNotifier.value ==
          "LegacyFirmwareDetected") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: const Icon(Icons.warning),
                title: Text(appLocalizations.legacyFirmwareAlertTitle),
                content: Text(appLocalizations.legacyFirmwareAlertMessage),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(appLocalizations.ok),
                  ),
                ],
              );
            },
          );
        });
      }
    });

    _instrumentDatas = [
      _InstrumentData(appLocalizations.oscilloscope,
          appLocalizations.oscilloscopeDesc, '/oscilloscope'),
      _InstrumentData(appLocalizations.multimeter,
          appLocalizations.multimeterDesc, '/multimeter'),
      _InstrumentData(appLocalizations.logicAnalyzer,
          appLocalizations.logicAnalyzerDesc, '/logicAnalyzer'),
      _InstrumentData(
          appLocalizations.sensors, appLocalizations.sensorsDesc, '/sensors'),
      _InstrumentData(appLocalizations.waveGenerator,
          appLocalizations.waveGeneratorDesc, '/waveGenerator'),
      _InstrumentData(appLocalizations.powerSource,
          appLocalizations.powerSourceDesc, '/powerSource'),
      _InstrumentData(appLocalizations.luxMeter, appLocalizations.luxMeterDesc,
          '/luxmeter'),
      _InstrumentData(appLocalizations.accelerometer,
          appLocalizations.accelerometerDesc, '/accelerometer'),
      _InstrumentData(appLocalizations.barometer,
          appLocalizations.barometerDesc, '/barometer'),
      _InstrumentData(
          appLocalizations.compass, appLocalizations.compassDesc, '/compass'),
      _InstrumentData(appLocalizations.gyroscope,
          appLocalizations.gyroscopeDesc, '/gyroscope'),
      _InstrumentData(appLocalizations.thermometer,
          appLocalizations.thermometerDesc, '/thermometer'),
      _InstrumentData(appLocalizations.roboticArm,
          appLocalizations.roboticArmDesc, '/roboticArm'),
      // Instruments below are not yet implemented.
      //_InstrumentData(appLocalizations.gasSensor, appLocalizations.gasSensorDesc, '/gassensor'),
      //_InstrumentData(appLocalizations.dustSensor, appLocalizations.dustSensorDesc, '/dustsensor'),
      _InstrumentData(appLocalizations.soundMeter,
          appLocalizations.soundMeterDesc, '/soundmeter'),
    ];

    _filteredIndices =
        List<int>.generate(_instrumentDatas.length, (index) => index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setPortraitOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void didChangeDependencies() {
    _setPortraitOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 0,
      scaffoldKey: const Key(instrumentsScreenTitleKey),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return constraints.maxWidth < constraints.maxHeight
                        ? ListView.builder(
                            itemCount: _filteredIndices.length,
                            itemBuilder: (context, index) {
                              final int originalIndex = _filteredIndices[index];
                              return GestureDetector(
                                onTap: () => _onItemTapped(originalIndex),
                                child: ApplicationsListItem(
                                  heading: _instrumentDatas[originalIndex]
                                      .heading
                                      .toUpperCase(),
                                  description: _instrumentDatas[originalIndex]
                                      .description,
                                  instrumentIcon:
                                      instrumentIcons[originalIndex],
                                ),
                              );
                            },
                          )
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: _filteredIndices.length,
                            itemBuilder: (context, index) {
                              final int originalIndex = _filteredIndices[index];
                              return GestureDetector(
                                onTap: () => _onItemTapped(originalIndex),
                                child: ApplicationsListItem(
                                  heading: _instrumentDatas[originalIndex]
                                      .heading
                                      .toUpperCase(),
                                  description: _instrumentDatas[originalIndex]
                                      .description,
                                  instrumentIcon:
                                      instrumentIcons[originalIndex],
                                ),
                              );
                            },
                          );
                  },
                ),
              ),
      ),
    );
  }
}
