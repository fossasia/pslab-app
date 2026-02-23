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
import '../providers/ads1115_provider.dart';

class ADS1115Screen extends StatefulWidget {
  const ADS1115Screen({super.key});

  @override
  State<ADS1115Screen> createState() => _ADS1115ScreenState();
}

class _ADS1115ScreenState extends State<ADS1115Screen> {
  AppLocalizations appLocalizations = getIt.get();
  String sensorImage = 'assets/images/ads1115.jpg';

  I2C? _i2c;
  ScienceLab? _scienceLab;
  late ADS1115Provider _provider;

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
          content: Text(message, style: TextStyle(color: snackBarContentColor)),
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
          content: Text(message, style: TextStyle(color: snackBarContentColor)),
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
        _provider = ADS1115Provider()
          ..initializeSensors(
            onError: _showSensorErrorSnackbar,
            i2c: _i2c,
            scienceLab: _scienceLab,
          );
        return _provider;
      },
      child: Consumer<ADS1115Provider>(
        builder: (context, provider, child) {
          return CommonScaffold(
            title: "ADS1115",
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
                              '${appLocalizations.plot} - ${appLocalizations.voltage}',
                          yAxisLabel:
                              '${appLocalizations.voltage} (${appLocalizations.millivolts})',
                          data: provider.voltageData,
                          lineColor: primaryRed,
                          unit: appLocalizations.millivolts,
                          maxDataPoints: provider.numberOfReadings,
                          showDots: true,
                        ),
                        const SizedBox(height: 24),
                        _buildConfigureSection(provider),
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

  Widget _buildRawDataSection(ADS1115Provider provider) {
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
                        appLocalizations.data,
                        provider.voltage.toStringAsFixed(2),
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

  Widget _buildConfigureSection(ADS1115Provider provider) {
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
            child: Column(
              children: [
                _buildConfigRow(
                  appLocalizations.setGain,
                  provider.currentGain,
                  provider.availableGains,
                  provider.setGain,
                ),
                const SizedBox(height: 16),
                _buildConfigRow(
                  appLocalizations.setChannel,
                  provider.currentChannel,
                  provider.availableChannels,
                  provider.setChannel,
                ),
                const SizedBox(height: 16),
                _buildConfigRow(
                  appLocalizations.setRate,
                  provider.currentRate.toString(),
                  provider.availableRates.map((e) => e.toString()).toList(),
                  (String value) => provider.setRate(int.parse(value)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                style: TextStyle(fontSize: 14, color: blackTextColor),
                dropdownColor: cardBackgroundColor,
                items: options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ),
      ],
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
                style: TextStyle(fontSize: 14, color: blackTextColor),
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
