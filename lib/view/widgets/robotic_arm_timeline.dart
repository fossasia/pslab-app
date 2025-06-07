import 'package:flutter/material.dart';
import 'package:pslab/constants.dart';

import '../../colors.dart';

class TimelineScrollView extends StatelessWidget {
  final ScrollController scrollController;
  final int timelinePosition;
  final double scrollAmountPerTick;
  final List<List<double>> timelineDegrees;
  final void Function(int index, int servo, double value) onUpdate;

  const TimelineScrollView({
    super.key,
    required this.scrollController,
    required this.timelinePosition,
    required this.scrollAmountPerTick,
    required this.timelineDegrees,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        child: Row(
          children: List.generate(60, (index) {
            bool isCurrent = index == timelinePosition;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                children: [
                  Container(
                    width: 130,
                    height: 4,
                    color: isCurrent ? primaryRed : Colors.transparent,
                  ),
                  const SizedBox(height: 3),
                  ...List.generate(4, (boxIndex) {
                    return Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: SizedBox(
                        width: 130,
                        height: 35,
                        child: DragTarget<Map<String, dynamic>>(
                          builder: (context, candidateData, rejectedData) {
                            bool isHighlighted = candidateData.isNotEmpty;
                            return Container(
                              decoration: BoxDecoration(
                                color: isHighlighted
                                    ? Colors.blue.withAlpha((0.3 * 255).round())
                                    : Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 1,
                                    child: Text(
                                      '${timelineDegrees[index][boxIndex].toStringAsFixed(0)}$degreeSymbol',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
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
                                        fontSize: 14,
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
                            onUpdate(index, boxIndex, data['degree']);
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
