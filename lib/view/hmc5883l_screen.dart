import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/sensor_controls.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/others/logger_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../../providers/hmc5883l_provider.dart';

class HMC5883LScreen extends StatefulWidget {
  const HMC5883LScreen({super.key});

  @override
  State<HMC5883LScreen> createState() => _HMC5883LScreenState();
}

class _HMC5883LScreenState extends State<HMC5883LScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
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
            title: appLocalizations.hmc5883l,
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        _buildRawDataCard(provider),
                        _buildPlotCard(provider),
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

  Widget _buildRawDataCard(HMC5883LProvider provider) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Column(
          children: [
            Container(
              height: 40,
              width: double.infinity,
              color: primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                appLocalizations.rawData,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelText('Bx'),
                        const SizedBox(height: 10),
                        _buildLabelText('By'),
                        const SizedBox(height: 10),
                        _buildLabelText('Bz'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Column(
                      children: [
                        _buildValueBox(provider.bx.toStringAsFixed(2)),
                        const SizedBox(height: 10),
                        _buildValueBox(provider.by.toStringAsFixed(2)),
                        const SizedBox(height: 10),
                        _buildValueBox(provider.bz.toStringAsFixed(2)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: Image.asset(
                        sensorImage,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.sensors, size: 50),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlotCard(HMC5883LProvider provider) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: Column(
          children: [
            Container(
              height: 40,
              width: double.infinity,
              color: primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                appLocalizations.plot,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 190,
              margin: const EdgeInsets.only(top: 10),
              color: Colors.black,
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              appLocalizations.gauss,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 20,
                          alignment: Alignment.center,
                          child: Text(
                            appLocalizations.time,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 16.0, bottom: 10.0),
                            child: _buildCombinedChart(provider),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedChart(HMC5883LProvider provider) {
    List<FlSpot> bxSpots =
        provider.bxData.map((data) => FlSpot(data.x, data.y)).toList();
    List<FlSpot> bySpots =
        provider.byData.map((data) => FlSpot(data.x, data.y)).toList();
    List<FlSpot> bzSpots =
        provider.bzData.map((data) => FlSpot(data.x, data.y)).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white24,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.white24,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white30),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: bxSpots.isNotEmpty ? bxSpots : const [FlSpot(0, 0)],
            isCurved: false,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            spots: bySpots.isNotEmpty ? bySpots : const [FlSpot(0, 0)],
            isCurved: false,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            spots: bzSpots.isNotEmpty ? bzSpots : const [FlSpot(0, 0)],
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 0),
    );
  }

  Widget _buildLabelText(String text) {
    return SizedBox(
      height: 30,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildValueBox(String text) {
    return Container(
      width: 100,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}
