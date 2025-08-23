// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get oscilloscope => 'Oscilloscope';

  @override
  String get multimeter => 'Multimeter';

  @override
  String get logicAnalyzer => 'Logic Analyzer';

  @override
  String get sensors => 'Sensors';

  @override
  String get waveGenerator => 'Wave Generator';

  @override
  String get powerSource => 'Power Source';

  @override
  String get luxMeter => 'Lux Meter';

  @override
  String get accelerometer => 'Accelerometer';

  @override
  String get barometer => 'Barometer';

  @override
  String get compass => 'Compass';

  @override
  String get gyroscope => 'Gyroscope';

  @override
  String get thermometer => 'Thermometer';

  @override
  String get roboticArm => 'Robotic Arm';

  @override
  String get gasSensor => 'Gas Sensor';

  @override
  String get dustSensor => 'Dust Sensor';

  @override
  String get soundMeter => 'Sound Meter';

  @override
  String get oscilloscopeDesc =>
      'Allows observation of varying signal voltages';

  @override
  String get multimeterDesc =>
      'Measure voltage, current, resistance and capacitance';

  @override
  String get logicAnalyzerDesc =>
      'Captures and displays signals from digital systems';

  @override
  String get sensorsDesc =>
      'Allows logging of data returned by sensor connected';

  @override
  String get waveGeneratorDesc =>
      'Generates arbitrary analog and digital waveforms';

  @override
  String get powerSourceDesc => 'Generates programmable voltage and currents';

  @override
  String get luxMeterDesc => 'Measures the ambient light intensity';

  @override
  String get accelerometerDesc =>
      'Measures the Linear acceleration in XYZ directions';

  @override
  String get barometerDesc => 'Measures the atmospheric pressure';

  @override
  String get compassDesc =>
      'Three axes magnetometer pointing to magnetic north';

  @override
  String get gyroscopeDesc => 'Measures rate of rotation about XYZ axis';

  @override
  String get thermometerDesc => 'To measure the ambient temperature';

  @override
  String get roboticArmDesc => 'Controls servos of a robotic arm';

  @override
  String get gasSensorDesc =>
      'Air quality sensor for detecting a wide range of gases, including NH3, NOx, alcohol, benzene, smoke and CO2';

  @override
  String get dustSensorDesc =>
      'Dust sensor is used to measure air quality in terms of particles per square meter';

  @override
  String get soundMeterDesc =>
      'To measure the loudness in the environment in decibel(dB)';

  @override
  String get yAxisRange16V => '+/-16V';

  @override
  String get yAxisRange8V => '+/-8V';

  @override
  String get yAxisRange4V => '+/-4V';

  @override
  String get yAxisRange3V => '+/-3V';

  @override
  String get yAxisRange2V => '+/-2V';

  @override
  String get yAxisRange1_5V => '+/-1.5V';

  @override
  String get yAxisRange1V => '+/-1V';

  @override
  String get yAxisRange500mV => '+/-500mV';

  @override
  String get yAxisRange160V => '+/-160V';

  @override
  String get oscilloscopeBulletPoint1 =>
      'Oscilloscope in PSLab gives out many of the functionalities of a commercially available Oscilloscope. It has 4-channels with a MIC in, 2 Sine wave generators and 4 PWM square wave generators, can change the timebase, analyses signal and does Sine and Square wave fitting and plots channel to channel voltage.';

  @override
  String get oscilloscopeBulletPoint2 =>
      'To read from a Sine wave or a square wave, you can connect the Output wave pin and a Channel to the Oscilloscope as follows.';

  @override
  String get oscilloscopeBulletPoint3 =>
      'Above shown figure has a connection from SQ1 to CH1 and SI1 to CH2.';

  @override
  String get oscilloscopeBulletPoint4 =>
      'Once you have generated a wave from the Wave Generator instrument connect the relevant pins and observe it from the Oscilloscope by ticking the relevant channel in Channel parameters. If you are using CH1 pin, select CH1 from channel parameters.';

  @override
  String get channelParameters => 'Channel Parameters';

  @override
  String get channelParametersIntro =>
      'From this Setting, you can change the Channel that needs to be osbserved from the plot.';

  @override
  String get channelParametersBulletPoint1 =>
      'Tick the check boxes to plot the relevant Channel.';

  @override
  String get channelParametersBulletPoint2 =>
      'Can change the Y-axis voltage range in the plot using the spinner next to the Channel.';

  @override
  String get channelParametersBulletPoint3 =>
      'For the fourth Channel, you can choose either In-built microphone or an external mic. If you are to use an external microphone, the connection is as follows.';

  @override
  String get channelParametersBulletPoint4 =>
      'The Positive terminal of the MIC should be connected with the MIC pin and negative terminal should be conneted with the GND pin of PSLab device.';

  @override
  String get timebaseIntro =>
      'This setting gives you the control of the range of Time axis(X-axis).';

  @override
  String get timebaseBulletPoint1 =>
      'The timebase slidder can be used to increase or decrease the signal capturing time. Can change the range from 875.0 micro seconds to 102.4 milli seconds.';

  @override
  String get timebaseBulletPoint2 =>
      'This will be useful to capture periodic wave signals in the given range for analysis.';

  @override
  String get timebaseBulletPoint3 =>
      'You can use the trigger to set voltage value, so that when the signal exceeds the given value, plot will halt.';

  @override
  String get dataAnalysisBulletPoint1 =>
      'Using this Setting, the mathematical function of the analysed signal can be found. Can choose the Wave type from Sine or Square and the Channel that needs to be analyzed.';

  @override
  String get dataAnalysisBulletPoint2 =>
      'Furthermore, analyzed signal\'s Fourier transform can be observed by checking Fourier Transforms check box.';

  @override
  String get xyPlotBulletPoint1 =>
      'This is used to plot the Channel to Channel voltage in a X-Y plot having voltage as the unit for the both axes relevant for the corresponding Channels.';

  @override
  String get channel1 => 'CH1';

  @override
  String get channel2 => 'CH2';

  @override
  String get channel3 => 'CH3';

  @override
  String get mic => 'MIC';

  @override
  String get capacitance => 'CAP';

  @override
  String get resistance => 'RES';

  @override
  String get voltageUnit => 'VOL';

  @override
  String get multimeterTitle => 'Multimeter';

  @override
  String get defaultValue => '0.00';

  @override
  String get unitVolts => 'Volts';

  @override
  String get knobMarkerCh1 => 'CH1';

  @override
  String get knobMarkerCap => 'CAP';

  @override
  String get knobMarkerVol => 'VOL';

  @override
  String get knobMarkerRes => 'RES';

  @override
  String get knobMarkerLa1 => 'LA1';

  @override
  String get knobMarkerLa2 => 'LA2';

  @override
  String get knobMarkerLa3 => 'LA3';

  @override
  String get knobMarkerLa4 => 'LA4';

  @override
  String get knobMarkerCh3 => 'CH3';

  @override
  String get knobMarkerCh2 => 'CH2';

  @override
  String get voltage => 'Voltage';

  @override
  String get unitHz => 'Hz';

  @override
  String get countPulse => 'Count Pulse';

  @override
  String get measure => 'Measure';

  @override
  String get connectDevice => 'Connect Device';

  @override
  String get deviceConnected => 'Device Connected Successfully';

  @override
  String get noDeviceFound => 'No USB Device Found';

  @override
  String get stepsToConnectTitle => 'Steps to connect the PSLab Device';

  @override
  String get step1ConnectMicroUsb => '1. Connect a micro USB(Mini B) to PSLab';

  @override
  String get step2ConnectOtg =>
      '2. Connect the other end of the micro USB cable to a OTG';

  @override
  String get step3ConnectPhone => '3. Connect the OTG to the phone';

  @override
  String get bluetoothWifiConnection => 'Connect using Bluetooth or Wi-Fi';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get whatIsPslab => 'What is PSLab Device?';

  @override
  String get pslabUrl => 'https://pslab.io';

  @override
  String get logicAnalyzerTitle => 'Logic Analyzer';

  @override
  String get channelSelection => 'Channel Selection';

  @override
  String get logicAnalyzerAxisTitle => 'Time (µs)';

  @override
  String get noChartDataAvailable => 'No chart data available';

  @override
  String get noOfChannelsOne => '1';

  @override
  String get noOfChannelsTwo => '2';

  @override
  String get noOfChannelsThree => '3';

  @override
  String get noOfChannelsFour => '4';

  @override
  String get channelLA1 => 'LA1';

  @override
  String get channelLA2 => 'LA2';

  @override
  String get channelLA3 => 'LA3';

  @override
  String get channelLA4 => 'LA4';

  @override
  String get analysisOptionEveryEdge => 'Every Edge';

  @override
  String get analysisOptionEveryFallingEdge => 'Every Falling Edge';

  @override
  String get analysisOptionEveryRisingEdge => 'Every Rising Edge';

  @override
  String get analysisOptionEveryFourthRisingEdge => 'Every Fourth Rising Edge';

  @override
  String get analysisOptionDisabled => 'Disabled';

  @override
  String get powerSourceTitle => 'Power Source';

  @override
  String get pinPV1 => 'PV1';

  @override
  String get pinPV2 => 'PV2';

  @override
  String get pinPV3 => 'PV3';

  @override
  String get pinPCS => 'PCS';

  @override
  String get powerSourceIntro =>
      'PSLab device can generate voltages from +5V to -5V at a resolution of 10mV';

  @override
  String get powerSourceBulletPoint1 =>
      'Connect one wire to PV1 and another wire to GND to generate voltages between +5V to -5V.';

  @override
  String get powerSourceBulletPoint2 =>
      'Similarly connect wires between PV2 to generate voltages between +3.3V to -3.3V.';

  @override
  String get powerSourceBulletPoint3 =>
      'Use PV3 pin to generate voltages between 0V to +3.3V.';

  @override
  String get powerSourceBulletPoint4 =>
      'PCS pin is used to supply a constant current between PCS pin and a GND pin in a range of 3.3mA.';

  @override
  String get analog => 'Analog';

  @override
  String get digital => 'Digital';

  @override
  String get wave1 => 'Wave 1';

  @override
  String get wave2 => 'Wave 2';

  @override
  String get sqr1 => 'sqr1';

  @override
  String get sqr2 => 'sqr2';

  @override
  String get sqr3 => 'sqr3';

  @override
  String get sqr4 => 'sqr4';

  @override
  String get freq => 'Freq';

  @override
  String get phase => 'Phase';

  @override
  String get duty => 'Duty';

  @override
  String get produceSound => 'Produce Sound';

  @override
  String get frequency => 'Frequency';

  @override
  String get phaseOffset => 'Phase Offset';

  @override
  String get unitDeg => '°';

  @override
  String get unitPercentage => '%';

  @override
  String get sine => 'Sine';

  @override
  String get tri => 'Tri';

  @override
  String get pwm => 'pwm';

  @override
  String get waveGeneratorIntro =>
      'The wave generator can be used to generate different types of waves like Sine wave, square wave and saw-tooth wave allow us to change their characteristics like frequency, phase and duty. It also allows us to produce PWM signals having different phase and duty.';

  @override
  String get sineWaveCaption => 'To generate Sine wave or Saw-Tooth wave:';

  @override
  String get sineWaveBulletPoint1 =>
      'Connect the Wave pins S1 and S2 to the channel pins CH1, CH2 as shown in the above figure.';

  @override
  String get sineWaveBulletPoint2 =>
      'Select the Wave1 button for S1 pin and Wave2 button for S2 pin.';

  @override
  String get sineWaveBulletPoint3 =>
      'Press Sine image button for Sine wave and Saw-Tooth image button for Saw-Tooth wave.';

  @override
  String get sineWaveBulletPoint4 =>
      'Set their respective frequencies and phase difference(optional) using buttons in waveform panel.';

  @override
  String get sineWaveBulletPoint5 =>
      'Press the View button to view the waves in oscilloscope.';

  @override
  String get squareWaveCaption => 'To generate Square wave:';

  @override
  String get squareWaveBulletPoint1 =>
      'Connect the Wave pins SQ1 to the channel pin CH1 as shown in the above figure.';

  @override
  String get squareWaveBulletPoint2 =>
      'Ensure the mode is selected to the Square, if not press the mode button to switch to Square mode.';

  @override
  String get squareWaveBulletPoint3 => 'Select the SQ1 button';

  @override
  String get squareWaveBulletPoint4 => 'Set its Frequency and Duty Cycle';

  @override
  String get squareWaveBulletPoint5 =>
      'Press the View button to view the square wave in oscilloscope.';

  @override
  String get pwmCaption => 'Similarly, to produce four different PWM signals:';

  @override
  String get pwmBulletPoint1 =>
      'Switch over to PWM mode(In this mode S1 and S2 pin will be disabled).';

  @override
  String get pwmBulletPoint2 => 'Set the common frequency for all the SQ pins.';

  @override
  String get pwmBulletPoint3 => 'Set the duty and phase for all the SQ pins.';

  @override
  String get pwmBulletPoint4 =>
      'Press View button to generate the PWM signals.';

  @override
  String get analyze => 'Analyze';

  @override
  String get settings => 'Settings';

  @override
  String get autoStart => 'Auto Start';

  @override
  String get autoStartText => 'Auto start app when PSLab device is connected';

  @override
  String get export => 'Export Data Format';

  @override
  String get txtFormat => 'TXT Format';

  @override
  String get csvFormat => 'CSV Format';

  @override
  String get cancel => 'Cancel';

  @override
  String get currentFormat => 'Current format is ';

  @override
  String get aboutUs => 'About Us';

  @override
  String get pslabDescription =>
      'The goal of PSLab is to create an Open Source hardware device (open on all layers) that can be used for experiments by teachers, students and citizen scientists. Our tiny pocket lab provides an array of sensors for doing science and engineering experiments. It provides functions of numerous measurement devices including an oscilloscope, a waveform generator, a frequency generator, a frequency counter, a programmable voltage, current source and as a data logger.';

  @override
  String get feedbackNBugs => 'Feedback & Bugs';

  @override
  String get feedbackForm => 'https://goo.gl/forms/sHlmRAPFmzcGQ27u2';

  @override
  String get website => 'https://pslab.io/';

  @override
  String get github => 'https://github.com/fossasia/';

  @override
  String get facebook => 'https://www.facebook.com/pslabio/';

  @override
  String get x => 'https://x.com/pslabio/';

  @override
  String get youtube =>
      'https://www.youtube.com/channel/UCQprMsG-raCIMlBudm20iLQ/';

  @override
  String get mail => 'pslab-fossasia@googlegroups.com';

  @override
  String get developers =>
      'https://github.com/fossasia/pslab-android/graphs/contributors';

  @override
  String get connectWithUs => 'Connect with us';

  @override
  String get contactUs => 'Contact us';

  @override
  String get visitOurWebsite => 'Visit our website';

  @override
  String get forkUsOnGithub => 'Fork us on GitHub';

  @override
  String get likeUsOnFacebook => 'Like us on Facebook';

  @override
  String get followUsOnX => 'Follow us on X';

  @override
  String get watchUsOnYoutube => 'Watch us on Youtube';

  @override
  String get developersLink => 'Developers';

  @override
  String get softwareLicenses => 'Software Licenses';

  @override
  String get tryDifferentSearchSuggestion => 'Try a different search term';

  @override
  String get noInstrumentsFoundMessage => 'No instruments found';

  @override
  String get searchInstrumentsHint => 'Search instruments...';

  @override
  String get instrumentsTitle => 'Instruments';

  @override
  String get faqTitle => 'FAQs';

  @override
  String get launchError => 'Could not launch';

  @override
  String get faqQ => 'Q:';

  @override
  String get faqA => 'A:';

  @override
  String get faqWhatIsPslab =>
      'What is Pocket Science Lab? What can I do with it?';

  @override
  String get faqWhereToBuy => 'Where can I buy a Pocket Science Lab?';

  @override
  String get faqDownloadAndroidApp =>
      'Where can I download the Android App for Pocket Science Lab?';

  @override
  String get faqDownloadDesktopApp =>
      'Where can I download the desktop app for Pocket Science Lab for Windows, Linux and Mac?';

  @override
  String get faqHowToConnect =>
      'How can I connect to the device? What kind of USB cable do I need? What is an OTG USB cable?';

  @override
  String get faqReportBug =>
      'I found a bug in one of your apps or hardware. What to do? Where should I report it?';

  @override
  String get faqRecordData =>
      'Can I record or save data in the apps and export or import it?';

  @override
  String get faqUsePhoneSensors =>
      'My Android phone already has some sensors, can I use them with the PSLab app as well?';

  @override
  String get faqCompatibleSensors =>
      'Which external sensors can I use with a PSLab device and the apps? Which ones are compatible?';

  @override
  String get faqWhatIsPslabAnswer =>
      'Pocket Science Lab (PSLab) is a small USB powered hardware board that can be used for measurements and experiments. It works as an extension for Android phones or PCs. PSLab comes with a built-in Oscilloscope, Multimeter, Wave Generator, Logic Analyzer, Power Source, and many more instruments. It can also be used as a robotics control app. And, we are constantly adding more digital instruments. PSLab is many devices in one. Simply connect two wires to the relevant pins (description is on the back of the PSLab board) and start measuring. You can use our Open Source Android or desktop app to view and collect the data. You can also plug in hundreds of compatible I²C standard sensors to the PSLab pin slots. It works without the need for programming. So, what experiments you do is just limited to your imagination!';

  @override
  String get faqWhereToBuyAnswer =>
      'There is an overview page for shops where you can buy a Pocket Science Lab device in different regions on the website at ';

  @override
  String get faqWhereToBuyLinkText => 'https://pslab.io/shop/';

  @override
  String get faqWhereToBuyLinkUrl => 'https://pslab.io/shop/';

  @override
  String get faqDownloadAndroidAppAnswer =>
      'The app can be downloaded from F-Droid or Play Store. Simply click on the links to be directed over!';

  @override
  String get faqDownloadAndroidAppLinkText => 'Playstore';

  @override
  String get faqDownloadAndroidAppLinkUrl =>
      'https://play.google.com/store/apps/details?id=io.pslab&hl=en_IN';

  @override
  String get faqDownloadDesktopAppAnswer =>
      'We are developing a desktop app for Windows, Linux and Mac in our desktop Git repository. You can find it in the install branch of the project here. The app is still under development. We are using technologies like Electron and Python, that work on all platforms. However, to make the final installer work everywhere requires some tweaks and improvements here and there. So, please expect some glitches. You can use the tracker in the repository to submit issues, bugs and feature requests.';

  @override
  String get faqHowToConnectAnswer =>
      'To connect to the device you need an OTG USB cable (OTG = On the go) which is a USB cable that allows connected devices to switch back and forth between the roles of host and device. USB cables that are not OTG compatible will NOT work. It is also possible to extend the PSLab with an ESP WiFi chip or a Bluetooth chip and communicate through these gateways using the Android app. You can refer to the hardware developer documentation and code on GitHub for more details here.';

  @override
  String get faqReportBugAnswer =>
      'We have issue trackers in all our projects. They are currently hosted on GitHub. In order to submit a bug or feature request you need to login to the service.';

  @override
  String get faqReportBugLinkText => 'A list of our PSLab repositories is here';

  @override
  String get faqReportBugLinkUrl => 'https://github.com/fossasia';

  @override
  String get faqRecordDataAnswer =>
      'Yes, we have implemented a record and play function or a way to save and open configurations in the instruments on the Android and desktop app. Data you record can be imported into the apps and viewed. This feature is still under heavy development, but works well in most places. You can find it in the top bar of the apps. There are buttons to record, play, save and open data.';

  @override
  String get faqUsePhoneSensorsAnswer =>
      'Yes, absolutely. You can install the PSLab Android app (Play Store, Fdroid) on your phone and use it with devices such as Luxmeter or Compass. We are adding support for more built-in sensors step by step.';

  @override
  String get faqCompatibleSensorsAnswer =>
      'In our apps we use the industry standard I²C (Wikipedia). You can get the data from sensors that are connected to the device through the USB port using an OTG USB cable (OTG = On the go) which is a USB cable that allows connected devices to switch back and forth between the roles of host and device. For the transfer we use UART (universal asynchronous receiver-transmitter, Wikipedia). Many sensors can be used with specific instruments, e.g. Barometer, Thermometer, Gyroscope etc. You can access the configuration for sensors in the instrument settings on the top right burger menu of each instrument. All sensors using the I²C standard are compatible with the device. There are connection pins for analogue and digital sensors. You find the description of the pins on the back of the device. Even if there is no specific instrument in one of our apps yet, you can still view and store the raw data using the Oscilloscope instrument component. There is a page with a list of recommended sensors on the website.';

  @override
  String get accelerometerTitle => 'Accelerometer';

  @override
  String get xAxis => 'x';

  @override
  String get yAxis => 'y';

  @override
  String get zAxis => 'z';

  @override
  String get timeAxisLabel => 'Time(s)';

  @override
  String get accelerationAxisLabel => 'm/s²';

  @override
  String get minValue => 'Min: ';

  @override
  String get maxValue => 'Max: ';

  @override
  String get gyroscopeTitle => 'Gyroscope';

  @override
  String get gyroscopeAxisLabel => 'rad/s';

  @override
  String get noData => 'No data available';

  @override
  String get degreeSymbol => '°';

  @override
  String get enterAngleRange => 'Enter angle (0 - 360)';

  @override
  String get errorCannotBeEmpty => 'Cannot be empty';

  @override
  String get servoValidNumberRange =>
      'Please enter a valid number between 0 and 360';

  @override
  String get ok => 'OK';

  @override
  String get roboticArmTitle => 'Robotic Arm';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get controls => 'Controls';

  @override
  String get saveData => 'Save Data';

  @override
  String get showGuide => 'Show Guide';

  @override
  String get showLoggedData => 'Show Logged Data';

  @override
  String get setAngle => 'Set angle for Servo';

  @override
  String get angleDialog => 'AngleDialog';

  @override
  String get servo1 => 'Servo 1';

  @override
  String get servo2 => 'Servo 2';

  @override
  String get servo3 => 'Servo 3';

  @override
  String get servo4 => 'Servo 4';

  @override
  String get xyPlot => 'XY Plot';

  @override
  String get enablePlot => 'Enable XY Plot';

  @override
  String get trigger => 'Trigger';

  @override
  String get timeBase => 'Timebase';

  @override
  String get timeBaseAndTrigger => 'Timebase & Trigger';

  @override
  String get offsets => 'Offsets';

  @override
  String get dataAnalysis => 'Data Analysis';

  @override
  String get fourierAnalysis => 'Fourier Analysis';

  @override
  String get channels => 'Channels';

  @override
  String get pslabMic => 'PSLab MIC';

  @override
  String get inBuiltMic => 'In-Built MIC';

  @override
  String get ch3Range => 'CH3 (+/- 3.3V)';

  @override
  String get rangeValue => '+/-16V';

  @override
  String get range => 'Range';

  @override
  String get ch2 => 'CH2';

  @override
  String get ch1 => 'CH1';

  @override
  String get noSignal => 'No signal found.';

  @override
  String get autoScale => 'AUTO';

  @override
  String get automatedMeasurements => 'Automated Measurements';

  @override
  String get luxMeterTitle => 'Lux Meter';

  @override
  String get builtIn => 'Built-In';

  @override
  String get lx => 'Lx';

  @override
  String get maxScaleError => 'Max Scale';

  @override
  String get lightSensorError => 'Light sensor error:';

  @override
  String get lightSensorInitialError => 'Failed to initialize light sensor:';

  @override
  String get barometerTitle => 'Barometer';

  @override
  String get atm => 'atm';

  @override
  String get barometerSensorInitialError =>
      'Failed to initialize barometer sensor:';

  @override
  String get barometerSensorError => 'Barometer sensor error occurred';

  @override
  String get barometerNotAvailable =>
      'Barometer sensor not available on this device';

  @override
  String get meterUnit => 'm';

  @override
  String get altitudeLabel => 'Altitude';

  @override
  String get soundMeterError => 'Sound sensor error:';

  @override
  String get soundMeterInitialError => 'Sound sensor initialization error:';

  @override
  String get db => 'dB';

  @override
  String get soundMeterTitle => 'Sound Meter';

  @override
  String get noLightSensor => 'Device does not have a light sensor';

  @override
  String get lightSensorErrorDetails => 'Light sensor error details:';

  @override
  String get lightSensorErrorLog =>
      'No light sensor data received - sensor may not be available';

  @override
  String get playBackSummary => 'Playback Summary';

  @override
  String get servo => 'Servo:';

  @override
  String get percentage => '%';

  @override
  String get pwmWaveForm => 'PWM Waveform';

  @override
  String get close => 'Close';

  @override
  String get timeMillisecond => 'Time (ms)';

  @override
  String get low => 'Low';

  @override
  String get high => 'High';

  @override
  String get clearTimelineTitle => 'Clear Timeline?';

  @override
  String get clearTimelineConfirmation =>
      'Are you sure you want to clear the timeline?';

  @override
  String get avgAngleLabel => 'Avg Angle';

  @override
  String get maxAngleLabel => 'Max Angle';

  @override
  String get minAngleLabel => 'Min Angle';

  @override
  String get avgDutyLabel => 'Avg Duty';

  @override
  String get maxDutyLabel => 'Max Duty';

  @override
  String get minDutyLabel => 'Min Duty';

  @override
  String get controlsTitle => 'Controls';

  @override
  String get manualLabel => 'Manual';

  @override
  String get feedbackLabel => 'Feedback';

  @override
  String get duration1Min => '1min';

  @override
  String get duration2Min => '2min';

  @override
  String get frequency50Hz => '50Hz';

  @override
  String get frequency100Hz => '100Hz';

  @override
  String get angle180 => '180';

  @override
  String get angle360 => '360';

  @override
  String get angle180Display => '180°';

  @override
  String get angle360Display => '360°';

  @override
  String get clear => 'Clear';

  @override
  String get hzSuffix => 'Hz';

  @override
  String get clearTimelineTooltip => 'Clear Timeline';

  @override
  String get manualMode => 'Manual Mode';

  @override
  String get frequencyChange => 'Stop playback to change frequency.';

  @override
  String get playBackStop => 'Playback stopped';

  @override
  String get soundMeterIntro => 'Sound meter Introduction';

  @override
  String get soundMeterDescFull =>
      'To measure the loudness in the environment in decibel(dB)';

  @override
  String get luxMeterDescFull =>
      'The Lux meter can be used to measure the ambient light intensity. This instruments is compatible with either the built-in light sensor on any Android device or the BH-1750 light sensor.';

  @override
  String get luxMeterSensorIntro =>
      'If you want to use the sensor BH-1750, connect the sensor to PSLab device as shown below';

  @override
  String get luxMeterBulletPoint1 =>
      'The above pin configuration has to be same except for the pin GND. GND is meant for Ground and any of the PSLab device GND pins can be used since they are common.';

  @override
  String get luxMeterBulletPoint2 =>
      'Select sensor by going to the Configure tab from the bottom navigation bar and choose BHT-1750 in the drop down menu under Select Sensor.';

  @override
  String get gyroscopeIntro =>
      'Gyroscope is used to measure rate of rotation of a body along X, Y, and Z axis.';

  @override
  String get gyroscopeDescFull =>
      'Orientation of the positive X, Y, and Z axes. For any positive axis on the device, clockwise rotation outputs negative values, and counterclockwise rotation outputs positive values.';

  @override
  String get accelerometerIntro =>
      'Accelerometer is used to measure acceleration of a body along the X, Y, and Z axis.';

  @override
  String get accelerometerImageDesc =>
      'The figure above shows the direction of all the three axis when the mobile is held straight.';

  @override
  String get accelerometerSteps =>
      'Steps to measure acceleration in PSLab app:';

  @override
  String get accelerometerBulletPoint1 =>
      'Hold the device as shown in the above figure.';

  @override
  String get accelerometerBulletPoint2 =>
      'Accelerate the device along any one or multiple axis.';

  @override
  String get accelerometerBulletPoint3 =>
      'Observe the values in the cards or the plotted graph of any particular axis.';

  @override
  String get accelerometerDescFull =>
      'The Accelerometer instrument can also be used to measure the acceleration of a moving body by placing the device on/inside the body and then accelerating the body.';

  @override
  String get accelerometerNote =>
      'NOTE: Don\'t accelerate the body if the device isn\'t properly attached else the device could be damaged.';

  @override
  String get hideGuide => 'Hide Guide';

  @override
  String get minLabel => 'Min';

  @override
  String get maxLabel => 'Max';

  @override
  String get avgLabel => 'Avg';

  @override
  String get loggedDataMenu => 'Logged Data';

  @override
  String get configFileMenu => 'Generate Config File';

  @override
  String get documentationMenu => 'Documentation';

  @override
  String get rateApp => 'Rate App';

  @override
  String get buyPsLabMenu => 'Buy PSLab';

  @override
  String get faqMenu => 'FAQ';

  @override
  String get shareAppMenu => 'Share App';

  @override
  String get privacyPolicyMenu => 'Privacy Policy';

  @override
  String get shopLink => 'https://pslab.io/shop/';

  @override
  String get shopError => 'Could not open the shop link';

  @override
  String get showLuxmeterConfig => 'Lux Meter Configurations';

  @override
  String get luxmeterConfigurations => 'Lux Meter Configurations';

  @override
  String get updatePeriod => 'Update Period';

  @override
  String get luxmeterUpdatePeriodHint =>
      'Please provide time interval at which data will be updated (100 ms to 1000 ms)';

  @override
  String get highLimit => 'High Limit';

  @override
  String get luxmeterHighLimitHint =>
      'Please provide the maximum limit of lux value to be recorded (10 Lx to 10000 Lx)';

  @override
  String get sensorGain => 'Sensor Gain';

  @override
  String get sensorGainHint => 'Please set gain of the sensor';

  @override
  String get locationData => 'Include Location Data';

  @override
  String get locationDataHint => 'Include the location data in the logged file';

  @override
  String get activeSensor => 'Active Sensor';

  @override
  String get ms => 'ms';

  @override
  String get inBuiltSensor => 'In-built Sensor';

  @override
  String get updatePeriodErrorMessage =>
      'Entered update period is not within the limits!';

  @override
  String get highLimitErrorMessage =>
      'Entered High limit is not within the limits!';

  @override
  String get baroMeterBulletPoint1 =>
      'The Barometer can be used to measure Atmospheric pressure. This instrument is compatible with either the built in pressure sensor on any android device or the BMP-180 pressure sensor';

  @override
  String get baroMeterBulletPoint2 =>
      'If you want to use the sensor BMP-180, connect the sensor to PSLab device as shown in the figure.';

  @override
  String get baroMeterBulletPoint3 =>
      'The above pin configuration has to be same except for the pin GND. GND is meant for Ground and any of the PSLab device GND pins can be used since they are common.';

  @override
  String get baroMeterBulletPoint4 =>
      'Select the sensor by going to the Configure tab from the bottom navigation bar and choose BMP-180 in the drop down menu under Select Sensor.';

  @override
  String get magnetometerError => 'Magnetometer error:';

  @override
  String get accelerometerError => 'Accelerometer error:';

  @override
  String get compassTitle => 'Compass';

  @override
  String get parallelToGround => 'Select axes parallel to ground';

  @override
  String get sharingMessage => 'Sharing PSLab Data';

  @override
  String get delete => 'Delete';

  @override
  String get thermometerTitle => 'Thermometer';

  @override
  String get thermometerIntro =>
      'Thermometer instrument is used to measure ambient temprature. It can be measured using inbuilt ambient temprature sensor or through SHT21.';

  @override
  String get celsius => '°C';

  @override
  String get temperatureSensorError => 'Temperature sensor error:';

  @override
  String get temperatureSensorInitialError =>
      'Temperature sensor initialization error:';

  @override
  String get temperatureSensorUnavailableMessage =>
      'Ambient temperature sensor is not available on this device';

  @override
  String get deleteHint => 'Are you sure you want to delete this file?';

  @override
  String get deleteFile => 'Delete File';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteCautionMessage =>
      'Are you sure you want to delete all logged data for this instrument?';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get noLoggedData => 'No logged data found.';

  @override
  String get importLog => 'Import Log';

  @override
  String get failedToSave => 'Failed to save file. No data was recorded.';

  @override
  String get fileSaved => 'File saved';

  @override
  String get save => 'Save';

  @override
  String get enterFileName =>
      'Enter filename (leave empty for auto-generated name)';

  @override
  String get fileName => 'Filename';

  @override
  String get saveRecording => 'Save Recording';

  @override
  String get recordingStarted => 'Recording started';

  @override
  String get noValidData => 'No valid data to display.';

  @override
  String get csvPickingError => 'Error picking or reading CSV file';

  @override
  String get csvReadingError => 'Error reading CSV from file';

  @override
  String get sharingError => 'Error sharing file';

  @override
  String get csvGettingError => 'Error getting saved files';

  @override
  String get unsupportedPlatform => 'Unsupported platform';

  @override
  String get noDataRecorded => 'No data recorded to save for';

  @override
  String get csvFileSaved => 'CSV file saved at';

  @override
  String get csvSavingError => 'Error saving CSV file';

  @override
  String get csvDeletingError => 'Error deleting file';

  @override
  String get fileDeleted => 'File deleted';

  @override
  String get soundmeterConfig => 'Soundmeter Configurations';

  @override
  String get barometerConfig => 'Barometer Configurations';

  @override
  String get baroUpdatePeriodHint =>
      'Please provide time interval at which data will be updated (100 ms to 2000 ms)';

  @override
  String get barometerHighLimitHint =>
      'Please provide the maximum limit of lux value to be recorded (0 atm to 1.10 atm)';

  @override
  String get gyroscopeConfigurations => 'Gyroscope Configurations';

  @override
  String get gyroscopeHighLimitHint =>
      'Please provide the maximum limit of lux value to be recorded (0 rad/s to 1000 rad/s)';

  @override
  String get accelerometerConfigurations => 'Accelerometer Configurations';

  @override
  String get accelerometerUpdatePeriodHint =>
      'Please provide time interval at which data will be updated';

  @override
  String get accelerometerHighLimitHint =>
      'Please provide the maximum limit of lux value to be recorded';

  @override
  String get soundmeterSnackBarMessage => 'Unable to access sound sensor';

  @override
  String get dangerous => 'Dangerous';

  @override
  String get roboticArmIntro =>
      '• A robotic arm is a programmable mechanical device that mimics the movement of a human arm.\n• It uses servo motors to control its motion, and these motors are operated using PWM signals.\n• The PSLab provides four PWM square wave generators (SQ1, SQ2, SQ3, SQ4), allowing control of up to four servo motors and enabling a robotic arm with up to four degrees of freedom.';

  @override
  String get roboticArmConnection =>
      '• In the above figure, SQ1 is connected to the signal pin of the first servo motor. The servo\'s GND pin is connected to both the PSLab’s GND and the external power supply GND, while the VCC pin is connected to the external power supply VCC.\n• Similarly, connect the remaining servos to SQ2, SQ3, and SQ4 along with their respective GND and power supply connections.\n• Once connected, each servo can be controlled using either circular sliders for manual control or a timeline-based sequence for automated movement.';

  @override
  String get documentationLink => 'https://docs.pslab.io/';

  @override
  String get documentationError => 'Could not open the documentation link';

  @override
  String get autoscan => 'Autoscan';

  @override
  String get selectSensor => 'Select Sensor';

  @override
  String get notConnected => 'Not Connected';

  @override
  String get autoScanHint =>
      'Use Autoscan button to find connected sensors to PSLab device';

  @override
  String get noSensorDetected => 'No sensors detected';

  @override
  String get screenNotImplemented => 'screen not implemented yet';

  @override
  String get timeGap => 'Time gap';

  @override
  String get pslabNotConnected => 'PSLab not connected';

  @override
  String get clearData => 'Clear Data';

  @override
  String get numberOfSampes => 'No. of samples';

  @override
  String get pressure => 'Pressure';

  @override
  String get temperature => 'Temperature';

  @override
  String get bmp180 => 'BMP180';

  @override
  String get plot => 'Plot';

  @override
  String get dataCleared => 'Data cleared successfully';

  @override
  String get rawData => 'Raw Data';

  @override
  String get pressureUnitLabel => 'Pa';

  @override
  String get temperatureUnitLabel => '°C';

  @override
  String get altitudeUnitLabel => 'm';

  @override
  String get time => 'Time';

  @override
  String get notAvailable => 'N/A';

  @override
  String get estimated => 'Estimated';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');
}
