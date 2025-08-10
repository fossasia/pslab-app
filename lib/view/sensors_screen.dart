import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/bmp180_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import '../../providers/board_state_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _hasScanned = false;
  List<String> _detectedSensors = [];
  Map<String, String> _sensorAddresses = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardStateProvider>(
      builder: (context, boardProvider, child) {
        return CommonScaffold(
          title: appLocalizations.sensors,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _performAutoscan(boardProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: buttonTextColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      appLocalizations.autoscan.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: sensorStatusBackgroundColor,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: sensorStatusBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(boardProvider),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: blackTextColor,
                    ),
                  ),
                ),
                if (_hasScanned) ...[
                  const SizedBox(height: 30),
                  Text(
                    appLocalizations.selectSensor.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: blackTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildSensorList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(BoardStateProvider boardProvider) {
    if (!boardProvider.pslabIsConnected) {
      return appLocalizations.notConnected;
    }

    if (!_hasScanned) {
      return appLocalizations.autoScanHint;
    }

    if (_detectedSensors.isEmpty) {
      return appLocalizations.noSensorDetected;
    }

    String result = '';
    for (String sensor in _detectedSensors) {
      String address = _sensorAddresses[sensor] ?? '';
      result += '$address: [$sensor]\n';
    }
    return result.trim();
  }

  void _performAutoscan(BoardStateProvider boardProvider) {
    setState(() {
      _hasScanned = true;

      if (boardProvider.pslabIsConnected) {
        _detectedSensors = [
          'HMC5883L',
          'VL53L0X',
          'TSL2561',
          'APDS9960',
          'SHT21',
          'ADS1115',
          'MLX90614',
          'CCS811',
          'MPU6050',
          'MPU925X',
          'BMP180',
        ];
        _sensorAddresses = {
          'HMC5883L': '30',
          'VL53L0X': '41',
          'TSL2561': '57',
          'APDS9960': '57',
          'SHT21': '64',
          'ADS1115': '72',
          'MLX90614': '90',
          'CCS811': '90',
          'MPU6050': '104',
          'MPU925X': '105',
          'BMP180': '119',
        };
      } else {
        _detectedSensors = [];
        _sensorAddresses = {};
      }
    });
  }

  Widget _buildSensorList() {
    final sensors = [
      'ADS1115',
      'APDS9960',
      'BMP180',
      'CCS811',
      'HMC5883L',
      'MLX90614',
      'MPU6050',
      'MPU925X',
      'SHT21',
      'TSL2561',
      'VL53L0X',
    ];

    return ListView.builder(
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final sensor = sensors[index];
        final isDetected = _detectedSensors.contains(sensor);

        return Container(
          margin: const EdgeInsets.only(bottom: 1),
          child: Material(
            color: primaryRed,
            child: InkWell(
              onTap: () {
                _onSensorTap(sensor);
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: primaryRed,
                  border: isDetected
                      ? Border.all(color: buttonTextColor, width: 2)
                      : null,
                ),
                child: Text(
                  sensor,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: buttonTextColor,
                    fontSize: 16,
                    fontWeight: isDetected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSensorTap(String sensorName) {
    Widget? targetScreen;

    switch (sensorName) {
      case 'BMP180':
        targetScreen = const BMP180Screen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('$sensorName ${appLocalizations.screenNotImplemented}'),
            duration: const Duration(milliseconds: 500),
          ),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => targetScreen!,
      ),
    );
  }
}
