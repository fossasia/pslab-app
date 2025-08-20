import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import '/providers/experiment_provider.dart';
import '/theme/colors.dart';

class ExperimentOverlayWidget extends StatefulWidget {
  final VoidCallback? onExperimentComplete;

  const ExperimentOverlayWidget({
    super.key,
    this.onExperimentComplete,
  });

  @override
  State<ExperimentOverlayWidget> createState() =>
      _ExperimentOverlayWidgetState();
}

class _ExperimentOverlayWidgetState extends State<ExperimentOverlayWidget> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late Offset _position = Offset(MediaQuery.of(context).size.width / 8, 100);
  bool _hasCompletionBeenTriggered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExperimentProvider>(
      builder: (context, experimentProvider, child) {
        if (!experimentProvider.isExperimentActive &&
            experimentProvider.isExperimentCompleted &&
            !_hasCompletionBeenTriggered &&
            experimentProvider.currentExperiment != null) {
          _hasCompletionBeenTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onExperimentComplete?.call();
          });
        }

        if (experimentProvider.isExperimentActive &&
            _hasCompletionBeenTriggered) {
          _hasCompletionBeenTriggered = false;
        }
        if (!experimentProvider.isExperimentActive) {
          return const SizedBox.shrink();
        }

        final currentStep = experimentProvider.currentStep;
        if (currentStep == null) {
          return const SizedBox.shrink();
        }

        return _buildDraggableInstructionOverlay(
          context,
          currentStep.instruction,
          experimentProvider.isStepCompleted,
          experimentProvider.currentStepIndex + 1,
          experimentProvider.currentExperiment?.experimentSteps.length ?? 0,
        );
      },
    );
  }

  Widget _buildDraggableInstructionOverlay(
    BuildContext context,
    String instruction,
    bool isCompleted,
    int currentStep,
    int totalSteps,
  ) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Draggable(
        feedback: Material(
          color: Colors.transparent,
          child: _buildInstructionCard(
            context,
            instruction,
            isCompleted,
            currentStep,
            totalSteps,
            isDragging: true,
          ),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            final cardWidth = 320.0;
            final cardHeight = 160.0;

            _position = Offset(
              details.offset.dx.clamp(0, screenSize.width - cardWidth),
              details.offset.dy.clamp(0, screenSize.height - cardHeight),
            );
          });
        },
        child: _buildInstructionCard(
          context,
          instruction,
          isCompleted,
          currentStep,
          totalSteps,
        ),
      ),
    );
  }

  Widget _buildInstructionCard(
    BuildContext context,
    String instruction,
    bool isCompleted,
    int currentStep,
    int totalSteps, {
    bool isDragging = false,
  }) {
    return Material(
      elevation: isDragging ? 12 : 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted
                ? [stepCompletedColor[0], stepCompletedColor[1]]
                : [primaryRed.withAlpha(230), primaryRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDragging ? 75 : 50),
              blurRadius: isDragging ? 15 : 10,
              offset: Offset(0, isDragging ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.science,
                  color: buttonTextColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${appLocalizations.step} $currentStep - $totalSteps',
                    style: TextStyle(
                      color: buttonTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                MaterialButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      appLocalizations.endExperiment,
                      style: TextStyle(color: buttonTextColor),
                    ))
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: currentStep / totalSteps,
              backgroundColor: Colors.white.withAlpha(80),
              valueColor: AlwaysStoppedAnimation<Color>(buttonTextColor),
            ),
            const SizedBox(height: 16),
            Text(
              instruction,
              style: TextStyle(
                color: buttonTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check,
                    color: buttonTextColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appLocalizations.stepCompleted,
                    style: TextStyle(
                      color: buttonTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
