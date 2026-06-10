import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/sensor_controls.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/logger_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/mpu6050_state_provider.dart';
import '../theme/colors.dart';
import 'widgets/sensor_chart_widget.dart';
import '../models/chart_data_points.dart';

class MPU6050Screen extends StatefulWidget {
  const MPU6050Screen({super.key});

  @override
  State<MPU6050Screen> createState() => _MPU6050ScreenState();
}

class _MPU6050ScreenState extends State<MPU6050Screen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  I2C? _i2c;
  ScienceLab? _scienceLab;
  late MPU6050Provider _provider;

  String _selectedAccelAxis = 'X';
  String _selectedGyroAxis = 'X';

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
      create: (_) {
        _provider = MPU6050Provider()
          ..initializeSensors(
            onError: _showSnackbar,
            i2c: _i2c,
            scienceLab: _scienceLab,
          );
        return _provider;
      },
      child: Consumer<MPU6050Provider>(
        builder: (context, provider, child) {
          return CommonScaffold(
            title: appLocalizations.mpu6050,
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
                        _buildDynamicChart(
                          title: appLocalizations.accelerometer,
                          selectedAxis: _selectedAccelAxis,
                          onAxisChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedAccelAxis = val);
                            }
                          },
                          dataList: _getAccelDataForAxis(
                              provider, _selectedAccelAxis),
                          lineColor: _getColorForAxis(_selectedAccelAxis),
                          unit: 'g',
                          yAxisLabel: appLocalizations.acceleration,
                          provider: provider,
                        ),
                        const SizedBox(height: 20),
                        _buildDynamicChart(
                          title: appLocalizations.gyroscope,
                          selectedAxis: _selectedGyroAxis,
                          onAxisChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedGyroAxis = val);
                            }
                          },
                          dataList:
                              _getGyroDataForAxis(provider, _selectedGyroAxis),
                          lineColor: _getColorForAxis(_selectedGyroAxis),
                          unit: '°/s',
                          yAxisLabel: appLocalizations.angularVelocity,
                          provider: provider,
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

  Widget _buildDynamicChart({
    required String title,
    required String selectedAxis,
    required Function(String?) onAxisChanged,
    required List<ChartDataPoint> dataList,
    required Color lineColor,
    required String unit,
    required String yAxisLabel,
    required MPU6050Provider provider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title Axis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedAxis,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.black54),
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    items: ['X', 'Y', 'Z'].map((axis) {
                      return DropdownMenuItem(value: axis, child: Text(axis));
                    }).toList(),
                    onChanged: onAxisChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        SensorChartWidget(
          title: '$title $selectedAxis',
          yAxisLabel: yAxisLabel,
          data: dataList,
          lineColor: lineColor,
          unit: unit,
          maxDataPoints: provider.numberOfReadings,
          showDots: true,
        ),
      ],
    );
  }

  List<ChartDataPoint> _getAccelDataForAxis(
      MPU6050Provider provider, String axis) {
    switch (axis) {
      case 'Y':
        return provider.ayData;
      case 'Z':
        return provider.azData;
      case 'X':
      default:
        return provider.axData;
    }
  }

  List<ChartDataPoint> _getGyroDataForAxis(
      MPU6050Provider provider, String axis) {
    switch (axis) {
      case 'Y':
        return provider.gyData;
      case 'Z':
        return provider.gzData;
      case 'X':
      default:
        return provider.gxData;
    }
  }

  Color _getColorForAxis(String axis) {
    switch (axis) {
      case 'Y':
        return Colors.green;
      case 'Z':
        return Colors.red;
      case 'X':
      default:
        return Colors.blue;
    }
  }

  Widget _buildRawDataSection(MPU6050Provider provider) {
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
                        color: appBarContentColor, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        appLocalizations.gyroRange,
                        provider.selectedGyroRange,
                        [250, 500, 1000, 2000]
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e.toString())))
                            .toList(),
                        (val) => provider.updateGyroRange(val as int),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        appLocalizations.accelerationRange,
                        provider.selectedAccelRange,
                        [2, 4, 8, 16]
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e.toString())))
                            .toList(),
                        (val) => provider.updateAccelRange(val as int),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),
                Row(
                  children: [
                    Expanded(
                        child: _buildDataRow('Ax',
                            provider.currentValues['ax']!.toStringAsFixed(2))),
                    Expanded(
                        child: _buildDataRow('Ay',
                            provider.currentValues['ay']!.toStringAsFixed(2))),
                    Expanded(
                        child: _buildDataRow('Az',
                            provider.currentValues['az']!.toStringAsFixed(2))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildDataRow('Gx',
                            provider.currentValues['gx']!.toStringAsFixed(2))),
                    Expanded(
                        child: _buildDataRow('Gy',
                            provider.currentValues['gy']!.toStringAsFixed(2))),
                    Expanded(
                        child: _buildDataRow('Gz',
                            provider.currentValues['gz']!.toStringAsFixed(2))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildDataRow(
                            appLocalizations.temp,
                            provider.currentValues['temperature']!
                                .toStringAsFixed(2))),
                    const Expanded(flex: 2, child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, dynamic currentValue,
      List<DropdownMenuItem<dynamic>> items, Function(dynamic) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              isExpanded: true,
              value: currentValue,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
