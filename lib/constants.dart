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

String multimeter = 'Multimeter';
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
String tryDifferentSearchSuggestion = 'Try a different search term';
String noInstrumentsFoundMessage = 'No instruments found';
String searchInstrumentsHint = 'Search instruments...';
String instrumentsTitle = 'Instruments';
String faqTitle = 'FAQs';
String launchError = 'Could not launch';
String Q = 'Q:';
String A = 'A:';

class FAQConstants {
  static const String whatIsPslab =
      "What is Pocket Science Lab? What can I do with it?";
  static const String whereToBuy = "Where can I buy a Pocket Science Lab?";
  static const String downloadAndroidApp =
      "Where can I download the Android App for Pocket Science Lab?";
  static const String downloadDesktopApp =
      "Where can I download the desktop app for Pocket Science Lab for Windows, Linux and Mac?";
  static const String howToConnect =
      "How can I connect to the device? What kind of USB cable do I need? What is an OTG USB cable?";
  static const String reportBug =
      "I found a bug in one of your apps or hardware. What to do? Where should I report it?";
  static const String recordData =
      "Can I record or save data in the apps and export or import it?";
  static const String usePhoneSensors =
      "My Android phone already has some sensors, can I use them with the PSLab app as well?";
  static const String compatibleSensors =
      "Which external sensors can I use with a PSLab device and the apps? Which ones are compatible?";

  static const String whatIsPslabAnswer =
      "Pocket Science Lab (PSLab) is a small USB powered hardware board that can be used for measurements and experiments. It works as an extension for Android phones or PCs. PSLab comes with a built-in Oscilloscope, Multimeter, Wave Generator, Logic Analyzer, Power Source, and many more instruments. It can also be used as a robotics control app. And, we are constantly adding more digital instruments. PSLab is many devices in one. Simply connect two wires to the relevant pins (description is on the back of the PSLab board) and start measuring. You can use our Open Source Android or desktop app to view and collect the data. You can also plug in hundreds of compatible I²C standard sensors to the PSLab pin slots. It works without the need for programming. So, what experiments you do is just limited to your imagination!";

  static const String whereToBuyAnswer =
      "There is an overview page for shops where you can buy a Pocket Science Lab device in different regions on the website at ";
  static const String whereToBuyLinkText = "https://pslab.io/shop/";
  static const String whereToBuyLinkUrl = "https://pslab.io/shop/";

  static const String downloadAndroidAppAnswer =
      "The app can be downloaded from F-Droid or Play Store. Simply click on the links to be directed over!";
  static const String downloadAndroidAppLinkText = "Playstore";
  static const String downloadAndroidAppLinkUrl =
      "https://play.google.com/store/apps/details?id=io.pslab&hl=en_IN";

  static const String downloadDesktopAppAnswer =
      "We are developing a desktop app for Windows, Linux and Mac in our desktop Git repository. You can find it in the install branch of the project here. The app is still under development. We are using technologies like Electron and Python, that work on all platforms. However, to make the final installer work everywhere requires some tweaks and improvements here and there. So, please expect some glitches. You can use the tracker in the repository to submit issues, bugs and feature requests.";

  static const String howToConnectAnswer =
      "To connect to the device you need an OTG USB cable (OTG = On the go) which is a USB cable that allows connected devices to switch back and forth between the roles of host and device. USB cables that are not OTG compatible will NOT work. It is also possible to extend the PSLab with an ESP WiFi chip or a Bluetooth chip and communicate through these gateways using the Android app. You can refer to the hardware developer documentation and code on GitHub for more details here.";

  static const String reportBugAnswer =
      "We have issue trackers in all our projects. They are currently hosted on GitHub. In order to submit a bug or feature request you need to login to the service.";
  static const String reportBugLinkText =
      "A list of our PSLab repositories is here";
  static const String reportBugLinkUrl = "https://github.com/fossasia";

  static const String recordDataAnswer =
      "Yes, we have implemented a record and play function or a way to save and open configurations in the instruments on the Android and desktop app. Data you record can be imported into the apps and viewed. This feature is still under heavy development, but works well in most places. You can find it in the top bar of the apps. There are buttons to record, play, save and open data.";

  static const String usePhoneSensorsAnswer =
      "Yes, absolutely. You can install the PSLab Android app (Play Store, Fdroid) on your phone and use it with devices such as Luxmeter or Compass. We are adding support for more built-in sensors step by step.";

