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
import '../providers/hmc5883l_provider.dart';
import '../communication/sensors/hmc5883l.dart';

class HMC5883LScreen extends StatefulWidget {
  const HMC5883LScreen({super.key});

  @override
  State<HMC5883LScreen> createState() => _HMC5883LScreenState();
}

class _HMC5883LScreenState extends State<HMC5883LScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  String sensorImage = 'assets/images/hmc5883l.jpg';
  I2C? _i2c;
  ScienceLab? _scienceLab;
  late HMC5883LProvider _provider;

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
        _provider = HMC5883LProvider()
          ..initializeSensors(
            onError: _showSensorErrorSnackbar,
            i2c: _i2c,
            scienceLab: _scienceLab,
          );
        return _provider;
      },
      child: Consumer<HMC5883LProvider>(
        builder: (context, provider, child) {
          return CommonScaffold(
            title: 'HMC5883L Magnetometer',
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRawDataSection(provider),
                        const SizedBox(height: 16),
                        _buildCalibrationSection(provider),
                        const SizedBox(height: 24),
                        SensorChartWidget(
                          title: '${appLocalizations.plot} - Magnetic Field X',
                          yAxisLabel: 'Magnetic Field X (µT)',
                          data: provider.magneticXData,
                          lineColor: const Color(0xFFE91E63),
                          unit: 'µT',
                          maxDataPoints: provider.numberOfReadings,
                          showDots: true,
                        ),
                        const SizedBox(height: 20),
                        SensorChartWidget(
                          title: '${appLocalizations.plot} - Magnetic Field Y',
                          yAxisLabel: 'Magnetic Field Y (µT)',
                          data: provider.magneticYData,
                          lineColor: const Color(0xFF2196F3),
                          unit: 'µT',
                          maxDataPoints: provider.numberOfReadings,
                          showDots: true,
                        ),
                        const SizedBox(height: 20),
                        SensorChartWidget(
                          title: '${appLocalizations.plot} - Magnetic Field Z',
                          yAxisLabel: 'Magnetic Field Z (µT)',
                          data: provider.magneticZData,
                          lineColor: const Color(0xFF4CAF50),
                          unit: 'µT',
                          maxDataPoints: provider.numberOfReadings,
                          showDots: true,
                        ),
                        const SizedBox(height: 20),
                        SensorChartWidget(
                          title: '${appLocalizations.plot} - Heading',
                          yAxisLabel: 'Heading (degrees)',
                          data: provider.headingData,
                          lineColor: const Color(0xFFFF9800),
                          unit: '°',
                          maxDataPoints: provider.numberOfReadings,
                          showDots: true,
                        ),
                        const SizedBox(height: 20),
                        SensorChartWidget(
                          title: '${appLocalizations.plot} - Magnitude',
                          yAxisLabel: 'Magnitude (µT)',
                          data: provider.magnitudeData,
                          lineColor: const Color(0xFF9C27B0),
                          unit: 'µT',
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

  Widget _buildRawDataSection(HMC5883LProvider provider) {
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
                        'Magnetic X',
                        '${provider.magneticX.toStringAsFixed(2)} µT',
                      ),
                      const SizedBox(height: 16),
                      _buildDataCard(
                        'Magnetic Y',
                        '${provider.magneticY.toStringAsFixed(2)} µT',
                      ),
                      const SizedBox(height: 16),
                      _buildDataCard(
                        'Magnetic Z',
                        '${provider.magneticZ.toStringAsFixed(2)} µT',
                      ),
                      const SizedBox(height: 16),
                      _buildDataCard(
                        'Heading',
                        '${provider.heading.toStringAsFixed(1)}°',
                      ),
                      const SizedBox(height: 16),
                      _buildDataCard(
                        'Magnitude',
                        '${provider.magnitude.toStringAsFixed(2)} µT',
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
                          Icons.explore,
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

  Widget _buildCalibrationSection(HMC5883LProvider provider) {
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
                  'Calibration',
                  style: TextStyle(
                    color: appBarContentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (provider.isCalibrating)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.isCalibrating
                      ? 'Move the sensor in a figure-8 pattern to calibrate...'
                      : 'Tap the button below to start calibration',
                  style: TextStyle(
                    fontSize: 14,
                    color: blackTextColor.withAlpha(180),
                  ),
                ),
                if (provider.isCalibrating) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(100)),
                    ),
                    child: Text(
                      provider.getCalibrationStatus(),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: blackTextColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (provider.isCalibrating) {
                            provider.stopCalibration();
                            _showSuccessSnackbar('Calibration completed');
                          } else {
                            provider.startCalibration();
                            _showSuccessSnackbar('Calibration started');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: provider.isCalibrating
                              ? Colors.orange
                              : primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          provider.isCalibrating
                              ? 'Stop Calibration'
                              : 'Start Calibration',
                          style: TextStyle(
                            color: appBarContentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _showGainDialog(provider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Set Gain',
                          style: TextStyle(
                            color: appBarContentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGainDialog(HMC5883LProvider provider) {
    final gains = {
      'Gain 1370 (±0.88 Ga)': HMC5883L.gain1370,
      'Gain 1090 (±1.3 Ga) - Default': HMC5883L.gain1090,
      'Gain 820 (±1.9 Ga)': HMC5883L.gain820,
      'Gain 660 (±2.5 Ga)': HMC5883L.gain660,
      'Gain 440 (±4.0 Ga)': HMC5883L.gain440,
      'Gain 390 (±4.7 Ga)': HMC5883L.gain390,
      'Gain 330 (±5.6 Ga)': HMC5883L.gain330,
      'Gain 230 (±8.1 Ga)': HMC5883L.gain230,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Gain'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: gains.entries.map((entry) {
            return ListTile(
              title: Text(entry.key),
              onTap: () {
                provider.setGain(entry.value);
                Navigator.pop(context);
                _showSuccessSnackbar('Gain set to ${entry.key}');
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
