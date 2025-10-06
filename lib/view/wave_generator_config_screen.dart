import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/wave_generator_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';

import '../theme/colors.dart';

class WaveGeneratorConfigScreen extends StatefulWidget {
  const WaveGeneratorConfigScreen({super.key});

  @override
  State<WaveGeneratorConfigScreen> createState() =>
      _WaveGeneratorConfigScreenState();
}

class _WaveGeneratorConfigScreenState extends State<WaveGeneratorConfigScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        iconTheme: IconThemeData(color: appBarContentColor),
        systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: appBarColor),
        backgroundColor: primaryRed,
        title: Text(
          appLocalizations.waveGeneratorConfigs,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<WaveGeneratorConfigProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
