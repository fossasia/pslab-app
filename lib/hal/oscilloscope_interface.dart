abstract class OscilloscopeInterface {
  Future<void> configureChannel(int channel, bool enabled);
  Future<void> setGain(int channel, double gain);
  void setAcCoupled(bool isAc);
  Future<List<double>> fetchSamples(int numToGet, int channel);
}
