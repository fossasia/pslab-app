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
import '../providers/sht21_provider.dart';

class SHT21Screen extends StatefulWidget {
  const SHT21Screen({super.key});

  @override
  State<SHT21Screen> createState() => _SHT21ScreenState();
}

class _SHT21ScreenState extends State<SHT21Screen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  String sensorImage = 'assets/images/sht21.jpg';
  I2C? _i2c;
  ScienceLab? _scienceLab;
  late SHT21Provider _provider;

  // Hardcoded strings for SHT21-specific labels (not in l10n yet)
  static const String _sht21Title = 'SHT21';
  static const String _humidityLabel = 'Humidity';
  static const String _humidityUnit = '%';

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
        _provider = SHT21Provider();
        if (_i2c != null) {
          _provider.init(_i2c!);
        } else if (_scienceLab == null || !_scienceLab!.isConnected()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSensorErrorSnackbar(appLocalizations.pslabNotConnected);
          });
        }
        return _provider;
      },
      child: Consumer<SHT21Provider>(
        builder: (context, provider, child) {
          return CommonScaffold(
            title: _sht21Title,
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRawDataSection(provider),
                        const SizedBox(height: 24),
                        SensorChartWidget(
                          title:
                              '${appLocalizations.plot} - ${appLocalizations.temperature}',
                          yAxisLabel:
                              '${appLocalizations.temperature} (${appLocalizations.temperatureUnitLabel})',
                          data: provider.temperatureData,
                          lineColor: sht21ChartColors[0],
                          unit: appLocalizations.temperatureUnitLabel,
                          maxDataPoints: provider.numberOfReadings,
                          showDots: true,
                        ),
                        const SizedBox(height: 20),
                        SensorChartWidget(
                          title: '${appLocalizations.plot} - $_humidityLabel',
                          yAxisLabel: '$_humidityLabel ($_humidityUnit)',
                          data: provider.humidityData,
                          lineColor: sht21ChartColors[1],
                          unit: _humidityUnit,
                          maxDataPoints: provider.numberOfReadings,
                          showDots: true,
                        ),
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

  Widget _buildRawDataSection(SHT21Provider provider) {
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildDataCard(
                        appLocalizations.temperature,
                        provider.temperature.toStringAsFixed(2),
                      ),
                      const SizedBox(height: 16),
                      _buildDataCard(
                        _humidityLabel,
                        provider.humidity.toStringAsFixed(2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      sensorImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.sensors,
                          size: 40,
                          color: sensorControlsTextBox,
                        );
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

  Widget _buildDataCard(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: blackTextColor,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            height: 36,
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
    );
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}
