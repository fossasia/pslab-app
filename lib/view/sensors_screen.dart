import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/bmp180_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import '../../providers/board_state_provider.dart';
import '../theme/colors.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  bool _hasScanned = false;
  List<String> _detectedSensors = [];
  Map<String, String> _sensorAddresses = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardStateProvider>(
      builder: (context, boardProvider, child) {
        return CommonScaffold(
          title: 'Sensors',
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
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'AUTOSCAN',
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
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(boardProvider),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (_hasScanned) ...[
                  const SizedBox(height: 30),
                  const Text(
                    'SELECT SENSOR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
      return 'Not Connected';
    }

    if (!_hasScanned) {
      return 'Use Autoscan button to find connected sensors to PSLab device';
    }

    if (_detectedSensors.isEmpty) {
      return 'No sensors detected';
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
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: Text(
                  sensor,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
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
            content: Text('$sensorName screen not implemented yet'),
            duration: const Duration(seconds: 2),
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
