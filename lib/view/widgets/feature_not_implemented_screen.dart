import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';

/// A reusable placeholder widget for features that are not yet implemented.
/// Used to provide consistent UX across multiple placeholder screens.
class FeatureNotImplementedScreen extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const FeatureNotImplementedScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  @override
  State<FeatureNotImplementedScreen> createState() =>
      _FeatureNotImplementedScreenState();
}

class _FeatureNotImplementedScreenState extends State<FeatureNotImplementedScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: widget.title,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 120,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 32),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                appLocalizations.screenNotImplemented,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: widget.accentColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(appLocalizations.close),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
