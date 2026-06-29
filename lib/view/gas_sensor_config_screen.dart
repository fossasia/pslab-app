import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/gas_sensor_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';

import '../l10n/app_localizations.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';

class GasSensorConfigScreen extends StatefulWidget {
  const GasSensorConfigScreen({super.key});

  @override
  State<GasSensorConfigScreen> createState() => _GasSensorConfigScreenState();
}

class _GasSensorConfigScreenState extends State<GasSensorConfigScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  final TextEditingController _updatePeriodController = TextEditingController();
  bool _isControllerInitialized = false;

  @override
  void dispose() {
    _updatePeriodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GasSensorConfigProvider>(
      create: (_) => GasSensorConfigProvider(),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            iconTheme: IconThemeData(color: appBarContentColor),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: appBarColor,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            backgroundColor: primaryRed,
            title: Text(
              appLocalizations.configure,
              style: TextStyle(
                color: appBarContentColor,
                fontSize: 15,
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Consumer<GasSensorConfigProvider>(
                builder: (context, provider, child) {
                  if (!_isControllerInitialized) {
                    _updatePeriodController.text =
                        provider.config.updatePeriod.toString();
                    _isControllerInitialized = true;
                  }

                  String currentMode = provider.config.activeGas;
                  final List<String> allowedModes = [
                    'Raw',
                    'CO2',
                    'NH3',
                    'Alcohol',
                    'CO',
                    'Toluene',
                    'Acetone'
                  ];

                  if (!allowedModes.contains(currentMode)) {
                    currentMode = 'Raw';
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConfigDropdownItem(
                          title: "Active Gas",
                          selectedValue: currentMode,
                          options: [
                            ConfigOption(value: 'Raw', displayName: 'Raw'),
                            ConfigOption(value: 'CO2', displayName: 'CO2'),
                            ConfigOption(value: 'NH3', displayName: 'NH3'),
                            ConfigOption(
                                value: 'Alcohol', displayName: 'Alcohol'),
                            ConfigOption(value: 'CO', displayName: 'CO'),
                            ConfigOption(
                                value: 'Toluene', displayName: 'Toluene'),
                            ConfigOption(
                                value: 'Acetone', displayName: 'Acetone'),
                          ],
                          onChanged: (value) {
                            provider.updateActiveGas(value);
                          },
                        ),
                        ConfigInputItem(
                          title: appLocalizations.updatePeriod,
                          value:
                              '${provider.config.updatePeriod} ${appLocalizations.ms}',
                          controller: _updatePeriodController,
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                            if (intValue != null &&
                                intValue >= 100 &&
                                intValue <= 5000) {
                              provider.updateUpdatePeriod(intValue);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                      appLocalizations.updatePeriodErrorMessage,
                                      style: TextStyle(
                                          color: snackBarContentColor),
                                    ),
                                    backgroundColor: snackBarBackgroundColor),
                              );
                            }
                          },
                          hint: appLocalizations.baroUpdatePeriodHint,
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
      },
    );
  }
}
