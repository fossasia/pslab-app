import 'package:flutter/material.dart';
import 'package:pslab/colors.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

import '../../constants.dart';

class ServoCard extends StatelessWidget {
  final double value;
  final Function(double) onChanged;
  final VoidCallback onTap;
  final String label;
  final int servoId;

  const ServoCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onTap,
    required this.label,
    required this.servoId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 8,
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
            top: 8,
            right: 8,
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${value.toInt()}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              childWhenDragging:
                  const Icon(Icons.more_vert, size: 16, color: Colors.grey),
              child: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 25,
            child: GestureDetector(
              onTap: onTap,
              child: Center(
                child: SleekCircularSlider(
                  initialValue: value,
                  min: 0,
                  max: 360,
                  onChange: onChanged,
                  appearance: CircularSliderAppearance(
                    size: 96,
                    startAngle: 270,
                    angleRange: 360,
                    customWidths: CustomSliderWidths(
                      trackWidth: 8,
                      progressBarWidth: 8,
                      handlerSize: 14,
                    ),
                    customColors: CustomSliderColors(
                      trackColor: Colors.grey.shade300,
                      progressBarColor: primaryRed,
                      dotColor: Colors.blue,
                    ),
                    infoProperties: InfoProperties(
                      mainLabelStyle: const TextStyle(fontSize: 16),
                      modifier: (val) => '${val.toInt()}$degreeSymbol',
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
