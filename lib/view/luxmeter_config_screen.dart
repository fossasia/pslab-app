import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/luxmeter_config_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';

import '../theme/colors.dart';

class LuxMeterConfigScreen extends StatefulWidget {
  const LuxMeterConfigScreen({super.key});

  @override
  State<LuxMeterConfigScreen> createState() => _LuxMeterConfigScreenState();
}

class _LuxMeterConfigScreenState extends State<LuxMeterConfigScreen> {
  final TextEditingController _updatePeriodController = TextEditingController();
  final TextEditingController _highLimitController = TextEditingController();
  final TextEditingController _sensorGainController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<LuxMeterConfigProvider>(context, listen: false);
      _updatePeriodController.text = provider.config.updatePeriod.toString();
      _highLimitController.text = provider.config.highLimit.toString();
      _sensorGainController.text = provider.config.sensorGain.toString();
    });
  }

  @override
  void dispose() {
    _updatePeriodController.dispose();
    _highLimitController.dispose();
    _sensorGainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: luxmeterConfigurations,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<LuxMeterConfigProvider>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfigItem(
                    title: updatePeriod,
                    value: '${provider.config.updatePeriod} $ms',
                    controller: _updatePeriodController,
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue != null &&
                          intValue >= 100 &&
                          intValue <= 1000) {
                        provider.updateUpdatePeriod(intValue);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                updatePeriodErrorMessage,
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.grey[700]),
                        );
                      }
                    },
                    hint: updatePeriodHint,
                  ),
                  _buildConfigItem(
                    title: highLimit,
                    value: '${provider.config.highLimit} $lx',
                    controller: _highLimitController,
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue != null &&
                          intValue >= 10 &&
                          intValue <= 10000) {
                        provider.updateHighLimit(intValue);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                highLimitErrorMessage,
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.grey[700]),
                        );
                      }
                    },
                    hint: highLimitHint,
                  ),
                  _buildSensorDropdown(provider),
                  _buildConfigItem(
                    title: sensorGain,
                    value: provider.config.sensorGain.toString(),
                    controller: _sensorGainController,
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue != null) {
                        provider.updateSensorGain(intValue);
                      }
                    },
                    hint: sensorGainHint,
                  ),
                  _buildLocationCheckbox(provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConfigItem({
    required String title,
    required String value,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? hint,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: blackTextColor,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: hintTextColor,
        ),
      ),
      onTap: () => _showInputDialog(title, controller, onChanged, hint),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showInputDialog(String title, TextEditingController controller,
      Function(String) onChanged, String? hint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: hintTextColor,
                    ),
                  ),
                ),
              TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: false),
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryRed),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                cancel,
                style: TextStyle(color: primaryRed),
              ),
            ),
            TextButton(
              onPressed: () {
                onChanged(controller.text);
                Navigator.of(context).pop();
              },
              child: Text(
                ok,
                style: TextStyle(color: primaryRed),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensorDropdown(LuxMeterConfigProvider provider) {
    return ListTile(
      title: Text(
        activeSensor,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: blackTextColor,
        ),
      ),
      subtitle: Text(
        provider.config.activeSensor,
        style: TextStyle(
          fontSize: 14,
          color: hintTextColor,
        ),
      ),
      onTap: () => _showSensorDialog(provider),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showSensorDialog(LuxMeterConfigProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(activeSensor),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(inBuiltSensor),
                value: 'In-built Sensor',
                groupValue: provider.config.activeSensor,
                onChanged: (String? value) {
                  if (value != null) {
                    provider.updateActiveSensor(value);
                    Navigator.of(context).pop();
                  }
                },
                activeColor: primaryRed,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('BH1750'),
                value: 'BH1750',
                groupValue: provider.config.activeSensor,
                onChanged: (String? value) {
                  if (value != null) {
                    provider.updateActiveSensor(value);
                    Navigator.of(context).pop();
                  }
                },
                activeColor: primaryRed,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('TSL2561'),
                value: 'TSL2561',
                groupValue: provider.config.activeSensor,
                onChanged: (String? value) {
                  if (value != null) {
                    provider.updateActiveSensor(value);
                    Navigator.of(context).pop();
                  }
                },
                activeColor: primaryRed,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                cancel,
                style: TextStyle(color: primaryRed),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationCheckbox(LuxMeterConfigProvider provider) {
    return ListTile(
      title: Text(
        locationData,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: blackTextColor,
        ),
      ),
      subtitle: Text(
        locationDataHint,
        style: TextStyle(
          fontSize: 14,
          color: hintTextColor,
        ),
      ),
      trailing: Checkbox(
        value: provider.config.includeLocationData,
        checkColor: Colors.white,
        onChanged: (bool? value) {
          if (value != null) {
            provider.updateIncludeLocationData(value);
          }
        },
        activeColor: checkBoxActiveColor,
      ),
      onTap: () {
        provider
            .updateIncludeLocationData(!provider.config.includeLocationData);
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
