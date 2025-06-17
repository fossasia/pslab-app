import 'package:pslab/view/widgets/gauge_widget.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/soundmeter_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';
import 'package:pslab/constants.dart';

class SoundMeterCard extends StatefulWidget {
  const SoundMeterCard({super.key});
  @override
  State<StatefulWidget> createState() => _SoundMeterCardState();
}

class _SoundMeterCardState extends State<SoundMeterCard> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    SoundMeterStateProvider provider =
        Provider.of<SoundMeterStateProvider>(context);
    double currentDb = provider.getCurrentDb();
    double minDb = provider.getMinDb();
    double maxDb = provider.getMaxDb();
    double avgDb = provider.getAverageDb();
    final cardMargin = screenWidth < 400 ? 8.0 : 12.0;
    final cardPadding = screenWidth < 400 ? 12.0 : 20.0;
    final gaugeSize = isLargeScreen ? 240.0 : screenWidth * 0.45;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 20.0 : 15.0;
    final dbValueFontSize = isLargeScreen ? 20.0 : 16.0;

    return Card(
      margin: EdgeInsets.all(cardMargin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    flex: screenWidth < 500 ? 40 : 35,
                    child: Instrumentstats(
                      titleFontSize: titleFontSize,
                      statFontSize: statFontSize,
                      maxValue: maxDb,
                      minValue: minDb,
                      avgValue: avgDb,
                      unit: db,
                    ),
                  ),
                  Expanded(
                    flex: screenWidth < 500 ? 60 : 65,
                    child: GaugeWidget(
                        gaugeSize: gaugeSize,
                        currentValue: currentDb,
                        minValue: 0,
                        maxValue: 200,
                        unit: db,
                        currentValueFontSize: dbValueFontSize),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
