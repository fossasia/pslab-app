import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/servo_slider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';
import '../../providers/robotic_arm_state_provider.dart';

class ServoCard extends StatefulWidget {
  final double value;
  final Function(double) onChanged;
  final VoidCallback onTap;
  final String label;
  final int servoId;
  final double cardHeight;

  const ServoCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onTap,
    required this.label,
    required this.servoId,
    required this.cardHeight,
  });

  @override
  State<ServoCard> createState() => _ServoCardState();
}

class _ServoCardState extends State<ServoCard> {
  late double currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoboticArmStateProvider>(context);
    final sliderSize = provider.maxAngle == 180
        ? widget.cardHeight * 0.95
        : widget.cardHeight * 0.85;
    AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 2,
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Draggable<Map<String, dynamic>>(
              data: {
                'servoId': widget.servoId,
                'degree': provider.maxAngle == 180
                    ? widget.value.clamp(0, 180).round()
                    : widget.value.clamp(0, 360).round(),
              },
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Text(
                    '${provider.maxAngle == 180 ? widget.value.clamp(0, 180).round() : widget.value.clamp(0, 360).round()} ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              childWhenDragging:
                  const Icon(Icons.drag_handle, size: 24, color: Colors.grey),
              child:
                  const Icon(Icons.drag_handle, size: 24, color: Colors.grey),
            ),
          ),
          Positioned.fill(
            top: provider.maxAngle == 180 ? 25 : 0,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ServoSlider(
                        progress: widget.value,
                        maxProgress: provider.maxAngle.toDouble(),
                        size: sliderSize,
                        trackWidth: 5,
                        thumbRadius: 9,
                        sweepAngle: provider.maxAngle.toDouble(),
                        startAngle:
                            provider.maxAngle.toDouble() == 180 ? 180 : 270,
                        clockwise: true,
                        trackColor: Colors.grey.shade300,
                        progressColor: Colors.red,
                        thumbColor: Colors.cyan,
                        onChanged: widget.onChanged),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ' ${provider.maxAngle == 180 ? widget.value.clamp(0, 180).round() : widget.value.clamp(0, 360).round()}${appLocalizations.degreeSymbol}',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        Text(
                          appLocalizations.tapToEdit,
                          style: TextStyle(fontSize: 7, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
