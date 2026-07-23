import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/compass_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';
import '../l10n/app_localizations.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';

class CompassConfigScreen extends StatefulWidget {
  const CompassConfigScreen({super.key});
  @override
  State<CompassConfigScreen> createState() => _CompassConfigScreenState();
}

class _CompassConfigScreenState extends State<CompassConfigScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

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
          statusBarBrightness: Brightness.dark,
        ),
        leading: Builder(builder: (context) {
          return IconButton(
            tooltip: appLocalizations.back,
            onPressed: () {
              if (Navigator.canPop(context) &&
                  ModalRoute.of(context)?.settings.name == '/compass') {
                Navigator.popUntil(context, ModalRoute.withName('/compass'));
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/compass',
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
          '${appLocalizations.compassTitle} Config',
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<CompassConfigProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConfigDropdownItem(
                      title: 'Sensor Source',
                      selectedValue: provider.config.sensorSource,
                      options: [
                        ConfigOption(
                          value: 'inbuilt',
                          displayName: appLocalizations.inBuiltSensor,
                        ),
                        ConfigOption(
                          value: 'hmc5883l',
                          displayName: appLocalizations.hmc5883l,
                        ),
                      ],
                      onChanged: (value) {
                        provider.updateSensorSource(value);
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
