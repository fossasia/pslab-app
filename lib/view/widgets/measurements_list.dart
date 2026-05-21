import 'package:flutter/material.dart';
import 'package:pslab/models/oscilloscope_measurements.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';

class MeasurementsList extends StatefulWidget {
  final List<String> dataParamsChannels;
  const MeasurementsList({
    super.key,
    required this.dataParamsChannels,
  });

  @override
  State<StatefulWidget> createState() => _MeasurementsListState();
}

double _responsiveFont(BuildContext context, double baseFont) {
  const referenceWidth = 1440.0;
  const minFontSize = 8.0;
  const maxFontSize = 32.0;

  final width = MediaQuery.sizeOf(context).width;
  final scaled = (width / referenceWidth) * baseFont;

  return scaled.clamp(minFontSize, maxFontSize).toDouble();
}

class _MeasurementsListState extends State<MeasurementsList> {
  String formatFrequency(double? freq) {
    return freq! >= 1000
        ? '${(freq / 1000).toStringAsFixed(2)} kHz'
        : '${freq.toStringAsFixed(2)} Hz';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.dataParamsChannels.length,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final textStyle = TextStyle(
          color: colors[index],
          fontSize: _responsiveFont(context, 16),
        );
        final channel = widget.dataParamsChannels[index];
        return Card(
          elevation: 8,
          color: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vpp: ${OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.amplitude]?.toStringAsFixed(2)} V',
                        style: textStyle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Vp+: ${OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.positivePeak]?.toStringAsFixed(2)} V',
                        style: textStyle,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vp-: ${OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.negativePeak]?.toStringAsFixed(2)} V',
                        style: textStyle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'f: ${formatFrequency(OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.frequency] ?? 0.0)}',
                        style: textStyle,
                      ),
                    ),
                  ],
                ),
                Text(
                  'P: ${OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.period]?.toStringAsFixed(2)} ms',
                  style: textStyle,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
