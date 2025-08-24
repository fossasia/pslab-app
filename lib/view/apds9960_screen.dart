import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/sensor_controls.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/logger_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'widgets/sensor_chart_widget.dart';
import '../providers/apds9960_provider.dart';

class APDS9960Screen extends StatefulWidget {
  const APDS9960Screen({super.key});

  @override
  State<APDS9960Screen> createState() => _APDS9960ScreenState();
}

class _APDS9960ScreenState extends State<APDS9960Screen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  I2C? _i2c;
  ScienceLab? _scienceLab;
  late APDS9960Provider _provider;

  final List<String> _modeOptions = [
    'Color, Proximity and Ambient Light',
    'Gesture'
  ];

  @override
  void initState() {
    super.initState();
    _initializeScienceLab();
  }

  void _initializeScienceLab() async {
    try {
      _scienceLab = getIt.get<ScienceLab>();
      if (_scienceLab != null && _scienceLab!.isConnected()) {
        _i2c = I2C(_scienceLab!.mPacketHandler);
      }
    } catch (e) {
      logger.e('Error initializing ScienceLab: $e');
    }
  }

  void _showSensorErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: snackBarContentColor),
          ),
          backgroundColor: snackBarBackgroundColor,
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: snackBarContentColor),
          ),
          backgroundColor: snackBarBackgroundColor,
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        _provider = APDS9960Provider()
          ..initializeSensors(
            onError: _showSensorErrorSnackbar,
            i2c: _i2c,
            scienceLab: _scienceLab,
          );
        return _provider;
      },
      child: Consumer<APDS9960Provider>(
        builder: (context, provider, child) {
          return CommonScaffold(
            title: 'APDS9960',
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConfigureSection(provider),
                        const SizedBox(height: 24),
                        _buildRawDataSection(provider),
                        if (provider.mode == 0) ...[
                          const SizedBox(height: 24),
                          SensorChartWidget(
                            title:
                                '${appLocalizations.plot} - ${appLocalizations.light} ${appLocalizations.lux}',
                            yAxisLabel:
                                '${appLocalizations.light} (${appLocalizations.lux})',
                            data: provider.luxData,
                            lineColor: apds9960ChartColors[0],
                            unit: appLocalizations.lx,
                            maxDataPoints: provider.numberOfReadings,
                            showDots: true,
                          ),
                          const SizedBox(height: 20),
                          SensorChartWidget(
                            title:
                                '${appLocalizations.plot} - ${appLocalizations.proximity}',
                            yAxisLabel: appLocalizations.proximity,
                            data: provider.proximityData,
                            lineColor: apds9960ChartColors[1],
                            unit: '',
                            maxDataPoints: provider.numberOfReadings,
                            showDots: true,
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                SensorControlsWidget(
                  isPlaying: provider.isRunning,
                  isLooping: provider.isLooping,
                  timegapMs: provider.timegapMs,
                  numberOfReadings: provider.numberOfReadings,
                  onPlayPause: () {
                    provider.toggleDataCollection();
                  },
                  onLoop: provider.toggleLooping,
                  onTimegapChanged: provider.setTimegap,
                  onNumberOfReadingsChanged: provider.setNumberOfReadings,
                  onClearData: () {
                    provider.clearData();
                    _showSuccessSnackbar(appLocalizations.dataCleared);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfigureSection(APDS9960Provider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: primaryRed,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.zero,
              ),
            ),
            child: Text(
              appLocalizations.configure,
              style: TextStyle(
                color: appBarContentColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  appLocalizations.mode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: blackTextColor,
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: sensorControlsTextBox),
                      borderRadius: BorderRadius.circular(4),
                      color: cardBackgroundColor,
                    ),
                    child: DropdownButton<int>(
                      dropdownColor: cardBackgroundColor,
                      value: provider.mode,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _modeOptions.asMap().entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              color: blackTextColor,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          provider.setMode(value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawDataSection(APDS9960Provider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: primaryRed,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.zero,
              ),
            ),
            child: Row(
              children: [
                Text(
                  appLocalizations.rawData,
                  style: TextStyle(
                    color: appBarContentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (provider.isRunning)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: appBarContentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: provider.mode == 0
                ? _buildColorProximityData(provider)
                : _buildGestureOnlyData(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildColorProximityData(APDS9960Provider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildDataCard(
                          appLocalizations.redLabel, provider.red.toString())),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildDataCard(appLocalizations.proxLabel,
                          provider.proximity.toString())),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildDataCard(appLocalizations.greenLabel,
                          provider.green.toString())),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildDataCard(appLocalizations.blueLabel,
                          provider.blue.toString())),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildDataCard(
                          appLocalizations.clear, provider.clear.toString())),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGestureOnlyData(APDS9960Provider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child:
              _buildDataCard(appLocalizations.gesture, provider.gestureString),
        ),
      ],
    );
  }

  Widget _buildDataCard(String label, String value) {
    return SizedBox(
      height: 50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: blackTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: sensorControlsTextBox),
                borderRadius: BorderRadius.circular(4),
                color: cardBackgroundColor,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: blackTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}
