import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/barometer_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';

import '../l10n/app_localizations.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';

class BarometerConfigScreen extends StatefulWidget {
  const BarometerConfigScreen({super.key});

  @override
  State<BarometerConfigScreen> createState() => _BarometerConfigScreenState();
}

class _BarometerConfigScreenState extends State<BarometerConfigScreen> {
  final TextEditingController _updatePeriodController = TextEditingController();
  final TextEditingController _highLimitController = TextEditingController();
  final TextEditingController _sensorGainController = TextEditingController();
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<BarometerConfigProvider>(context, listen: false);
      _updatePeriodController.text = provider.config.updatePeriod.toString();
      _highLimitController.text = provider.config.highLimit.toString();
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
                  ModalRoute.of(context)?.settings.name == '/barometer') {
                Navigator.popUntil(context, ModalRoute.withName('/barometer'));
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/barometer',
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
          appLocalizations.barometerConfig,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<BarometerConfigProvider>(
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
                        final intValue = int.tryParse(value);
                        if (intValue != null &&
                            intValue >= 100 &&
                            intValue <= 2000) {
                          provider.updateUpdatePeriod(intValue);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                  appLocalizations.updatePeriodErrorMessage,
                                  style: TextStyle(color: snackBarContentColor),
                                ),
                                backgroundColor: snackBarBackgroundColor),
                          );
                        }
                      },
                      hint: appLocalizations.baroUpdatePeriodHint,
                    ),
                    ConfigInputItem(
                      title: appLocalizations.highLimit,
                      value:
                          '${provider.config.highLimit} ${appLocalizations.atm}',
                      controller: _highLimitController,
                      onChanged: (value) {
                        final doubleValue = double.tryParse(value);
                        final regex = RegExp(r'^\d+(\.\d{1,2})?$');
                        if (doubleValue != null &&
                            doubleValue >= 0 &&
                            doubleValue <= 1.10 &&
                            regex.hasMatch(value)) {
                          provider.updateHighLimit(doubleValue);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                  appLocalizations.highLimitErrorMessage,
                                  style: TextStyle(color: snackBarContentColor),
                                ),
                                backgroundColor: snackBarBackgroundColor),
                          );
                        }
                      },
                      hint: appLocalizations.barometerHighLimitHint,
                    ),
                    ConfigDropdownItem(
                      title: appLocalizations.activeSensor,
                      selectedValue: provider.config.activeSensor,
                      options: [
                        ConfigOption(
                            value: 'In-built Sensor',
                            displayName: appLocalizations.inBuiltSensor),
                        ConfigOption(value: 'BMP180', displayName: 'BMP180'),
                      ],
                      onChanged: (value) {
                        provider.updateActiveSensor(value);
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
