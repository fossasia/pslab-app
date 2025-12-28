import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/sensor_controls.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/logger_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'widgets/sensor_chart_widget.dart';
import '../providers/gas_sensor_provider.dart';

class GasSensorScreen extends StatefulWidget {
  const GasSensorScreen({super.key});

  @override
  State<GasSensorScreen> createState() => _GasSensorScreenState();
}

class _GasSensorScreenState extends State<GasSensorScreen> {
  final AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final String sensorImage = 'assets/images/mq135.jpg';

  ScienceLab? _scienceLab;

  @override
  void initState() {
    super.initState();
    _initializeScienceLab();
  }

  void _initializeScienceLab() {
    try {
      _scienceLab = getIt.get<ScienceLab>();
      if (_scienceLab != null && _scienceLab!.isConnected()) {
        logger.d('ScienceLab connected for Gas Sensor');
      }
    } catch (e) {
      logger.e('Error initializing ScienceLab: $e');
    }
  }

  void _showSensorErrorSnackbar(String message) {
    if (!mounted) return;

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

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GasSensorProvider>(
      create: (_) {
        final provider = GasSensorProvider();
        provider.initializeSensors(
          scienceLab: _scienceLab,
          onError: _showSensorErrorSnackbar,
        );
        return provider;
      },
      child: Consumer<GasSensorProvider>(
        builder: (context, provider, child) {
          return CommonScaffold(
            title: appLocalizations.gasSensor,
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
                              '${appLocalizations.plot} - ${appLocalizations.gasSensor}',
                          yAxisLabel: 'Gas Concentration (PPM)',
                          data: provider.gasPPMData,
                          lineColor: Colors.orange,
                          unit: ' PPM',
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
                  onPlayPause: provider.toggleDataCollection,
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

  Widget _buildRawDataSection(GasSensorProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
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
            color: primaryRed,
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDataCard(
                    'Gas Concentration',
                    '${provider.gasPPM.toStringAsFixed(2)} PPM',
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
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.sensors,
                        size: 40,
                        color: sensorControlsTextBox,
                      ),
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
          width: 120,
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
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: sensorControlsTextBox),
              borderRadius: BorderRadius.circular(4),
              color: cardBackgroundColor,
            ),
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
      ],
    );
  }
}
