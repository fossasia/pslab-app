import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/thermometer_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';

import '../theme/colors.dart';

class ThermometerConfigScreen extends StatefulWidget {
  const ThermometerConfigScreen({super.key});

  @override
  State<ThermometerConfigScreen> createState() =>
      _ThermometerConfigScreenState();
}

class _ThermometerConfigScreenState extends State<ThermometerConfigScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final TextEditingController _updatePeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ThermometerConfigProvider>(context, listen: false);
      _updatePeriodController.text = provider.config.updatePeriod.toString();
    });
  }

  @override
  void dispose() {
    _updatePeriodController.dispose();
    super.dispose();
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
            onPressed: () {
              Navigator.maybePop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: appBarContentColor,
            ),
          );
        }),
        backgroundColor: primaryRed,
        title: Text(
          appLocalizations.thermometerTitle,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<ThermometerConfigProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    ConfigInputItem(
                      title: appLocalizations.updatePeriod,
                      value:
                          '${provider.config.updatePeriod} ${appLocalizations.ms}',
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
                                appLocalizations.updatePeriodErrorMessage,
                                style: TextStyle(color: snackBarContentColor),
                              ),
                              backgroundColor: snackBarBackgroundColor,
                            ),
                          );
                        }
                      },
                      hint: '100 - 1000',
                    ),
                    ConfigDropdownItem(
                      title: appLocalizations.activeSensor,
                      selectedValue: provider.config.activeSensor,
                      options: [
                        ConfigOption(
                          value: 'In-built Sensor',
                          displayName: appLocalizations.inBuiltSensor,
                        ),
                        ConfigOption(
                          value: 'SHT21',
                          displayName: 'SHT21',
                        ),
                      ],
                      onChanged: (value) {
                        provider.updateActiveSensor(value);
                      },
                    ),
                    ConfigDropdownItem(
                      title: "Temperature Unit",
                      selectedValue: provider.config.unit,
                      options: [
                        ConfigOption(
                          value: 'Celsius',
                          displayName: '°C',
                        ),
                        ConfigOption(
                          value: 'Fahrenheit',
                          displayName: '°F',
                        ),
                      ],
                      onChanged: (value) {
                        provider.updateUnit(value);
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
