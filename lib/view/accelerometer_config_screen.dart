import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/accelerometer_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';

import '../providers/locator.dart';
import '../theme/colors.dart';

class AccelerometerConfigScreen extends StatefulWidget {
  const AccelerometerConfigScreen({super.key});

  @override
  State<AccelerometerConfigScreen> createState() =>
      _AccelerometerConfigScreenState();
}

class _AccelerometerConfigScreenState extends State<AccelerometerConfigScreen> {
  final TextEditingController _updatePeriodController = TextEditingController();
  final TextEditingController _highLimitController = TextEditingController();
  final TextEditingController _lowLimitController = TextEditingController();
  final TextEditingController _sensorGainController = TextEditingController();
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AccelerometerConfigProvider>(context, listen: false);
      _updatePeriodController.text = provider.config.updatePeriod.toString();
      _highLimitController.text = provider.config.highLimit.toString();
      _lowLimitController.text = provider.config.lowLimit.toString();
      _sensorGainController.text = provider.config.sensorGain.toString();
    });
  }

  @override
  void dispose() {
    _updatePeriodController.dispose();
    _highLimitController.dispose();
    _lowLimitController.dispose();
    _sensorGainController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: snackBarContentColor),
        ),
        backgroundColor: snackBarBackgroundColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: appBarColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: Builder(builder: (context) {
          return IconButton(
            tooltip: appLocalizations.back,
            onPressed: () {
              if (Navigator.canPop(context) &&
                  ModalRoute.of(context)?.settings.name == '/accelerometer') {
                Navigator.popUntil(
                    context, ModalRoute.withName('/accelerometer'));
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/accelerometer',
                  (route) => route.isFirst,
                );
              }
            },
            icon: Icon(
              Icons.arrow_back,
              color: appBarContentColor,
            ),
          );
        }),
        backgroundColor: primaryRed,
        title: Text(
          appLocalizations.accelerometerConfigurations,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<AccelerometerConfigProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConfigInputItem(
                      title: appLocalizations.updatePeriod,
                      value:
                          '${provider.config.updatePeriod} ${appLocalizations.ms}',
                      controller: _updatePeriodController,
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        final intValue = int.tryParse(value);
                        if (intValue != null &&
                            intValue >= 20 &&
                            intValue <= 1000) {
                          provider.updateUpdatePeriod(intValue);
                        } else {
                          _showErrorSnackbar(
                              appLocalizations.updatePeriodErrorMessage);
                        }
                      },
                      hint: appLocalizations.accelerometerUpdatePeriodHint,
                    ),
                    ConfigInputItem(
                      title: appLocalizations.highLimit,
                      value:
                          '${provider.config.highLimit} ${appLocalizations.meterPerSecondSquared}',
                      controller: _highLimitController,
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        final intValue = int.tryParse(value);
                        if (intValue != null &&
                            intValue >= 0 &&
                            intValue <= 200) {
                          provider.updateHighLimit(intValue);
                        } else {
                          _showErrorSnackbar(
                              appLocalizations.highLimitErrorMessage);
                        }
                      },
                      hint: appLocalizations.accelerometerHighLimitHint,
                    ),
                    ConfigInputItem(
                      title: appLocalizations.lowLimit,
                      value:
                          '${provider.config.lowLimit} ${appLocalizations.meterPerSecondSquared}',
                      controller: _lowLimitController,
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        final intValue = int.tryParse(value);
                        if (intValue != null &&
                            intValue >= 0 &&
                            intValue <= 200) {
                          provider.updateLowLimit(intValue);
                        } else {
                          _showErrorSnackbar(
                              appLocalizations.lowLimitErrorMessage);
                        }
                      },
                      hint: appLocalizations.accelerometerLowLimitHint,
                    ),
                    ConfigDropdownItem(
                      title: appLocalizations.activeSensor,
                      selectedValue: provider.config.activeSensor,
                      options: [
                        ConfigOption(
                            value: 'In-built Sensor',
                            displayName: appLocalizations.inBuiltSensor),
                        ConfigOption(value: 'MPU6050', displayName: 'MPU6050'),
                        ConfigOption(value: 'MPU925X', displayName: 'MPU925X'),
                      ],
                      onChanged: (value) {
                        provider.updateActiveSensor(value);
                      },
                    ),
                    ConfigInputItem(
                      title: appLocalizations.sensorGain,
                      value: provider.config.sensorGain.toString(),
                      controller: _sensorGainController,
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        final doubleValue = double.tryParse(value);
                        if (doubleValue != null &&
                            doubleValue >= 0 &&
                            doubleValue <= 100) {
                          provider.updateSensorGain(doubleValue);
                        } else {
                          _showErrorSnackbar(
                              appLocalizations.sensorGainErrorMessage);
                        }
                      },
                      hint: appLocalizations.sensorGainHint,
                    ),
                    ConfigCheckboxItem(
                      title: appLocalizations.autoScaleGraph,
                      subtitle: appLocalizations.autoScaleDescription,
                      value: provider.config.autoScale,
                      onChanged: (value) {
                        provider.updateAutoScale(value);
                      },
                    ),
                    ConfigCheckboxItem(
                      title: appLocalizations.locationData,
                      subtitle: appLocalizations.locationDataHint,
                      value: provider.config.includeLocationData,
                      onChanged: (value) {
                        provider.updateIncludeLocationData(value);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
