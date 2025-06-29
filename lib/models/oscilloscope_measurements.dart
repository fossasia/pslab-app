import 'package:pslab/providers/oscilloscope_state_provider.dart';

class OscilloscopeMeasurements {
  static final Map<String, Map<ChannelMeasurements, double>> channel = {
    'CH1': {
      ChannelMeasurements.frequency: 0.00,
      ChannelMeasurements.period: 0.00,
      ChannelMeasurements.amplitude: 0.00,
      ChannelMeasurements.positivePeak: 0.00,
      ChannelMeasurements.negativePeak: 0.00,
    },
    'CH2': {
      ChannelMeasurements.frequency: 0.00,
      ChannelMeasurements.period: 0.00,
      ChannelMeasurements.amplitude: 0.00,
      ChannelMeasurements.positivePeak: 0.00,
      ChannelMeasurements.negativePeak: 0.00,
    },
    'CH3': {
      ChannelMeasurements.frequency: 0.00,
      ChannelMeasurements.period: 0.00,
      ChannelMeasurements.amplitude: 0.00,
      ChannelMeasurements.positivePeak: 0.00,
      ChannelMeasurements.negativePeak: 0.00,
    },
    'MIC': {
      ChannelMeasurements.frequency: 0.00,
      ChannelMeasurements.period: 0.00,
      ChannelMeasurements.amplitude: 0.00,
      ChannelMeasurements.positivePeak: 0.00,
      ChannelMeasurements.negativePeak: 0.00,
    },
  };
}
