import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/feature_not_implemented_screen.dart';

class GasSensorScreen extends StatelessWidget {
  const GasSensorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
    
    return FeatureNotImplementedScreen(
      title: appLocalizations.gasSensor,
      description: appLocalizations.gasSensorDesc,
      icon: Icons.air,
      accentColor: Colors.blue,
    );
  }
}
