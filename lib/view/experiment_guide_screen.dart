import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/luxmeter_screen.dart';
import '../theme/colors.dart';
import '../providers/experiment_provider.dart';
import 'package:pslab/others/light_distance_experiment.dart';

class ExperimentGuideScreen extends StatefulWidget {
  final String experimentId;
  final String experimentTitle;
  final String experimentRoute;

  const ExperimentGuideScreen({
    super.key,
    required this.experimentId,
    required this.experimentTitle,
    required this.experimentRoute,
  });

  @override
  State<ExperimentGuideScreen> createState() => _ExperimentGuideScreenState();
}

class _ExperimentGuideScreenState extends State<ExperimentGuideScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  int currentStep = 0;
  List<Map<String, String>> guideSteps = [];
  late ExperimentProvider _experimentProvider;

  @override
  void initState() {
    super.initState();
    _experimentProvider = ExperimentProvider();
    _loadExperimentGuide();
  }

  void _loadExperimentGuide() {
    switch (widget.experimentId) {
      case 'light_distance':
        guideSteps = lightDistanceExperiment.guideSteps;
        break;
      default:
        guideSteps = [
          {
            'title': 'Setup',
            'content': appLocalizations.followInstructions,
            'image': '',
          }
        ];
    }
  }

  void nextStep() {
    if (currentStep < guideSteps.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      _startExperiment();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  void _startExperiment() {
    switch (widget.experimentId) {
      case 'light_distance':
        _experimentProvider.startExperiment(lightDistanceExperiment);
        break;
    }

    switch (widget.experimentRoute) {
      case '/luxmeter':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChangeNotifierProvider<ExperimentProvider>.value(
              value: _experimentProvider,
              child: const LuxMeterScreen(isExperiment: true),
            ),
          ),
        );
        break;
      default:
        Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (guideSteps.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.experimentTitle),
          backgroundColor: appBarColor,
          foregroundColor: appBarContentColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final step = guideSteps[currentStep];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.experimentTitle),
        backgroundColor: appBarColor,
        foregroundColor: appBarContentColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (currentStep + 1) / guideSteps.length,
              backgroundColor: sensorStatusBorder,
              valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
            ),
            const SizedBox(height: 20),
            Text(
              '${appLocalizations.step} ${currentStep + 1} - ${guideSteps.length}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              step['title']!,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (step['image'] != null && step['image']!.isNotEmpty)
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        color: sensorStatusBorder,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          step['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: sensorStatusBorder,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: menuColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  Text(
                    step['content']!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 0)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sensorStatusBorder,
                      foregroundColor: guideDrawerHeadingColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: previousStep,
                    child: Text(appLocalizations.previous),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: buttonTextColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: nextStep,
                  child: Text(
                    currentStep == guideSteps.length - 1
                        ? appLocalizations.startExperiment
                        : appLocalizations.next,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
