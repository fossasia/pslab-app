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
        final channel = widget.dataParamsChannels[index];
        return Card(
          elevation: 8,
          color: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Text(
              'Vpp: ${OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.amplitude]?.toStringAsFixed(2)} V\n'
              'Vp+: ${OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.positivePeak]?.toStringAsFixed(2)} V  '
              'Vp-: ${OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.negativePeak]?.toStringAsFixed(2)} V\n'
              'f: ${formatFrequency(OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.frequency])}  '
              'P: ${OscilloscopeMeasurements.channel[channel]?[ChannelMeasurements.period]?.toStringAsFixed(2)} ms',
              style: TextStyle(
                color: colors[index],
                fontSize: 8,
              ),
            ),
          ),
        );
      },
    );
  }
}
