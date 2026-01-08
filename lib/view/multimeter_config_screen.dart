import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/multimeter_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';

import '../theme/colors.dart';

class MultimeterConfigScreen extends StatefulWidget {
  const MultimeterConfigScreen({super.key});

  @override
  State<MultimeterConfigScreen> createState() => _MultimeterConfigScreenState();
}

class _MultimeterConfigScreenState extends State<MultimeterConfigScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final TextEditingController _updatePeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<MultimeterConfigProvider>(context, listen: false);
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
        iconTheme: IconThemeData(color: appBarContentColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: appBarColor,
          statusBarIconBrightness: Brightness.light,
        ),
        backgroundColor: primaryRed,
        title: Text(
          appLocalizations.multimeterConfigs,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<MultimeterConfigProvider>(
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
                            intValue <= 1000) {
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
                      hint: appLocalizations.multimeterUpdatePeriodHint,
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
