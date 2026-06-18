import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/view/sht21_screen.dart';
import 'package:pslab/view/bmp180_screen.dart';
import 'package:pslab/view/ads1115_screen.dart';
import 'package:pslab/view/vl53l0x_screen.dart';
import 'package:pslab/view/apds9960_screen.dart';
import 'package:pslab/view/tsl2561_screen.dart';
import 'package:pslab/view/mpu6050_screen.dart';

import 'package:pslab/view/max30102_screen.dart';

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
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  bool _hasScanned = false;
  bool _isScanning = false;
  List<String> _detectedSensors = [];
  Map<String, String> _sensorAddresses = {};

  Future<void> _performAutoscan(BoardStateProvider boardProvider) async {
    if (!boardProvider.pslabIsConnected || _isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      I2C i2c =
          I2C(boardProvider.scienceLabCommon.getScienceLab().mPacketHandler);

      List<int> scannedAddresses = await i2c.scan(null);

      final Map<int, List<String>> knownSensors = {
        30: ['HMC5883L'],
        41: ['VL53L0X'],
        64: ['SHT21'],
        72: ['ADS1115'],
        87: ['MAX30102'],
        105: ['MPU925X'],
        119: ['BMP180'],
      };

      List<String> actualDetectedSensors = [];
      Map<String, String> actualSensorAddresses = {};

      for (int address in scannedAddresses) {
        if (address == 104) {
          try {
            int deviceId = await i2c.readByte(104, 0x75);
            if (deviceId == 104) {
              actualDetectedSensors.add('MPU6050');
              actualSensorAddresses['MPU6050'] = '0x68';
            }
          } catch (e) {
            logger.e('Failed to read MPU6050 ID at address 104: $e');
          }
        } else if (address == 57) {
          bool foundSpecific = false;
          try {
            int apdsId = await i2c.readByte(57, 0x92);
            if (apdsId == 171) {
              actualDetectedSensors.add('APDS9960');
              actualSensorAddresses['APDS9960'] = '0x39';
              foundSpecific = true;
            }
          } catch (e) {
            logger.e('Failed to read APDS9960 ID at address 57: $e');
          }

          if (!foundSpecific) {
            try {
              int tslId = await i2c.readByte(57, 0x8A);
              if ((tslId & 0xF0) == 0x50) {
                actualDetectedSensors.add('TSL2561');
                actualSensorAddresses['TSL2561'] = '0x39';
                foundSpecific = true;
              }
            } catch (e) {
              logger.e('Failed to read TSL2561 ID at address 57: $e');
            }
          }

          if (!foundSpecific) {
            actualDetectedSensors.add('TSL2561');
            actualSensorAddresses['TSL2561'] = '0x39';
            actualDetectedSensors.add('APDS9960');
            actualSensorAddresses['APDS9960'] = '0x39';
          }
        } else if (address == 90) {
          bool foundSpecific = false;
          try {
            int ccsId = await i2c.readByte(90, 0x20);
            if (ccsId == 129) {
              actualDetectedSensors.add('CCS811');
              actualSensorAddresses['CCS811'] = '0x5A';
              foundSpecific = true;
            }
          } catch (e) {
            logger.e('Failed to read CCS811 ID at address 90: $e');
          }

          if (!foundSpecific) {
            actualDetectedSensors.add('MLX90614');
            actualSensorAddresses['MLX90614'] = '0x5A';
            actualDetectedSensors.add('CCS811');
            actualSensorAddresses['CCS811'] = '0x5A';
          }
        } else if (knownSensors.containsKey(address)) {
          for (String sensorName in knownSensors[address]!) {
            actualDetectedSensors.add(sensorName);
            actualSensorAddresses[sensorName] =
                '0x${address.toRadixString(16).toUpperCase()}';
          }
        } else {
          logger.i(
              "Detected unknown sensor with address 0x${address.toRadixString(16).toUpperCase()} ($address)");
        }
      }

      if (mounted) {
        setState(() {
          _hasScanned = true;
          _detectedSensors = actualDetectedSensors;
          _sensorAddresses = actualSensorAddresses;
        });
      }
    } catch (e) {
      logger.e('I2C Autoscan failed completely: $e');
      if (mounted) {
        setState(() {
          _hasScanned = true;
          _detectedSensors = [];
          _sensorAddresses = {};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  String _getSensorDescription(String sensorName) {
    switch (sensorName) {
      case 'ADS1115':
        return appLocalizations.sensorDescADS1115;
      case 'APDS9960':
        return appLocalizations.sensorDescAPDS9960;
      case 'BMP180':
        return appLocalizations.sensorDescBMP180;
      case 'CCS811':
        return appLocalizations.sensorDescCCS811;
      case 'HMC5883L':
        return appLocalizations.sensorDescHMC5883L;
      case 'MAX30102':
        return appLocalizations.sensorDescMAX30102;
      case 'MLX90614':
        return appLocalizations.sensorDescMLX90614;
      case 'MPU6050':
        return appLocalizations.sensorDescMPU6050;
      case 'MPU925X':
        return appLocalizations.sensorDescMPU925X;
      case 'SHT21':
        return appLocalizations.sensorDescSHT21;
      case 'TSL2561':
        return appLocalizations.sensorDescTSL2561;
      case 'VL53L0X':
        return appLocalizations.sensorDescVL53L0X;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardStateProvider>(
      builder: (context, boardProvider, child) {
        return CommonScaffold(
          title: appLocalizations.sensors,
          actions: [
            Padding(
              padding:
                  const EdgeInsets.only(right: 12.0, top: 10.0, bottom: 10.0),
              child: OutlinedButton(
                onPressed:
                    _isScanning ? null : () => _performAutoscan(boardProvider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                  side: BorderSide(
                    color: _isScanning ? Colors.white70 : Colors.white,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isScanning
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        appLocalizations.autoscan.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          ],
          body: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: sensorStatusBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sensorStatusBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(boardProvider),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: blackTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  appLocalizations.selectSensor.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: blackTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _performAutoscan(boardProvider),
                    color: primaryRed,
                    child: _buildSensorListContent(),
                  ),
                ),
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

    List<String> formattedSensors = [];
    for (String sensor in _detectedSensors) {
      String address = _sensorAddresses[sensor] ?? '';
      formattedSensors.add('$sensor ($address)');
    }
    return 'Detected: ${formattedSensors.join(', ')}';
  }

  Widget _buildSensorListContent() {
    final sensors = [
      'ADS1115',
      'APDS9960',
      'BMP180',
      'CCS811',
      'HMC5883L',
      'MAX30102',
      'MLX90614',
      'MPU6050',
      'MPU925X',
      'SHT21',
      'TSL2561',
      'VL53L0X',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 600;
        int crossAxisCount = isDesktop ? 3 : 1;
        double spacing = 12.0;

        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20, top: 4),
          child: Wrap(
            spacing: spacing,
            runSpacing: 20,
            children: sensors.map((sensor) {
              final isDetected = _detectedSensors.contains(sensor);

              return SizedBox(
                width: itemWidth,
                child: _buildSensorChip(sensor, isDetected, isDesktop),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSensorChip(String sensor, bool isDetected, bool isDesktop) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onSensorTap(sensor, isDetected),
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: isDesktop
                  ? const EdgeInsets.fromLTRB(16, 24, 16, 20)
                  : const EdgeInsets.fromLTRB(8, 16, 8, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDetected ? Colors.green : primaryRed,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getSensorDescription(sensor),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  sensor,
                  style: TextStyle(
                    color: isDetected ? Colors.green.shade700 : primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 15 : 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSensorTap(String sensorName, bool isDetected) {
    if (!isDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$sensorName ${appLocalizations.mightNotConnected}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Widget? targetScreen;

    switch (sensorName) {
      case 'ADS1115':
        targetScreen = const ADS1115Screen();
        break;
      case 'BMP180':
        targetScreen = const BMP180Screen();
        break;
      case 'APDS9960':
        targetScreen = const APDS9960Screen();
        break;
      case 'VL53L0X':
        targetScreen = const VL53L0XScreen();
        break;
      case 'SHT21':
        targetScreen = const SHT21Screen();
        break;
      case 'TSL2561':
        targetScreen = const TSL2561Screen();
        break;
      case 'MPU6050':
        targetScreen = const MPU6050Screen();
        break;
      case 'MAX30102':
        targetScreen = const MAX30102Screen();
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('$sensorName ${appLocalizations.screenNotImplemented}'),
            duration: const Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
    }

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => targetScreen!));
  }
}
