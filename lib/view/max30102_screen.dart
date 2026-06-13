import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/sensor_controls.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/logger_service.dart';
import '../l10n/app_localizations.dart';
import 'widgets/sensor_chart_widget.dart';
import '../providers/max30102_provider.dart';
import '../theme/colors.dart';

class MAX30102Screen extends StatefulWidget {
  const MAX30102Screen({super.key});

  @override
  State<MAX30102Screen> createState() => _MAX30102ScreenState();
}

class _MAX30102ScreenState extends State<MAX30102Screen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  String sensorImage = 'assets/images/max30102.png';

  I2C? _i2c;
  ScienceLab? _scienceLab;
  late MAX30102Provider _provider;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _showSuccessSnackbar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            duration: const Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        _provider = MAX30102Provider()
          ..initializeSensors(
            onError: _showSensorErrorSnackbar,
            i2c: _i2c,
            scienceLab: _scienceLab,
          );
        return _provider;
      },
      child: Consumer<MAX30102Provider>(
        builder: (context, provider, child) {
          return CommonScaffold(
            title: appLocalizations.max30102,
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
                              '${appLocalizations.plot} - ${appLocalizations.estBMP}',
                          yAxisLabel: appLocalizations.estBMP,
                          data: provider.bpmData,
                          lineColor: Colors.red,
                          unit: appLocalizations.estBMP,
                          maxDataPoints: provider.numberOfReadings,
                          showDots: true,
                        ),
                        const SizedBox(height: 20),
                        SensorChartWidget(
                          title:
                              '${appLocalizations.plot} - ${appLocalizations.estSpo2}',
                          yAxisLabel: appLocalizations.estSpo2,
                          data: provider.spo2Data,
                          lineColor: Colors.green,
                          unit: appLocalizations.percentage,
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

  Widget _buildRawDataSection(MAX30102Provider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: primaryRed,
            ),
            child: Row(
              children: [
                Text(
                  appLocalizations.metrics,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (provider.isRunning)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildDataCard(
                            appLocalizations.estBMP,
                            provider.calculatedBPM > 0
                                ? '${provider.calculatedBPM}'
                                : '--',
                          ),
                          const SizedBox(height: 16),
                          _buildDataCard(
                            appLocalizations.estSpo2,
                            provider.calculatedSpO2 > 0
                                ? '${provider.calculatedSpO2}${appLocalizations.percentage}'
                                : '--',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          color: Colors.white,
                          child: Image.asset(
                            sensorImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  appLocalizations.imgMissing,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    appLocalizations.adcEstimateLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
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
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(0),
              color: Colors.white,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
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
