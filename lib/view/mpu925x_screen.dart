import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/sensor_controls.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/logger_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/mpu925x_provider.dart';
import '../theme/colors.dart';
import 'widgets/sensor_chart_widget.dart';

class MPU925XScreen extends StatefulWidget {
  const MPU925XScreen({super.key});

  @override
  State<MPU925XScreen> createState() => _MPU925XScreenState();
}

class _MPU925XScreenState extends State<MPU925XScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  I2C? _i2c;
  ScienceLab? _scienceLab;
  late MPU925XProvider _provider;

  @override
  void initState() {
    super.initState();
    _initializeScienceLab();
  }

  void _initializeScienceLab() {
    try {
      _scienceLab = getIt.get<ScienceLab>();
      if (_scienceLab != null && _scienceLab!.isConnected()) {
        _i2c = I2C(_scienceLab!.mPacketHandler);
      }
    } catch (e) {
      logger.e('Error initializing ScienceLab: $e');
    }
  }

  void _showSnackbar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        _provider = MPU925XProvider()
          ..initializeSensors(
            onError: _showSnackbar,
            i2c: _i2c,
            scienceLab: _scienceLab,
          );
        return _provider;
      },
      child: Consumer<MPU925XProvider>(
        builder: (context, provider, child) {
          return CommonScaffold(
            title: appLocalizations.mpu925x,
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
                              "${appLocalizations.plot} - ${appLocalizations.accelerometer}",
                          yAxisLabel: appLocalizations.acceleration,
                          unit: "g",
                          data: provider.axData,
                          lineColor: Colors.blue,
                          data2: provider.ayData,
                          lineColor2: Colors.green,
                          data3: provider.azData,
                          lineColor3: Colors.red,
                          maxDataPoints: provider.numberOfReadings,
                          showDots: false,
                        ),
                        const SizedBox(height: 20),
                        SensorChartWidget(
                          title:
                              "${appLocalizations.plot} - ${appLocalizations.gyroscope}",
                          yAxisLabel: "Angle",
                          unit: "rad/s",
                          data: provider.gxData,
                          lineColor: Colors.blue,
                          data2: provider.gyData,
                          lineColor2: Colors.green,
                          data3: provider.gzData,
                          lineColor3: Colors.red,
                          maxDataPoints: provider.numberOfReadings,
                          showDots: false,
                        ),
                        const SizedBox(height: 20),
                        SensorChartWidget(
                          title:
                              "${appLocalizations.plot} - ${appLocalizations.magnetometer}",
                          yAxisLabel: "Magnetic Field",
                          unit: "µT",
                          data: provider.mxData,
                          lineColor: Colors.blue,
                          data2: provider.myData,
                          lineColor2: Colors.green,
                          data3: provider.mzData,
                          lineColor3: Colors.red,
                          maxDataPoints: provider.numberOfReadings,
                          showDots: false,
                        ),
                        const SizedBox(height: 24),
                        _buildConfigSection(provider),
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
                    _showSnackbar(appLocalizations.dataCleared);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRawDataSection(MPU925XProvider provider) {
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAccelColumn(provider)),
                const SizedBox(width: 8),
                Expanded(child: _buildGyroColumn(provider)),
                const SizedBox(width: 8),
                Expanded(child: _buildMagColumn(provider)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(MPU925XProvider provider) {
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
            color: primaryRed,
            child: Text(
              "Configuration",
              style: TextStyle(
                color: appBarContentColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildGyroDropdown(provider),
                const SizedBox(height: 16),
                _buildAccelDropdown(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccelColumn(MPU925XProvider provider) {
    return Column(
      children: [
        _buildDataCard("Ax", provider.currentValues['ax']!),
        const SizedBox(height: 16),
        _buildDataCard("Ay", provider.currentValues['ay']!),
        const SizedBox(height: 16),
        _buildDataCard("Az", provider.currentValues['az']!),
        const SizedBox(height: 16),
        _buildDataCard("Temp", provider.currentValues['temperature']!),
      ],
    );
  }

  Widget _buildGyroColumn(MPU925XProvider provider) {
    return Column(
      children: [
        _buildDataCard("Gx", provider.currentValues['gx']!),
        const SizedBox(height: 16),
        _buildDataCard("Gy", provider.currentValues['gy']!),
        const SizedBox(height: 16),
        _buildDataCard("Gz", provider.currentValues['gz']!),
      ],
    );
  }

  Widget _buildMagColumn(MPU925XProvider provider) {
    return Column(
      children: [
        _buildDataCard("Mx", provider.currentValues['mx']!),
        const SizedBox(height: 16),
        _buildDataCard("My", provider.currentValues['my']!),
        const SizedBox(height: 16),
        _buildDataCard("Mz", provider.currentValues['mz']!),
      ],
    );
  }

  Widget _buildDataCard(String label, double value) {
    return Row(
      children: [
        SizedBox(
          width: 40,
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: sensorControlsTextBox),
              borderRadius: BorderRadius.circular(4),
              color: cardBackgroundColor,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(fontSize: 13, color: blackTextColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGyroDropdown(MPU925XProvider provider) {
    return _buildDropdownCard(
      "Gyro Range",
      provider.selectedGyroRange,
      [250, 500, 1000, 2000]
          .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
          .toList(),
      (val) => provider.updateGyroRange(val as int),
    );
  }

  Widget _buildAccelDropdown(MPU925XProvider provider) {
    return _buildDropdownCard(
      "Accel Range",
      provider.selectedAccelRange,
      [2, 4, 8, 16]
          .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
          .toList(),
      (val) => provider.updateAccelRange(val as int),
    );
  }

  Widget _buildDropdownCard(String label, dynamic currentValue,
      List<DropdownMenuItem<dynamic>> items, Function(dynamic) onChanged) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: blackTextColor),
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
              child: DropdownButton<dynamic>(
                isExpanded: true,
                value: currentValue,
                items: items,
                onChanged: onChanged,
                style: TextStyle(fontSize: 14, color: blackTextColor),
                icon: Icon(Icons.arrow_drop_down, color: blackTextColor),
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
