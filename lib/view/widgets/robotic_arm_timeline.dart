import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class TimelineScrollView extends StatelessWidget {
  final int timelinePosition;
  final double screenHeight;
  final List<List<double?>> timelineDegrees;
  final void Function(int index, int servo, double value) onUpdate;
  final int totalTimelineItems;

  final ScrollController scrollController;

  const TimelineScrollView({
    super.key,
    required this.screenHeight,
    required this.timelinePosition,
    required this.timelineDegrees,
    required this.onUpdate,
    required this.totalTimelineItems,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
    final screenWidth = MediaQuery.of(context).size.width;
    final boxWidth = (screenWidth / 6) - 2;
    final timeLineHeight = (screenHeight - screenHeight / 2.5);
    final boxHeight = screenHeight / 11.1;

    return SizedBox(
      height: timeLineHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        child: Row(
          children: List.generate(totalTimelineItems, (index) {
            bool isCurrent = index == timelinePosition;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Column(
                children: [
                  Container(
                    width: boxWidth,
                    height: MediaQuery.of(context).size.height * 0.007,
                    color: isCurrent ? primaryRed : Colors.transparent,
                  ),
                  const SizedBox(height: 1),
                  ...List.generate(4, (boxIndex) {
                    return Padding(
                      padding: const EdgeInsets.all(0.5),
                      child: SizedBox(
                        width: boxWidth,
                        height: boxHeight,
                        child: DragTarget<Map<String, dynamic>>(
                          builder: (context, candidateData, rejectedData) {
                            bool isHighlighted = candidateData.isNotEmpty;
                            return Container(
                              decoration: BoxDecoration(
                                color: isHighlighted
                                    ? Colors.blue.withAlpha((0.3 * 255).round())
                                    : Colors.black,
                              ),
                              padding: const EdgeInsets.all(5),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: -MediaQuery.of(context).size.height *
                                        0.005,
                                    left: 1,
                                    child: Text(
                                      timelineDegrees[index][boxIndex] != null
                                          ? '${timelineDegrees[index][boxIndex]!.toStringAsFixed(0)}${appLocalizations.degreeSymbol}'
                                          : '',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.05,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 1,
                                    child: Text(
                                      '${index + 1}s',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onWillAcceptWithDetails:
                              (DragTargetDetails<Map<String, dynamic>>
                                  details) {
                            final data = details.data;
                            return data['servoId'] == boxIndex;
                          },
                          onAcceptWithDetails:
                              (DragTargetDetails<Map<String, dynamic>>
                                  details) {
                            final data = details.data;
                            onUpdate(index, boxIndex,
                                data['degree'].floorToDouble());
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
