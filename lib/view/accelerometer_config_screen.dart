import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/accelerometer_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';

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
  final TextEditingController _sensorGainController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AccelerometerConfigProvider>(context, listen: false);
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: appBarColor),
        leading: Builder(builder: (context) {
          return IconButton(
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
          accelerometerConfigurations,
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
                                  style: TextStyle(color: snackBarContentColor),
                                ),
                                backgroundColor: snackBarBackgroundColor),
                          );
                        }
                      },
                      hint: accelerometerUpdatePeriodHint,
                    ),
                    ConfigInputItem(
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
                                  style: TextStyle(color: snackBarContentColor),
                                ),
                                backgroundColor: snackBarBackgroundColor),
                          );
                        }
                      },
                      hint: accelerometerHighLimitHint,
                    ),
                    ConfigDropdownItem(
                      title: activeSensor,
                      selectedValue: provider.config.activeSensor,
                      options: [
                        ConfigOption(
                            value: 'In-built Sensor',
                            displayName: inBuiltSensor),
                        ConfigOption(value: 'MPU6050', displayName: 'MPU6050'),
                      ],
                      onChanged: (value) {
                        provider.updateActiveSensor(value);
                      },
                    ),
                    ConfigInputItem(
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
                    ConfigCheckboxItem(
                      title: locationData,
                      subtitle: locationDataHint,
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
