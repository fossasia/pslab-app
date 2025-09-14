import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:pslab/view/experiment_guide_screen.dart';
import '/theme/colors.dart';

class ExperimentsScreen extends StatefulWidget {
  const ExperimentsScreen({super.key});

  @override
  State<ExperimentsScreen> createState() => _ExperimentsScreenState();
}

class _ExperimentsScreenState extends State<ExperimentsScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  late final List<Map<String, dynamic>> experiments = [
    {
      'id': 'light_distance',
      'title': appLocalizations.lightIntensityVsDistance,
      'description': appLocalizations.lightIntensityVsDistanceDesc,
      'icon': Icons.lightbulb,
      'route': '/luxmeter',
    },
    {
      'id': 'barometer_pressure',
      'title': appLocalizations.pressureVsAltitude,
      'description': appLocalizations.pressureVsAltitudeDesc,
      'icon': Icons.compress,
      'route': '/barometer',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 13,
      title: appLocalizations.experiments,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: experiments.length,
                  itemBuilder: (context, index) {
                    final experiment = experiments[index];
                    return _buildExperimentCard(context, experiment);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperimentCard(
      BuildContext context, Map<String, dynamic> experiment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExperimentGuideScreen(
                experimentId: experiment['id'],
                experimentTitle: experiment['title'],
                experimentRoute: experiment['route'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryRed.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      experiment['icon'],
                      color: primaryRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          experiment['title'],
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                experiment['description'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: snackBarBackgroundColor,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExperimentGuideScreen(
                            experimentId: experiment['id'],
                            experimentTitle: experiment['title'],
                            experimentRoute: experiment['route'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: buttonTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(appLocalizations.startExperiment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
