import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/communication/peripherals/i2c.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import '../providers/mlx90614_provider.dart';

class MLX90614Screen extends StatefulWidget {
  const MLX90614Screen({super.key});

  @override
  State<MLX90614Screen> createState() => _MLX90614ScreenState();
}

class _MLX90614ScreenState extends State<MLX90614Screen> {
  late final MLX90614Provider _provider;

  @override
  void initState() {
    super.initState();
    _provider = MLX90614Provider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final scienceLab = getIt<ScienceLab>();
      final appLocalizations = AppLocalizations.of(context)!;

      if (scienceLab.isConnected()) {
        final i2c = I2C(scienceLab.mPacketHandler);
        _provider.init(i2c);
        _provider.startDataLog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.notConnected)),
        );
      }
    });
  }

  @override
  void dispose() {
    _provider.stopDataLog();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<MLX90614Provider>(
        builder: (context, provider, child) {
          final appLocalizations = AppLocalizations.of(context)!;

          return CommonScaffold(
            title: 'MLX90614 Sensor',
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSensorCard(
                    title: appLocalizations.mlxObjectTemp,
                    value: provider.objectTemp.toStringAsFixed(2),
                    unit: "°C",
                    icon: Icons.thermostat_auto,
                    color: Colors.deepOrangeAccent,
                  ),
                  const SizedBox(height: 20),
                  _buildSensorCard(
                    title: appLocalizations.mlxAmbientTemp,
                    value: provider.ambientTemp.toStringAsFixed(2),
                    unit: "°C",
                    icon: Icons.home_mini,
                    color: Colors.blueGrey,
                  ),
                ],
              ),
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
