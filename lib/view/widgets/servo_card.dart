import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

import '../../providers/robotic_arm_state_provider.dart';

class ServoCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final provider = Provider.of<RoboticArmStateProvider>(context);
    final sliderSize =
        provider.maxAngle == 180 ? cardHeight * 0.95 : cardHeight * 0.72;

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
              label,
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
                'servoId': servoId,
                'degree': value,
              },
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Text(
                    '${value.floor()} °',
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
              onTap: onTap,
              child: Center(
                child: SleekCircularSlider(
                  initialValue: value.clamp(0, provider.maxAngle.toDouble()),
                  key: ValueKey(provider.maxAngle),
                  min: 0,
                  max: provider.maxAngle.toDouble(),
                  onChange: onChanged,
                  appearance: CircularSliderAppearance(
                    size: sliderSize,
                    startAngle: provider.maxAngle == 180 ? 180 : 270,
                    angleRange: provider.maxAngle.toDouble(),
                    customWidths: CustomSliderWidths(
                      trackWidth: 8,
                      progressBarWidth: 8,
                      handlerSize: 14,
                    ),
                    customColors: CustomSliderColors(
                      trackColor: Colors.grey.shade300,
                      progressBarColor: primaryRed,
                      dotColor: Colors.black38,
                    ),
                    infoProperties: InfoProperties(
                      mainLabelStyle: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withAlpha((0.3 * 255).round()),
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      modifier: (val) => '${val.round()}°',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
