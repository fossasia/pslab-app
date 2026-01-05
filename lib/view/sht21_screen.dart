import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/peripherals/i2c.dart'; // Import I2C class
import 'package:pslab/providers/locator.dart';
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
      final sht21Provider = Provider.of<SHT21Provider>(context, listen: false);

      // 1. Get the ScienceLab instance
      final scienceLab = getIt<ScienceLab>();

      // 2. Check connection
      if (scienceLab.isConnected()) {
        // 3. MANUALLY create the I2C helper using the packet handler
        // This fixes the "getter i2c not defined" error
        I2C i2c = I2C(scienceLab.mPacketHandler);

        // 4. Initialize the sensor provider
        sht21Provider.init(i2c);
        sht21Provider.startDataLog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device not connected')),
        );
      }
    });
  }

  @override
  void dispose() {
    // Stop the data loop when leaving the screen
    if (mounted) {
      Provider.of<SHT21Provider>(context, listen: false).stopDataLog();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  title: "Temperature",
                  value: provider.temp.toStringAsFixed(2),
                  unit: "°C",
                  icon: Icons.thermostat,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 20),
                _buildSensorCard(
                  title: "Humidity",
                  value: provider.hum.toStringAsFixed(2),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 18, color: Colors.grey)),
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
          ],
        ),
      ),
    );
  }
}
