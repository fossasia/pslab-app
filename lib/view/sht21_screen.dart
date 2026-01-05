import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/l10n/app_localizations.dart';
import '../providers/sht21_provider.dart';

class SHT21Screen extends StatefulWidget {
  const SHT21Screen({super.key});

  @override
  State<SHT21Screen> createState() => _SHT21ScreenState();
}

class _SHT21ScreenState extends State<SHT21Screen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = Provider.of<SHT21Provider>(context, listen: false);
      final scienceLab = getIt<ScienceLab>();
      final appLocalizations = AppLocalizations.of(context)!;

      if (scienceLab.isConnected()) {
        I2C i2c = I2C(scienceLab.mPacketHandler);
        provider.init(i2c);
        provider.startDataLog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.notConnected)),
        );
      }
    });
  }

  @override
  void dispose() {
    if (mounted) {
      Provider.of<SHT21Provider>(context, listen: false).stopDataLog();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SHT21 Sensor'),
      ),
      body: Consumer<SHT21Provider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSensorCard(
                  // Using the localized string we added earlier
                  title: appLocalizations.temperature,
                  value: provider.temperature.toStringAsFixed(2),
                  unit: "°C",
                  icon: Icons.thermostat,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 20),
                _buildSensorCard(
                  title: "Humidity",
                  value: provider.humidity.toStringAsFixed(2),
                  unit: "%",
                  icon: Icons.water_drop,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Row(
                    children: [
                      Text(value,
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 5),
                      Text(unit, style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
