import 'package:flutter/material.dart';
import 'package:pslab/theme/colors.dart';

class WaveGeneratorMainControls extends StatefulWidget {
  const WaveGeneratorMainControls({super.key});

  @override
  State<StatefulWidget> createState() => _WaveGeneratorMainControlsState();
}

class _WaveGeneratorMainControlsState extends State<WaveGeneratorMainControls> {
  String iconSin = "assets/icons/ic_sin.png";
  String iconTriangular = "assets/icons/ic_triangular.png";
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 75,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            color: Colors.black,
            child: Column(
              children: [
                Expanded(
                  flex: 80,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 20,
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  iconSin,
                                  height: 40,
                                  width: 40,
                                ),
                                Text(
                                  'Sine',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          flex: 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Frequency:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Phase:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: const Divider(),
                ),
                Expanded(
                  flex: 20,
                  child: Transform.translate(
                    offset: const Offset(0, -8),
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 32,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Phase Offset:',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 25,
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 16,
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 35,
                  width: 30,
                  child: IconButton.filled(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.chevron_left),
                    onPressed: () async {},
                    style: IconButton.styleFrom(
                      backgroundColor: primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      inactiveTrackColor: sliderInActiveColor,
                      trackHeight: 1,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      activeColor: primaryRed,
                      min: 0,
                      max: 5000,
                      value: 0,
                      onChanged: (value) {},
                    ),
                  ),
                ),
                SizedBox(
                  height: 35,
                  width: 30,
                  child: IconButton.filled(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.chevron_right),
                    onPressed: () async {},
                    style: IconButton.styleFrom(
                      backgroundColor: primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
