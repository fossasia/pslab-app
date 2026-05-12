import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/colors.dart';

class HardwareSelectionScreen extends StatefulWidget {
  const HardwareSelectionScreen({super.key});

  @override
  State<HardwareSelectionScreen> createState() =>
      _HardwareSelectionScreenState();
}

class _HardwareOption {
  final String label;
  final IconData icon;
  final String value;

  _HardwareOption(this.label, this.icon, this.value);
}

class _HardwareSelectionScreenState extends State<HardwareSelectionScreen> {
  final AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late List<_HardwareOption> _options;

  @override
  void initState() {
    super.initState();
    _options = [
      _HardwareOption(appLocalizations.psLabBoard, Icons.usb, "pslab_board"),
      _HardwareOption(
          appLocalizations.internalSensors, Icons.developer_board, "internal_sensors"),
    ];
  }

  Future<void> _selectHardware(String hardwareValue) async {
    final boardProvider = getIt.get<BoardStateProvider>();
    boardProvider.setHardware(hardwareValue);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_hardware', hardwareValue);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 1,
      title: appLocalizations.selectHardware,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/icons/icon.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                appLocalizations.selectHardwareQuestion,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              ..._options.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: primaryRed,
                      ),
                      onPressed: () => _selectHardware(
                          option.value),
                      icon: Icon(option.icon, size: 28, color: chartTextColor,),
                      label: Text(option.label,
                          style: TextStyle(fontSize: 18, color: chartTextColor)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
