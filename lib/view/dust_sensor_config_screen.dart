import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/dust_sensor_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';
import '../l10n/app_localizations.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';

class DustSensorConfigScreen extends StatefulWidget {
  const DustSensorConfigScreen({super.key});
  @override
  State<DustSensorConfigScreen> createState() => _DustSensorConfigScreenState();
}

class _DustSensorConfigScreenState extends State<DustSensorConfigScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final TextEditingController _updatePeriodController = TextEditingController();
  final TextEditingController _highLimitController = TextEditingController();

  @override
  void dispose() {
    _updatePeriodController.dispose();
    _highLimitController.dispose();
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
          appLocalizations.dustSensorConfig,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<DustSensorConfigProvider>(
            builder: (context, provider, child) {
              _updatePeriodController.text =
                  provider.config.updatePeriod.toString();
              _highLimitController.text = provider.config.highLimit.toString();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    ConfigInputItem(
                      title: appLocalizations.updatePeriod,
                      value:
                          "${provider.config.updatePeriod} ${appLocalizations.ms}",
                      controller: _updatePeriodController,
                      hint: appLocalizations.dustUpdatePeriodHint,
                      onChanged: (value) {
                        try {
                          int updatePeriod = int.parse(value);
                          if (updatePeriod > 1000 || updatePeriod < 100) {
                            throw const FormatException();
                          }
                          provider.updateUpdatePeriod(updatePeriod);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  appLocalizations.updatePeriodErrorMessage)));
                        }
                      },
                    ),
                    ConfigInputItem(
                      title: appLocalizations.highLimit,
                      value:
                          "${provider.config.highLimit} ${appLocalizations.ppm}",
                      controller: _highLimitController,
                      hint: appLocalizations.dustHighLimitHint,
                      onChanged: (value) {
                        try {
                          double highLimit = double.parse(value);
                          if (highLimit > 5.0 || highLimit < 0.0) {
                            throw const FormatException();
                          }
                          provider.updateHighLimit(highLimit);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  appLocalizations.highLimitErrorMessage)));
                        }
                      },
                    ),
                    ConfigDropdownItem(
                      title: appLocalizations.activeSensor,
                      selectedValue: provider.config.activeSensor,
                      options: [
                        const ConfigOption(
                            value: 'SDS011', displayName: 'SDS011'),
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