  static const String compatibleSensorsAnswer =
      "In our apps we use the industry standard I²C (Wikipedia). You can get the data from sensors that are connected to the device through the USB port using an OTG USB cable (OTG = On the go) which is a USB cable that allows connected devices to switch back and forth between the roles of host and device. For the transfer we use UART (universal asynchronous receiver-transmitter, Wikipedia). Many sensors can be used with specific instruments, e.g. Barometer, Thermometer, Gyroscope etc. You can access the configuration for sensors in the instrument settings on the top right burger menu of each instrument. All sensors using the I²C standard are compatible with the device. There are connection pins for analogue and digital sensors. You find the description of the pins on the back of the device. Even if there is no specific instrument in one of our apps yet, you can still view and store the raw data using the Oscilloscope instrument component. There is a page with a list of recommended sensors on the website.";
}

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
String degreeSymbol = '°';
String enterAngleRange = 'Enter angle (0 - 360)';
String errorCannotBeEmpty = 'Cannot be empty';
String servoValidNumberRange = 'Please enter a valid number between 0 and 360';
String ok = 'Ok';
String roboticArm = 'Robotic Arm';
String play = 'Play';
String pause = 'Pause';
String stop = 'Stop';
String controls = 'Controls';
String saveData = 'Save Data';
String showGuide = 'Show Guide';
String showLoggedDataKey = 'show_logged_data';
String showLoggedData = 'Show Logged Data';
String setAngle = 'Set angle for Servo';
String angleDialog = 'AngleDialog';
List<String> servoLabels = [
  'Servo 1',
  'Servo 2',
  'Servo 3',
  'Servo 4',
];
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
String noSignal = 'No signal found.';
String autoScale = 'AUTO';
String automatedMeasurements = 'Automated Measurements';
String luxMeterTitle = 'Lux Meter';
String builtIn = 'Built-In';
String lx = 'Lx';
String maxScaleError = 'Max Scale';
String lightSensorError = 'Light sensor error:';
String lightSensorInitialError = 'Failed to initialize light sensor:';
String soundMeterError = 'Sound sensor error:';
String soundMeterInitialError = 'Sound sensor initialization error:';
String db = 'dB';
String soundMeterTitle = 'Sound Meter';
String playBackSummary = 'Playback Summary';
String servo = 'Servo:';
String percentage = '%';
String pwmWaveForm = 'PWM Waveform';
String close = 'Close';
String timeMillisecond = 'Time (ms)';
String low = 'LOW';
String high = 'HIGH';
String clearTimelineTitle = 'Clear Timeline?';
String clearTimelineConfirmation =
    'Are you sure you want to clear the timeline?';
String avgAngleLabel = 'Avg Angle';
String maxAngleLabel = 'Max Angle';
String minAngleLabel = 'Min Angle';
String avgDutyLabel = 'Avg Duty';
String maxDutyLabel = 'Max Duty';
String minDutyLabel = 'Min Duty';
String controlsTitle = 'Controls';
String manualLabel = 'Manual';
String feedbackLabel = 'Feedback';
String duration1Min = '1min';
String duration2Min = '2min';
String frequency50Hz = '50Hz';
String frequency100Hz = '100Hz';
String angle180 = '180';
String angle360 = '360';
String angle180Display = '180°';
String angle360Display = '360°';
String clear = 'Clear';
String hzSuffix = 'Hz';
String clearTimelineTooltip = 'Clear Timeline';
String manualMode = 'Manual Mode';
String frequencyChange = 'Stop playback to change frequency.';
String playBackStop = 'Playback stopped';
String soundMeterIntro = 'Sound meter Introduction';
String soundMeterDesc =
    'To measure the loudness in the environment in decibel(dB)';
String luxMeterDesc =
    'The Lux meter can be used to measure the ambient light intensity. This instruments is compatible with either the built-in light sensor on any Android device or the BH-1750 light sensor.';
String luxMeterSensorIntro =
    'If you want to use the sensor BH-1750, connect the sensor to PSLab device as shown below';
String luxMeterBulletPoint1 =
    'The above pin configuration has to be same except for the pin GND. GND is meant for Ground and any of the PSLab device GND pins can be used since they are common.';
String luxMeterBulletPoint2 =
    'Select sensor by going to the Configure tab from the bottom navigation bar and choose BHT-1750 in the drop down menu under Select Sensor.';
String gyroscopeIntro =
    'Gyroscope is used to measure rate of rotation of a body along X, Y, and Z axis.';
String gyroscopeDesc =
    'Orientation of the positive X, Y, and Z axes. For any positive axis on the device, clockwise rotation outputs negative values, and counterclockwise rotation outputs positive values.';
String accelerometerIntro =
    'Accelerometer is used to measure acceleration of a body along the X, Y, and Z axis.';
String accelerometerImageDesc =
    'The figure above shows the direction of all the three axis when the mobile is held straight.';
String accelerometerSteps = 'Steps to measure acceleration in PSLab app:';
String accelerometerBulletPoint1 =
    'Hold the device as shown in the above figure.';
String accelerometerBulletPoint2 =
    'Accelerate the device along any one or multiple axis.';
String accelerometerBulletPoint3 =
    'Observe the values in the cards or the plotted graph of any particular axis.';
String accelerometerDesc =
    'The Accelerometer instrument can also be used to measure the acceleration of a moving body by placing the device on/inside the body and then accelerating the body.';
String accelerometerNote =
    'NOTE: Don\'t accelerate the body if the device isn\'t properly attached else the device could be damaged.';
String hideGuide = 'Hide Guide';
String minLabel = 'Min';
String maxLabel = 'Max';
String avgLabel = 'Avg';
String loggedDataMenu = 'Logged Data';
String configFileMenu = 'Generate Config File';
String documentationMenu = 'Documentation';
String rateApp = 'Rate App';
String buyPsLabMenu = 'Buy PSLab';
String faqMenu = 'FAQ';
String shareAppMenu = 'Share App';
String privacyPolicyMenu = 'Privacy Policy';
