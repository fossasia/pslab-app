import 'dart:core';

List<String> instrumentHeadings = [
  'OSCILLOSCOPE',
  'MULTIMETER',
  'LOGIC ANALYZER',
  'SENSORS',
  'WAVE GENERATOR',
  'POWER SOURCE',
  'LUX METER',
  'ACCELEROMETER',
  'BAROMETER',
  'COMPASS',
  'GYROSCOPE',
  'THERMOMETER',
  'ROBOTIC ARM',
  'GAS SENSOR',
  'DUST SENSOR',
  'SOUND METER'
];

List<String> instrumentDesc = [
  'Allows observation of varying signal voltages',
  'Measure voltage, current, resistance and capacitance',
  'Captures and displays signals from digital systems',
  'Allows logging of data returned by sensor connected',
  'Generates arbitrary analog and digital waveforms',
  'Generates programmable voltage and currents',
  'Measures the ambient light intensity',
  'Measures the Linear acceleration in XYZ directions',
  'Measures the atmospheric pressure',
  'Three axes magnetometer pointing to magnetic north',
  'Measures rate of rotation about XYZ axis',
  'To measure the ambient temperature',
  'Controls servos of a robotic arm',
  'Air quality sensor for detecting a wide range of gases, including NH3, NOx, alcohol, benzene, smoke and CO2',
  'Dust sensor is used to measure air quality in terms of particles per square meter',
  'To measure the loudness in the environment in decibel(dB)'
];

List<String> instrumentIcons = [
  'assets/icons/tile_icon_oscilloscope.png',
  'assets/icons/tile_icon_multimeter.png',
  'assets/icons/tile_icon_logic_analyzer.png',
  'assets/icons/tile_icon_sensors.png',
  'assets/icons/tile_icon_wave_generator.png',
  'assets/icons/tile_icon_power_source.png',
  'assets/icons/tile_icon_lux_meter.png',
  'assets/icons/tile_icon_accelerometer.png',
  'assets/icons/tile_icon_barometer.png',
  'assets/icons/tile_icon_compass.png',
  'assets/icons/gyroscope_logo.png',
  'assets/icons/thermometer_logo.png',
  'assets/icons/robotic_arm.png',
  'assets/icons/tile_icon_gas.png',
  'assets/icons/tile_icon_gas.png',
  'assets/icons/tile_icon_gas.png',
];

List<String> yAxisRanges = [
  '+/-16V',
  '+/-8V',
  '+/-4V',
  '+/-3V',
  '+/-2V',
  '+/-1.5V',
  '+/-1V',
  '+/-500mV',
  '+/-160V',
];

List<String> rangeMenuEntries = [
  'CH1',
  'CH2',
  'CH3',
  'MIC',
  'CAP',
  'RES',
  'VOL',
];

List<String> channelEntries = [
  'CH1',
  'CH2',
  'CH3',
  'MIC',
];

String connectDevice = 'Connect Device';
String deviceConnected = 'Device Connected Successfully';
String noDeviceFound = 'No USB Device Found';
List<String> stepsToConnect = [
  'Steps to connect the PSLab Device',
  '1. Connect a micro USB(Mini B) to PSLab',
  '2. Connect the other end of the micro USB cable to a OTG',
  '3. Connect the OTG to the phone'
];
String bluetoothWifiConnection = 'Connect using Bluetooth or Wi-Fi';
String bluetooth = 'BLUETOOTH';
String wifi = 'WIFI';
String whatisPslab = 'What is PSLab Device?';
String pslabUrl = 'https://pslab.io';

String settings = 'Settings';
String start = 'Auto Start';
String autoStartText = 'Auto start app when PSLab device is connected';
String export = 'Export Data Format';
String txtFormat = 'TXT Format';
String csvFormat = 'CSV Format';
String cancel = 'CANCEL';
String currentFormat = 'Current format is ';
String aboutUs = 'About Us';
String pslabDescription =
    'The goal of PSLab is to create an Open Source hardware device (open on all layers) that can be used for experiments by teachers, students and citizen scientists. Our tiny pocket lab provides an array of sensors for doing science and engineering experiments. It provides functions of numerous measurement devices including an oscilloscope, a waveform generator, a frequency generator, a frequency counter, a programmable voltage, current source and as a data logger.';
String feedbackNBugs = 'Feedback & Bugs';
String feedbackForm = 'https://goo.gl/forms/sHlmRAPFmzcGQ27u2';
String website = 'https://pslab.io/';
String github = 'https://github.com/fossasia/';
String facebook = 'https://www.facebook.com/pslabio/';
String x = 'https://x.com/pslabio/';
String youtube = 'https://www.youtube.com/channel/UCQprMsG-raCIMlBudm20iLQ/';
String mail = 'pslab-fossasia@googlegroups.com';
String developers =
    'https://github.com/fossasia/pslab-android/graphs/contributors';
List<String> connectWithUs = [
  'Connect with us',
  'Contact us',
  'Visit our website',
  'Fork us on GitHub',
  'Like us on Facebook',
  'Follow us on X',
  'Watch us on Youtube',
  'Developers'
];
String softwareLicenses = 'Software Licenses';
String accelerometer = 'Accelerometer';
String xAxis = 'x';
String yAxis = 'y';
String zAxis = 'z';
String timeAxisLabel = 'Time(s)';
String accelerationAxisLabel = 'm/s²';
String minValue = 'Min: ';
String maxValue = 'Max: ';
String gyroscopeTitle = "Gyroscope";
String gyroscopeAxisLabel = 'rad/s';
String noData = 'No data available';
String xyPlot = 'XY Plot';
String enablePlot = 'Enable XY Plot';
String trigger = 'Trigger';
String timeBase = 'Timebase';
String timeBaseAndTrigger = 'Timebase & Trigger';
String offsets = 'Offsets';
String dataAnalysis = 'Data Analysis';
String fourierAnalysis = 'Fourier Analysis';
String channels = 'Channels';
String pslabMic = 'PSLab MIC';
String inBuiltMic = 'In-Built MIC';
String ch3Range = 'CH3 (+/- 3.3V)';
String rangeValue = '+/-16V';
String range = 'Range';
String ch2 = 'CH2';
String ch1 = 'CH1';
String luxMeterTitle = 'Lux Meter';
String builtIn = 'Built-In';
String lx = 'Lx';
String maxScaleError = 'Max Scale';
String lightSensorError = 'Light sensor error:';
String lightSensorInitialError = 'Failed to initialize light sensor:';
