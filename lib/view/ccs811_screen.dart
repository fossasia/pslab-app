import 'dart:async';

import 'package:intl/intl.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pslab/others/csv_service.dart';

import '../others/logger_service.dart';
import '../providers/ccs811_config_provider.dart';
import '../providers/ccs811_provider.dart';

class CCS811Screen extends StatefulWidget {
  const CCS811Screen({super.key});

  @override
  State<StatefulWidget> createState() => _CCS811ScreenState();
}

class _CCS811ScreenState extends State<CCS811Screen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final CsvService _csvService = CsvService();
  late CCS811Provider _provider;

  I2C? _i2c;
  ScienceLab? _scienceLab;
  CCS811ConfigProvider? _configProvider;

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
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_provider.isRecording) {
      final data = _provider.getRecordedData();
      _provider.stopRecording();
      await _showSaveFileDialog(data);
    } else {
      await _provider.startRecording();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appLocalizations.recordingStarted}...',
            style: TextStyle(color: snackBarContentColor),
          ),
          backgroundColor: snackBarBackgroundColor,
        ),
      );
    }
  }

  Future<void> _showSaveFileDialog(List<List<dynamic>> data) async {
    final TextEditingController filenameController = TextEditingController();
    final String defaultFilename =
        '${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv';
    filenameController.text = defaultFilename;

    final String? fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocalizations.saveRecording),
          content: TextField(
            controller: filenameController,
            decoration: InputDecoration(
              hintText: appLocalizations.enterFileName,
              labelText: appLocalizations.fileName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, filenameController.text);
              },
              child: Text(appLocalizations.save),
            ),
          ],
        );
      },
    );

    if (fileName != null) {
      _csvService.writeMetaData("ccs811", data);
      final file = await _csvService.saveCsvFile("ccs811", fileName, data);
      if (mounted) {
        if (file != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${appLocalizations.fileSaved}: ${file.path.split('/').last}',
                style: TextStyle(color: snackBarContentColor),
              ),
              backgroundColor: snackBarBackgroundColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appLocalizations.failedToSave,
                style: TextStyle(color: snackBarContentColor),
              ),
              backgroundColor: snackBarBackgroundColor,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CCS811ConfigProvider>(
          create: (_) {
            _configProvider = CCS811ConfigProvider();
            return _configProvider!;
          },
        ),
        ChangeNotifierProxyProvider<CCS811ConfigProvider, CCS811Provider>(
          create: (context) {
            final configProvider =
                Provider.of<CCS811ConfigProvider>(context, listen: false);
            _provider = CCS811Provider(configProvider);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _provider.initializeSensors(
                  onError: _showSensorErrorSnackbar,
                  i2c: _i2c,
                  scienceLab: _scienceLab,
                );
              }
            });
            return _provider;
          },
          update: (context, configProvider, previous) {
            return previous!;
          },
        ),
      ],
      child: Consumer<CCS811Provider>(
        builder: (context, provider, child) {
          return CommonScaffold(
            title: "CCS811 Air Quality",
            onRecordPressed: _toggleRecording,
            isRecording: provider.isRecording,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Value Cards
                    Row(
                      children: [
                        Expanded(
                            child: _buildValueCard(
                                "eCO2", "${provider.currentECO2}", "ppm")),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildValueCard(
                                "TVOC", "${provider.currentTVOC}", "ppb")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Charts
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                              child: _buildChart(provider.getECO2ChartData(),
                                  "eCO2 (ppm)", Colors.green)),
                          const SizedBox(height: 8),
                          Expanded(
                              child: _buildChart(provider.getTVOCChartData(),
                                  "TVOC (ppb)", Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildValueCard(String title, String value, String unit) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryRed)),
            Text(unit,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> spots, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: chartBackgroundColor,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xff37434d), width: 1)),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
