import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/feature_not_implemented_screen.dart';

class DustSensorScreen extends StatelessWidget {
  const DustSensorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
    
    return FeatureNotImplementedScreen(
      title: appLocalizations.dustSensor,
      description: appLocalizations.dustSensorDesc,
      icon: Icons.blur_on,
      accentColor: Colors.orange,
    );
  }
}
