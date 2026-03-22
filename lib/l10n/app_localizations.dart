import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_my.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_te.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('he'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ml'),
    Locale('my'),
    Locale('nb'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('te'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @oscilloscope.
  ///
  /// In en, this message translates to:
  /// **'Oscilloscope'**
  String get oscilloscope;

  /// No description provided for @multimeter.
  ///
  /// In en, this message translates to:
  /// **'Multimeter'**
  String get multimeter;

  /// No description provided for @logicAnalyzer.
  ///
  /// In en, this message translates to:
  /// **'Logic Analyzer'**
  String get logicAnalyzer;

  /// No description provided for @sensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensors;

  /// No description provided for @waveGenerator.
  ///
  /// In en, this message translates to:
  /// **'Wave Generator'**
  String get waveGenerator;

  /// No description provided for @powerSource.
  ///
  /// In en, this message translates to:
  /// **'Power Source'**
  String get powerSource;

  /// No description provided for @luxMeter.
  ///
  /// In en, this message translates to:
  /// **'Luxmeter'**
  String get luxMeter;

  /// No description provided for @accelerometer.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer'**
  String get accelerometer;

  /// No description provided for @barometer.
  ///
  /// In en, this message translates to:
  /// **'Barometer'**
  String get barometer;

  /// No description provided for @compass.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compass;

  /// No description provided for @gyroscope.
  ///
  /// In en, this message translates to:
  /// **'Gyroscope'**
  String get gyroscope;

  /// No description provided for @thermometer.
  ///
  /// In en, this message translates to:
  /// **'Thermometer'**
  String get thermometer;

  /// No description provided for @roboticArm.
  ///
  /// In en, this message translates to:
  /// **'Robotic Arm'**
  String get roboticArm;

  /// No description provided for @gasSensor.
  ///
  /// In en, this message translates to:
  /// **'Gas Sensor'**
  String get gasSensor;

  /// No description provided for @dustSensor.
  ///
  /// In en, this message translates to:
  /// **'Dust Sensor'**
  String get dustSensor;

  /// No description provided for @soundMeter.
  ///
  /// In en, this message translates to:
  /// **'Sound Meter'**
  String get soundMeter;

  /// No description provided for @oscilloscopeDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows observation of varying signal voltages'**
  String get oscilloscopeDesc;

  /// No description provided for @multimeterDesc.
  ///
  /// In en, this message translates to:
  /// **'Measure voltage, current, resistance and capacitance'**
  String get multimeterDesc;

  /// No description provided for @logicAnalyzerDesc.
  ///
  /// In en, this message translates to:
  /// **'Captures and displays signals from digital systems'**
  String get logicAnalyzerDesc;

  /// No description provided for @sensorsDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows logging of data returned by sensor connected'**
  String get sensorsDesc;

  /// No description provided for @waveGeneratorDesc.
  ///
  /// In en, this message translates to:
  /// **'Generates arbitrary analog and digital waveforms'**
  String get waveGeneratorDesc;

  /// No description provided for @powerSourceDesc.
  ///
  /// In en, this message translates to:
  /// **'Generates programmable voltage and currents'**
  String get powerSourceDesc;

  /// No description provided for @luxMeterDesc.
  ///
  /// In en, this message translates to:
  /// **'Measures the ambient light intensity'**
  String get luxMeterDesc;

  /// No description provided for @accelerometerDesc.
  ///
  /// In en, this message translates to:
  /// **'Measures the Linear acceleration in XYZ directions'**
  String get accelerometerDesc;

  /// No description provided for @barometerDesc.
  ///
  /// In en, this message translates to:
  /// **'Measures the atmospheric pressure'**
  String get barometerDesc;

  /// No description provided for @compassDesc.
  ///
  /// In en, this message translates to:
  /// **'Three axes magnetometer pointing to magnetic north'**
  String get compassDesc;

  /// No description provided for @gyroscopeDesc.
  ///
  /// In en, this message translates to:
  /// **'Measures rate of rotation about XYZ axis'**
  String get gyroscopeDesc;

  /// No description provided for @thermometerDesc.
  ///
  /// In en, this message translates to:
  /// **'To measure the ambient temperature'**
  String get thermometerDesc;

  /// No description provided for @roboticArmDesc.
  ///
  /// In en, this message translates to:
  /// **'Controls servos of a robotic arm'**
  String get roboticArmDesc;

  /// No description provided for @gasSensorDesc.
  ///
  /// In en, this message translates to:
  /// **'Air quality sensor for detecting a wide range of gases'**
  String get gasSensorDesc;

  /// No description provided for @dustSensorDesc.
  ///
  /// In en, this message translates to:
  /// **'Dust sensor is used to measure air quality in terms of particles per square meter'**
  String get dustSensorDesc;

  /// No description provided for @soundMeterDesc.
  ///
  /// In en, this message translates to:
  /// **'To measure the loudness in the environment in decibel(dB)'**
  String get soundMeterDesc;

  /// No description provided for @yAxisRange16V.
  ///
  /// In en, this message translates to:
  /// **'+/-16V'**
  String get yAxisRange16V;

  /// No description provided for @yAxisRange8V.
  ///
  /// In en, this message translates to:
  /// **'+/-8V'**
  String get yAxisRange8V;

  /// No description provided for @yAxisRange4V.
  ///
  /// In en, this message translates to:
  /// **'+/-4V'**
  String get yAxisRange4V;

  /// No description provided for @yAxisRange3V.
  ///
  /// In en, this message translates to:
  /// **'+/-3V'**
  String get yAxisRange3V;

  /// No description provided for @yAxisRange2V.
  ///
  /// In en, this message translates to:
  /// **'+/-2V'**
  String get yAxisRange2V;

  /// No description provided for @yAxisRange1_5V.
  ///
  /// In en, this message translates to:
  /// **'+/-1.5V'**
  String get yAxisRange1_5V;

  /// No description provided for @yAxisRange1V.
  ///
  /// In en, this message translates to:
  /// **'+/-1V'**
  String get yAxisRange1V;

  /// No description provided for @yAxisRange500mV.
  ///
  /// In en, this message translates to:
  /// **'+/-500mV'**
  String get yAxisRange500mV;

  /// No description provided for @yAxisRange160V.
  ///
  /// In en, this message translates to:
  /// **'+/-160V'**
  String get yAxisRange160V;

  /// No description provided for @oscilloscopeBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Oscilloscope in PSLab gives out many of the functionalities of a commercially available Oscilloscope. It has 4-channels with a MIC in, 2 Sine wave generators and 4 PWM square wave generators, can change the timebase, analyses signal and does Sine and Square wave fitting and plots channel to channel voltage.'**
  String get oscilloscopeBulletPoint1;

  /// No description provided for @oscilloscopeBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'To read from a Sine wave or a square wave, you can connect the Output wave pin and a Channel to the Oscilloscope as follows.'**
  String get oscilloscopeBulletPoint2;

  /// No description provided for @oscilloscopeBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Above shown figure has a connection from SQ1 to CH1 and SI1 to CH2.'**
  String get oscilloscopeBulletPoint3;

  /// No description provided for @oscilloscopeBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'Once you have generated a wave from the Wave Generator instrument connect the relevant pins and observe it from the Oscilloscope by ticking the relevant channel in Channel parameters. If you are using CH1 pin, select CH1 from channel parameters.'**
  String get oscilloscopeBulletPoint4;

  /// No description provided for @channelParameters.
  ///
  /// In en, this message translates to:
  /// **'Channel Parameters'**
  String get channelParameters;

  /// No description provided for @channelParametersIntro.
  ///
  /// In en, this message translates to:
  /// **'From this Setting, you can change the Channel that needs to be osbserved from the plot.'**
  String get channelParametersIntro;

  /// No description provided for @channelParametersBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Tick the check boxes to plot the relevant Channel.'**
  String get channelParametersBulletPoint1;

  /// No description provided for @channelParametersBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Can change the Y-axis voltage range in the plot using the spinner next to the Channel.'**
  String get channelParametersBulletPoint2;

  /// No description provided for @channelParametersBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'For the fourth Channel, you can choose either In-built microphone or an external mic. If you are to use an external microphone, the connection is as follows.'**
  String get channelParametersBulletPoint3;

  /// No description provided for @channelParametersBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'The Positive terminal of the MIC should be connected with the MIC pin and negative terminal should be conneted with the GND pin of PSLab device.'**
  String get channelParametersBulletPoint4;

  /// No description provided for @timebaseIntro.
  ///
  /// In en, this message translates to:
  /// **'This setting gives you the control of the range of Time axis(X-axis).'**
  String get timebaseIntro;

  /// No description provided for @timebaseBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'The timebase slidder can be used to increase or decrease the signal capturing time. Can change the range from 875.0 micro seconds to 102.4 milli seconds.'**
  String get timebaseBulletPoint1;

  /// No description provided for @timebaseBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'This will be useful to capture periodic wave signals in the given range for analysis.'**
  String get timebaseBulletPoint2;

  /// No description provided for @timebaseBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'You can use the trigger to set voltage value, so that when the signal exceeds the given value, plot will halt.'**
  String get timebaseBulletPoint3;

  /// No description provided for @dataAnalysisBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Using this Setting, the mathematical function of the analysed signal can be found. Can choose the Wave type from Sine or Square and the Channel that needs to be analyzed.'**
  String get dataAnalysisBulletPoint1;

  /// No description provided for @dataAnalysisBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Furthermore, analyzed signal\'s Fourier transform can be observed by checking Fourier Transforms check box.'**
  String get dataAnalysisBulletPoint2;

  /// No description provided for @xyPlotBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'This is used to plot the Channel to Channel voltage in a X-Y plot having voltage as the unit for the both axes relevant for the corresponding Channels.'**
  String get xyPlotBulletPoint1;

  /// No description provided for @channel1.
  ///
  /// In en, this message translates to:
  /// **'CH1'**
  String get channel1;

  /// No description provided for @channel2.
  ///
  /// In en, this message translates to:
  /// **'CH2'**
  String get channel2;

  /// No description provided for @channel3.
  ///
  /// In en, this message translates to:
  /// **'CH3'**
  String get channel3;

  /// No description provided for @mic.
  ///
  /// In en, this message translates to:
  /// **'MIC'**
  String get mic;

  /// No description provided for @capacitance.
  ///
  /// In en, this message translates to:
  /// **'CAP'**
  String get capacitance;

  /// No description provided for @resistance.
  ///
  /// In en, this message translates to:
  /// **'RES'**
  String get resistance;

  /// No description provided for @voltageUnit.
  ///
  /// In en, this message translates to:
  /// **'VOL'**
  String get voltageUnit;

  /// No description provided for @multimeterTitle.
  ///
  /// In en, this message translates to:
  /// **'Multimeter'**
  String get multimeterTitle;

  /// No description provided for @defaultValue.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get defaultValue;

  /// No description provided for @unitVolts.
  ///
  /// In en, this message translates to:
  /// **'Volts'**
  String get unitVolts;

  /// No description provided for @knobMarkerCh1.
  ///
  /// In en, this message translates to:
  /// **'CH1'**
  String get knobMarkerCh1;

  /// No description provided for @knobMarkerCap.
  ///
  /// In en, this message translates to:
  /// **'CAP'**
  String get knobMarkerCap;

  /// No description provided for @knobMarkerVol.
  ///
  /// In en, this message translates to:
  /// **'VOL'**
  String get knobMarkerVol;

  /// No description provided for @knobMarkerRes.
  ///
  /// In en, this message translates to:
  /// **'RES'**
  String get knobMarkerRes;

  /// No description provided for @knobMarkerLa1.
  ///
  /// In en, this message translates to:
  /// **'LA1'**
  String get knobMarkerLa1;

  /// No description provided for @knobMarkerLa2.
  ///
  /// In en, this message translates to:
  /// **'LA2'**
  String get knobMarkerLa2;

  /// No description provided for @knobMarkerLa3.
  ///
  /// In en, this message translates to:
  /// **'LA3'**
  String get knobMarkerLa3;

  /// No description provided for @knobMarkerLa4.
  ///
  /// In en, this message translates to:
  /// **'LA4'**
  String get knobMarkerLa4;

  /// No description provided for @knobMarkerCh3.
  ///
  /// In en, this message translates to:
  /// **'CH3'**
  String get knobMarkerCh3;

  /// No description provided for @knobMarkerCh2.
  ///
  /// In en, this message translates to:
  /// **'CH2'**
  String get knobMarkerCh2;

  /// No description provided for @voltage.
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get voltage;

  /// No description provided for @unitHz.
  ///
  /// In en, this message translates to:
  /// **'Hz'**
  String get unitHz;

  /// No description provided for @countPulse.
  ///
  /// In en, this message translates to:
  /// **'Count Pulse'**
  String get countPulse;

  /// No description provided for @measure.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get measure;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get connectDevice;

  /// No description provided for @deviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Device Connected Successfully'**
  String get deviceConnected;

  /// No description provided for @noDeviceFound.
  ///
  /// In en, this message translates to:
  /// **'No USB Device Found'**
  String get noDeviceFound;

  /// No description provided for @stepsToConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Steps to connect the PSLab Device'**
  String get stepsToConnectTitle;

  /// No description provided for @step1ConnectMicroUsb.
  ///
  /// In en, this message translates to:
  /// **'1. Connect a USB cable to PSLab.'**
  String get step1ConnectMicroUsb;

  /// No description provided for @step2ConnectOtg.
  ///
  /// In en, this message translates to:
  /// **'2. Connect the other end of the USB cable to an OTG.'**
  String get step2ConnectOtg;

  /// No description provided for @step3ConnectPhone.
  ///
  /// In en, this message translates to:
  /// **'3. Connect the OTG to the phone.'**
  String get step3ConnectPhone;

  /// No description provided for @step4ConnectWireless.
  ///
  /// In en, this message translates to:
  /// **'4. PSLab can also be connected wirelessly via Wi-Fi if the option is present.'**
  String get step4ConnectWireless;

  /// No description provided for @wifiConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect using Wi-Fi'**
  String get wifiConnection;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get wifi;

  /// No description provided for @connectingToWifi.
  ///
  /// In en, this message translates to:
  /// **'Connecting to PSLab WiFi...'**
  String get connectingToWifi;

  /// No description provided for @wifiConnectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully connected to PSLab via WiFi'**
  String get wifiConnectionSuccess;

  /// No description provided for @wifiConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect. Make sure you are connected to PSLab WiFi network.'**
  String get wifiConnectionFailed;

  /// No description provided for @whatIsPslab.
  ///
  /// In en, this message translates to:
  /// **'What is PSLab Device?'**
  String get whatIsPslab;

  /// No description provided for @pslabUrl.
  ///
  /// In en, this message translates to:
  /// **'https://pslab.io'**
  String get pslabUrl;

  /// No description provided for @logicAnalyzerTitle.
  ///
  /// In en, this message translates to:
  /// **'Logic Analyzer'**
  String get logicAnalyzerTitle;

  /// No description provided for @channelSelection.
  ///
  /// In en, this message translates to:
  /// **'Channel Selection'**
  String get channelSelection;

  /// No description provided for @logicAnalyzerAxisTitle.
  ///
  /// In en, this message translates to:
  /// **'Time (µs)'**
  String get logicAnalyzerAxisTitle;

  /// No description provided for @noChartDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No chart data available'**
  String get noChartDataAvailable;

  /// No description provided for @noOfChannelsOne.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get noOfChannelsOne;

  /// No description provided for @noOfChannelsTwo.
  ///
  /// In en, this message translates to:
  /// **'2'**
  String get noOfChannelsTwo;

  /// No description provided for @noOfChannelsThree.
  ///
  /// In en, this message translates to:
  /// **'3'**
  String get noOfChannelsThree;

  /// No description provided for @noOfChannelsFour.
  ///
  /// In en, this message translates to:
  /// **'4'**
  String get noOfChannelsFour;

  /// No description provided for @channelLA1.
  ///
  /// In en, this message translates to:
  /// **'LA1'**
  String get channelLA1;

  /// No description provided for @channelLA2.
  ///
  /// In en, this message translates to:
  /// **'LA2'**
  String get channelLA2;

  /// No description provided for @channelLA3.
  ///
  /// In en, this message translates to:
  /// **'LA3'**
  String get channelLA3;

  /// No description provided for @channelLA4.
  ///
  /// In en, this message translates to:
  /// **'LA4'**
  String get channelLA4;

  /// No description provided for @analysisOptionEveryEdge.
  ///
  /// In en, this message translates to:
  /// **'Every Edge'**
  String get analysisOptionEveryEdge;

  /// No description provided for @analysisOptionEveryFallingEdge.
  ///
  /// In en, this message translates to:
  /// **'Every Falling Edge'**
  String get analysisOptionEveryFallingEdge;

  /// No description provided for @analysisOptionEveryRisingEdge.
  ///
  /// In en, this message translates to:
  /// **'Every Rising Edge'**
  String get analysisOptionEveryRisingEdge;

  /// No description provided for @analysisOptionEveryFourthRisingEdge.
  ///
  /// In en, this message translates to:
  /// **'Every Fourth Rising Edge'**
  String get analysisOptionEveryFourthRisingEdge;

  /// No description provided for @analysisOptionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get analysisOptionDisabled;

  /// No description provided for @logicAnalyzerConfigs.
  ///
  /// In en, this message translates to:
  /// **'Logic Analyzer Configurations'**
  String get logicAnalyzerConfigs;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @powerSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Power Source'**
  String get powerSourceTitle;

  /// No description provided for @pinPV1.
  ///
  /// In en, this message translates to:
  /// **'PV1'**
  String get pinPV1;

  /// No description provided for @pinPV2.
  ///
  /// In en, this message translates to:
  /// **'PV2'**
  String get pinPV2;

  /// No description provided for @pinPV3.
  ///
  /// In en, this message translates to:
  /// **'PV3'**
  String get pinPV3;

  /// No description provided for @pinPCS.
  ///
  /// In en, this message translates to:
  /// **'PCS'**
  String get pinPCS;

  /// No description provided for @powerSourceIntro.
  ///
  /// In en, this message translates to:
  /// **'PSLab device can generate voltages from +5V to -5V at a resolution of 10mV'**
  String get powerSourceIntro;

  /// No description provided for @powerSourceBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Connect one wire to PV1 and another wire to GND to generate voltages between +5V to -5V.'**
  String get powerSourceBulletPoint1;

  /// No description provided for @powerSourceBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Similarly connect wires between PV2 to generate voltages between +3.3V to -3.3V.'**
  String get powerSourceBulletPoint2;

  /// No description provided for @powerSourceBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Use PV3 pin to generate voltages between 0V to +3.3V.'**
  String get powerSourceBulletPoint3;

  /// No description provided for @powerSourceBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'PCS pin is used to supply a constant current between PCS pin and a GND pin in a range of 3.3mA.'**
  String get powerSourceBulletPoint4;

  /// No description provided for @powerSourceConfigs.
  ///
  /// In en, this message translates to:
  /// **'Power Source Configurations'**
  String get powerSourceConfigs;

  /// No description provided for @loggingInterval.
  ///
  /// In en, this message translates to:
  /// **'Logging Interval'**
  String get loggingInterval;

  /// No description provided for @loggingIntervalErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Entered logging interval is not within the limits!'**
  String get loggingIntervalErrorMessage;

  /// No description provided for @powerSourceLoggingIntervalHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide time interval at which data will be logged (100 ms to 1000 ms)'**
  String get powerSourceLoggingIntervalHint;

  /// No description provided for @analog.
  ///
  /// In en, this message translates to:
  /// **'Analog'**
  String get analog;

  /// No description provided for @digital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get digital;

  /// No description provided for @wave1.
  ///
  /// In en, this message translates to:
  /// **'Wave 1'**
  String get wave1;

  /// No description provided for @wave2.
  ///
  /// In en, this message translates to:
  /// **'Wave 2'**
  String get wave2;

  /// No description provided for @sqr1.
  ///
  /// In en, this message translates to:
  /// **'sqr1'**
  String get sqr1;

  /// No description provided for @sqr2.
  ///
  /// In en, this message translates to:
  /// **'sqr2'**
  String get sqr2;

  /// No description provided for @sqr3.
  ///
  /// In en, this message translates to:
  /// **'sqr3'**
  String get sqr3;

  /// No description provided for @sqr4.
  ///
  /// In en, this message translates to:
  /// **'sqr4'**
  String get sqr4;

  /// No description provided for @freq.
  ///
  /// In en, this message translates to:
  /// **'Freq'**
  String get freq;

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @duty.
  ///
  /// In en, this message translates to:
  /// **'Duty'**
  String get duty;

  /// No description provided for @produceSound.
  ///
  /// In en, this message translates to:
  /// **'Produce Sound'**
  String get produceSound;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @phaseOffset.
  ///
  /// In en, this message translates to:
  /// **'Phase Offset'**
  String get phaseOffset;

  /// No description provided for @unitDeg.
  ///
  /// In en, this message translates to:
  /// **'°'**
  String get unitDeg;

  /// No description provided for @unitPercentage.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get unitPercentage;

  /// No description provided for @sine.
  ///
  /// In en, this message translates to:
  /// **'Sine'**
  String get sine;

  /// No description provided for @tri.
  ///
  /// In en, this message translates to:
  /// **'Tri'**
  String get tri;

  /// No description provided for @pwm.
  ///
  /// In en, this message translates to:
  /// **'pwm'**
  String get pwm;

  /// No description provided for @waveGeneratorIntro.
  ///
  /// In en, this message translates to:
  /// **'The wave generator can be used to generate different types of waves like Sine wave, square wave and saw-tooth wave allow us to change their characteristics like frequency, phase and duty. It also allows us to produce PWM signals having different phase and duty.'**
  String get waveGeneratorIntro;

  /// No description provided for @sineWaveCaption.
  ///
  /// In en, this message translates to:
  /// **'To generate Sine wave or Saw-Tooth wave:'**
  String get sineWaveCaption;

  /// No description provided for @sineWaveBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Connect the Wave pins S1 and S2 to the channel pins CH1, CH2 as shown in the above figure.'**
  String get sineWaveBulletPoint1;

  /// No description provided for @sineWaveBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Select the Wave1 button for S1 pin and Wave2 button for S2 pin.'**
  String get sineWaveBulletPoint2;

  /// No description provided for @sineWaveBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Press Sine image button for Sine wave and Saw-Tooth image button for Saw-Tooth wave.'**
  String get sineWaveBulletPoint3;

  /// No description provided for @sineWaveBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'Set their respective frequencies and phase difference(optional) using buttons in waveform panel.'**
  String get sineWaveBulletPoint4;

  /// No description provided for @sineWaveBulletPoint5.
  ///
  /// In en, this message translates to:
  /// **'Press the View button to view the waves in oscilloscope.'**
  String get sineWaveBulletPoint5;

  /// No description provided for @squareWaveCaption.
  ///
  /// In en, this message translates to:
  /// **'To generate Square wave:'**
  String get squareWaveCaption;

  /// No description provided for @squareWaveBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Connect the Wave pins SQ1 to the channel pin CH1 as shown in the above figure.'**
  String get squareWaveBulletPoint1;

  /// No description provided for @squareWaveBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Ensure the mode is selected to the Square, if not press the mode button to switch to Square mode.'**
  String get squareWaveBulletPoint2;

  /// No description provided for @squareWaveBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Select the SQ1 button'**
  String get squareWaveBulletPoint3;

  /// No description provided for @squareWaveBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'Set its Frequency and Duty Cycle'**
  String get squareWaveBulletPoint4;

  /// No description provided for @squareWaveBulletPoint5.
  ///
  /// In en, this message translates to:
  /// **'Press the View button to view the square wave in oscilloscope.'**
  String get squareWaveBulletPoint5;

  /// No description provided for @pwmCaption.
  ///
  /// In en, this message translates to:
  /// **'Similarly, to produce four different PWM signals:'**
  String get pwmCaption;

  /// No description provided for @pwmBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Switch over to PWM mode(In this mode S1 and S2 pin will be disabled).'**
  String get pwmBulletPoint1;

  /// No description provided for @pwmBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Set the common frequency for all the SQ pins.'**
  String get pwmBulletPoint2;

  /// No description provided for @pwmBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Set the duty and phase for all the SQ pins.'**
  String get pwmBulletPoint3;

  /// No description provided for @pwmBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'Press View button to generate the PWM signals.'**
  String get pwmBulletPoint4;

  /// No description provided for @waveGeneratorConfigs.
  ///
  /// In en, this message translates to:
  /// **'Wave Generator Configurations'**
  String get waveGeneratorConfigs;

  /// No description provided for @analyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyze;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @autoStart.
  ///
  /// In en, this message translates to:
  /// **'Auto Start'**
  String get autoStart;

  /// No description provided for @autoStartText.
  ///
  /// In en, this message translates to:
  /// **'Auto start app when PSLab device is connected'**
  String get autoStartText;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export Data Format'**
  String get export;

  /// No description provided for @txtFormat.
  ///
  /// In en, this message translates to:
  /// **'TXT Format'**
  String get txtFormat;

  /// No description provided for @csvFormat.
  ///
  /// In en, this message translates to:
  /// **'CSV Format'**
  String get csvFormat;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @currentFormat.
  ///
  /// In en, this message translates to:
  /// **'Current format is '**
  String get currentFormat;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @pslabDescription.
  ///
  /// In en, this message translates to:
  /// **'The goal of PSLab is to create an Open Source hardware device (open on all layers) that can be used for experiments by teachers, students and citizen scientists. Our tiny pocket lab provides an array of sensors for doing science & engineering experiments. It provides functions of numerous measurement devices including an oscilloscope, a waveform generator, a frequency generator, a frequency counter, a programmable voltage, current source and as a data logger.'**
  String get pslabDescription;

  /// No description provided for @feedbackNBugs.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Bugs'**
  String get feedbackNBugs;

  /// No description provided for @feedbackForm.
  ///
  /// In en, this message translates to:
  /// **'https://goo.gl/forms/sHlmRAPFmzcGQ27u2'**
  String get feedbackForm;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'https://pslab.io/'**
  String get website;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/fossasia/'**
  String get github;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'https://www.facebook.com/pslabio/'**
  String get facebook;

  /// No description provided for @x.
  ///
  /// In en, this message translates to:
  /// **'https://x.com/pslabio/'**
  String get x;

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'https://www.youtube.com/channel/UCQprMsG-raCIMlBudm20iLQ/'**
  String get youtube;

  /// No description provided for @mail.
  ///
  /// In en, this message translates to:
  /// **'pslab-fossasia@googlegroups.com'**
  String get mail;

  /// No description provided for @developers.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/fossasia/pslab-android/graphs/contributors'**
  String get developers;

  /// No description provided for @connectWithUs.
  ///
  /// In en, this message translates to:
  /// **'Connect with us'**
  String get connectWithUs;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @visitOurWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit our website'**
  String get visitOurWebsite;

  /// No description provided for @forkUsOnGithub.
  ///
  /// In en, this message translates to:
  /// **'Fork us on GitHub'**
  String get forkUsOnGithub;

  /// No description provided for @likeUsOnFacebook.
  ///
  /// In en, this message translates to:
  /// **'Like us on Facebook'**
  String get likeUsOnFacebook;

  /// No description provided for @followUsOnX.
  ///
  /// In en, this message translates to:
  /// **'Follow us on X'**
  String get followUsOnX;

  /// No description provided for @watchUsOnYoutube.
  ///
  /// In en, this message translates to:
  /// **'Watch us on Youtube'**
  String get watchUsOnYoutube;

  /// No description provided for @developersLink.
  ///
  /// In en, this message translates to:
  /// **'Developers'**
  String get developersLink;

  /// No description provided for @softwareLicenses.
  ///
  /// In en, this message translates to:
  /// **'Software Licenses'**
  String get softwareLicenses;

  /// No description provided for @tryDifferentSearchSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchSuggestion;

  /// No description provided for @noInstrumentsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No instruments found'**
  String get noInstrumentsFoundMessage;

  /// No description provided for @searchInstrumentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search instruments...'**
  String get searchInstrumentsHint;

  /// No description provided for @instrumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Instruments'**
  String get instrumentsTitle;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqTitle;

  /// No description provided for @launchError.
  ///
  /// In en, this message translates to:
  /// **'Could not launch'**
  String get launchError;

  /// No description provided for @faqQ.
  ///
  /// In en, this message translates to:
  /// **'Q:'**
  String get faqQ;

  /// No description provided for @faqA.
  ///
  /// In en, this message translates to:
  /// **'A:'**
  String get faqA;

  /// No description provided for @faqWhatIsPslab.
  ///
  /// In en, this message translates to:
  /// **'What is Pocket Science Lab? What can I do with it?'**
  String get faqWhatIsPslab;

  /// No description provided for @faqWhereToBuy.
  ///
  /// In en, this message translates to:
  /// **'Where can I buy a Pocket Science Lab?'**
  String get faqWhereToBuy;

  /// No description provided for @faqDownloadAndroidApp.
  ///
  /// In en, this message translates to:
  /// **'Where can I download the Android App for Pocket Science Lab?'**
  String get faqDownloadAndroidApp;

  /// No description provided for @faqDownloadDesktopApp.
  ///
  /// In en, this message translates to:
  /// **'Where can I download the desktop app for Pocket Science Lab for Windows, Linux and Mac?'**
  String get faqDownloadDesktopApp;

  /// No description provided for @faqHowToConnect.
  ///
  /// In en, this message translates to:
  /// **'How can I connect to the device? What kind of USB cable do I need? What is an OTG USB cable?'**
  String get faqHowToConnect;

  /// No description provided for @faqReportBug.
  ///
  /// In en, this message translates to:
  /// **'I found a bug in one of your apps or hardware. What to do? Where should I report it?'**
  String get faqReportBug;

  /// No description provided for @faqRecordData.
  ///
  /// In en, this message translates to:
  /// **'Can I record or save data in the apps and export or import it?'**
  String get faqRecordData;

  /// No description provided for @faqUsePhoneSensors.
  ///
  /// In en, this message translates to:
  /// **'My Android phone already has some sensors, can I use them with the PSLab app as well?'**
  String get faqUsePhoneSensors;

  /// No description provided for @faqCompatibleSensors.
  ///
  /// In en, this message translates to:
  /// **'Which external sensors can I use with a PSLab device and the apps? Which ones are compatible?'**
  String get faqCompatibleSensors;

  /// No description provided for @faqWhatIsPslabAnswer.
  ///
  /// In en, this message translates to:
  /// **'Pocket Science Lab (PSLab) is a small USB powered hardware board that can be used for measurements and experiments. It works as an extension for Android phones or PCs. PSLab comes with a built-in Oscilloscope, Multimeter, Wave Generator, Logic Analyzer, Power Source, and many more instruments. It can also be used as a robotics control app. And, we are constantly adding more digital instruments. PSLab is many devices in one. Simply connect two wires to the relevant pins (description is on the back of the PSLab board) and start measuring. You can use our Open Source Android or desktop app to view and collect the data. You can also plug in hundreds of compatible I²C standard sensors to the PSLab pin slots. It works without the need for programming. So, what experiments you do is just limited to your imagination!'**
  String get faqWhatIsPslabAnswer;

  /// No description provided for @faqWhereToBuyAnswer.
  ///
  /// In en, this message translates to:
  /// **'There is an overview page for shops where you can buy a Pocket Science Lab device in different regions on the website at '**
  String get faqWhereToBuyAnswer;

  /// No description provided for @faqWhereToBuyLinkText.
  ///
  /// In en, this message translates to:
  /// **'https://pslab.io/shop/'**
  String get faqWhereToBuyLinkText;

  /// No description provided for @faqWhereToBuyLinkUrl.
  ///
  /// In en, this message translates to:
  /// **'https://pslab.io/shop/'**
  String get faqWhereToBuyLinkUrl;

  /// No description provided for @faqDownloadAndroidAppAnswer.
  ///
  /// In en, this message translates to:
  /// **'The app can be downloaded from F-Droid or Play Store. Simply click on the links to be directed over!'**
  String get faqDownloadAndroidAppAnswer;

  /// No description provided for @faqDownloadAndroidAppLinkText.
  ///
  /// In en, this message translates to:
  /// **'Playstore'**
  String get faqDownloadAndroidAppLinkText;

  /// No description provided for @faqDownloadAndroidAppLinkUrl.
  ///
  /// In en, this message translates to:
  /// **'https://play.google.com/store/apps/details?id=io.pslab&hl=en_IN'**
  String get faqDownloadAndroidAppLinkUrl;

  /// No description provided for @faqDownloadDesktopAppAnswer.
  ///
  /// In en, this message translates to:
  /// **'We are developing a desktop app for Windows, Linux and Mac in our desktop Git repository. You can find it in the install branch of the project here. The app is still under development. We are using technologies like Electron and Python, that work on all platforms. However, to make the final installer work everywhere requires some tweaks and improvements here and there. So, please expect some glitches. You can use the tracker in the repository to submit issues, bugs and feature requests.'**
  String get faqDownloadDesktopAppAnswer;

  /// No description provided for @faqHowToConnectAnswer.
  ///
  /// In en, this message translates to:
  /// **'To connect to the device you need an OTG USB cable (OTG = On the go) which is a USB cable that allows connected devices to switch back and forth between the roles of host and device. USB cables that are not OTG compatible will NOT work. It is also possible to extend the PSLab with an ESP WiFi chip and communicate through this gateway using the Android app. You can refer to the hardware developer documentation and code on GitHub for more details here.'**
  String get faqHowToConnectAnswer;

  /// No description provided for @faqReportBugAnswer.
  ///
  /// In en, this message translates to:
  /// **'We have issue trackers in all our projects. They are currently hosted on GitHub. In order to submit a bug or feature request you need to login to the service.'**
  String get faqReportBugAnswer;

  /// No description provided for @faqReportBugLinkText.
  ///
  /// In en, this message translates to:
  /// **'A list of our PSLab repositories is here'**
  String get faqReportBugLinkText;

  /// No description provided for @faqReportBugLinkUrl.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/fossasia'**
  String get faqReportBugLinkUrl;

  /// No description provided for @faqRecordDataAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, we have implemented a record and play function or a way to save and open configurations in the instruments on the Android and desktop app. Data you record can be imported into the apps and viewed. This feature is still under heavy development, but works well in most places. You can find it in the top bar of the apps. There are buttons to record, play, save and open data.'**
  String get faqRecordDataAnswer;

  /// No description provided for @faqUsePhoneSensorsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, absolutely. You can install the PSLab Android app (Play Store, Fdroid) on your phone and use it with devices such as Luxmeter or Compass. We are adding support for more built-in sensors step by step.'**
  String get faqUsePhoneSensorsAnswer;

  /// No description provided for @faqCompatibleSensorsAnswer.
  ///
  /// In en, this message translates to:
  /// **'In our apps we use the industry standard I²C (Wikipedia). You can get the data from sensors that are connected to the device through the USB port using an OTG USB cable (OTG = On the go) which is a USB cable that allows connected devices to switch back and forth between the roles of host and device. For the transfer we use UART (universal asynchronous receiver-transmitter, Wikipedia). Many sensors can be used with specific instruments, e.g. Barometer, Thermometer, Gyroscope etc. You can access the configuration for sensors in the instrument settings on the top right burger menu of each instrument. All sensors using the I²C standard are compatible with the device. There are connection pins for analogue and digital sensors. You find the description of the pins on the back of the device. Even if there is no specific instrument in one of our apps yet, you can still view and store the raw data using the Oscilloscope instrument component. There is a page with a list of recommended sensors on the website.'**
  String get faqCompatibleSensorsAnswer;

  /// No description provided for @accelerometerTitle.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer'**
  String get accelerometerTitle;

  /// No description provided for @xAxis.
  ///
  /// In en, this message translates to:
  /// **'x'**
  String get xAxis;

  /// No description provided for @yAxis.
  ///
  /// In en, this message translates to:
  /// **'y'**
  String get yAxis;

  /// No description provided for @zAxis.
  ///
  /// In en, this message translates to:
  /// **'z'**
  String get zAxis;

  /// No description provided for @timeAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'Time(s)'**
  String get timeAxisLabel;

  /// No description provided for @accelerationAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'m/s²'**
  String get accelerationAxisLabel;

  /// No description provided for @minValue.
  ///
  /// In en, this message translates to:
  /// **'Min: '**
  String get minValue;

  /// No description provided for @maxValue.
  ///
  /// In en, this message translates to:
  /// **'Max: '**
  String get maxValue;

  /// No description provided for @gyroscopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Gyroscope'**
  String get gyroscopeTitle;

  /// No description provided for @gyroscopeAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'rad/s'**
  String get gyroscopeAxisLabel;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @degreeSymbol.
  ///
  /// In en, this message translates to:
  /// **'°'**
  String get degreeSymbol;

  /// No description provided for @enterAngleRange.
  ///
  /// In en, this message translates to:
  /// **'Enter angle (0 - 360)'**
  String get enterAngleRange;

  /// No description provided for @errorCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cannot be empty'**
  String get errorCannotBeEmpty;

  /// No description provided for @servoValidNumberRange.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number between 0 and 360'**
  String get servoValidNumberRange;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @roboticArmTitle.
  ///
  /// In en, this message translates to:
  /// **'Robotic Arm'**
  String get roboticArmTitle;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @controls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get controls;

  /// No description provided for @saveData.
  ///
  /// In en, this message translates to:
  /// **'Save Data'**
  String get saveData;

  /// No description provided for @showGuide.
  ///
  /// In en, this message translates to:
  /// **'Show Guide'**
  String get showGuide;

  /// No description provided for @compassGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compassGuideTitle;

  /// No description provided for @compassGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Compass instrument is used to navigate and to find magnetic field along axis. Compass instrument in PSLab app can be used with built-in mobile sensors or with sensor HMC5883L.'**
  String get compassGuideBody;

  /// No description provided for @compassGuideImageCaption.
  ///
  /// In en, this message translates to:
  /// **'Three axes magnetometer pointing to magnetic north'**
  String get compassGuideImageCaption;

  /// No description provided for @showLoggedData.
  ///
  /// In en, this message translates to:
  /// **'Show Logged Data'**
  String get showLoggedData;

  /// No description provided for @setAngle.
  ///
  /// In en, this message translates to:
  /// **'Set angle for Servo'**
  String get setAngle;

  /// No description provided for @angleDialog.
  ///
  /// In en, this message translates to:
  /// **'AngleDialog'**
  String get angleDialog;

  /// No description provided for @servo1.
  ///
  /// In en, this message translates to:
  /// **'Servo 1'**
  String get servo1;

  /// No description provided for @servo2.
  ///
  /// In en, this message translates to:
  /// **'Servo 2'**
  String get servo2;

  /// No description provided for @servo3.
  ///
  /// In en, this message translates to:
  /// **'Servo 3'**
  String get servo3;

  /// No description provided for @servo4.
  ///
  /// In en, this message translates to:
  /// **'Servo 4'**
  String get servo4;

  /// No description provided for @xyPlot.
  ///
  /// In en, this message translates to:
  /// **'XY Plot'**
  String get xyPlot;

  /// No description provided for @enablePlot.
  ///
  /// In en, this message translates to:
  /// **'Enable XY Plot'**
  String get enablePlot;

  /// No description provided for @trigger.
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get trigger;

  /// No description provided for @timeBase.
  ///
  /// In en, this message translates to:
  /// **'Timebase'**
  String get timeBase;

  /// No description provided for @timeBaseAndTrigger.
  ///
  /// In en, this message translates to:
  /// **'Timebase & Trigger'**
  String get timeBaseAndTrigger;

  /// No description provided for @offsets.
  ///
  /// In en, this message translates to:
  /// **'Offsets'**
  String get offsets;

  /// No description provided for @dataAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Data Analysis'**
  String get dataAnalysis;

  /// No description provided for @fourierAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Fourier Analysis'**
  String get fourierAnalysis;

  /// No description provided for @channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// No description provided for @pslabMic.
  ///
  /// In en, this message translates to:
  /// **'PSLab MIC'**
  String get pslabMic;

  /// No description provided for @inBuiltMic.
  ///
  /// In en, this message translates to:
  /// **'In-Built MIC'**
  String get inBuiltMic;

  /// No description provided for @ch3Range.
  ///
  /// In en, this message translates to:
  /// **'CH3 (+/- 3.3V)'**
  String get ch3Range;

  /// No description provided for @rangeValue.
  ///
  /// In en, this message translates to:
  /// **'+/-16V'**
  String get rangeValue;

  /// No description provided for @range.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get range;

  /// No description provided for @ch2.
  ///
  /// In en, this message translates to:
  /// **'CH2'**
  String get ch2;

  /// No description provided for @ch1.
  ///
  /// In en, this message translates to:
  /// **'CH1'**
  String get ch1;

  /// No description provided for @noSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal found.'**
  String get noSignal;

  /// No description provided for @autoScale.
  ///
  /// In en, this message translates to:
  /// **'AUTO'**
  String get autoScale;

  /// No description provided for @automatedMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Automated Measurements'**
  String get automatedMeasurements;

  /// No description provided for @luxMeterTitle.
  ///
  /// In en, this message translates to:
  /// **'Lux Meter'**
  String get luxMeterTitle;

  /// No description provided for @builtIn.
  ///
  /// In en, this message translates to:
  /// **'Built-In'**
  String get builtIn;

  /// No description provided for @lx.
  ///
  /// In en, this message translates to:
  /// **'lx'**
  String get lx;

  /// No description provided for @maxScaleError.
  ///
  /// In en, this message translates to:
  /// **'Max Scale'**
  String get maxScaleError;

  /// No description provided for @lightSensorError.
  ///
  /// In en, this message translates to:
  /// **'Light sensor error:'**
  String get lightSensorError;

  /// No description provided for @lightSensorInitialError.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize light sensor:'**
  String get lightSensorInitialError;

  /// No description provided for @barometerTitle.
  ///
  /// In en, this message translates to:
  /// **'Barometer'**
  String get barometerTitle;

  /// No description provided for @atm.
  ///
  /// In en, this message translates to:
  /// **'atm'**
  String get atm;

  /// No description provided for @barometerSensorInitialError.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize barometer sensor:'**
  String get barometerSensorInitialError;

  /// No description provided for @barometerSensorError.
  ///
  /// In en, this message translates to:
  /// **'Barometer sensor error occurred'**
  String get barometerSensorError;

  /// No description provided for @barometerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Barometer sensor not available on this device'**
  String get barometerNotAvailable;

  /// No description provided for @meterUnit.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get meterUnit;

  /// No description provided for @altitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get altitudeLabel;

  /// No description provided for @soundMeterError.
  ///
  /// In en, this message translates to:
  /// **'Sound sensor error:'**
  String get soundMeterError;

  /// No description provided for @soundMeterInitialError.
  ///
  /// In en, this message translates to:
  /// **'Sound sensor initialization error:'**
  String get soundMeterInitialError;

  /// No description provided for @db.
  ///
  /// In en, this message translates to:
  /// **'dB'**
  String get db;

  /// No description provided for @soundMeterTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound Meter'**
  String get soundMeterTitle;

  /// No description provided for @noLightSensor.
  ///
  /// In en, this message translates to:
  /// **'Device does not have a light sensor'**
  String get noLightSensor;

  /// No description provided for @lightSensorErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Light sensor error details:'**
  String get lightSensorErrorDetails;

  /// No description provided for @lightSensorErrorLog.
  ///
  /// In en, this message translates to:
  /// **'No light sensor data received - sensor may not be available'**
  String get lightSensorErrorLog;

  /// No description provided for @playBackSummary.
  ///
  /// In en, this message translates to:
  /// **'Playback Summary'**
  String get playBackSummary;

  /// No description provided for @servo.
  ///
  /// In en, this message translates to:
  /// **'Servo:'**
  String get servo;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get percentage;

  /// No description provided for @pwmWaveForm.
  ///
  /// In en, this message translates to:
  /// **'PWM Waveform'**
  String get pwmWaveForm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @timeMillisecond.
  ///
  /// In en, this message translates to:
  /// **'Time (ms)'**
  String get timeMillisecond;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @clearTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Timeline?'**
  String get clearTimelineTitle;

  /// No description provided for @clearTimelineConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the timeline?'**
  String get clearTimelineConfirmation;

  /// No description provided for @avgAngleLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Angle'**
  String get avgAngleLabel;

  /// No description provided for @maxAngleLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Angle'**
  String get maxAngleLabel;

  /// No description provided for @minAngleLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Angle'**
  String get minAngleLabel;

  /// No description provided for @avgDutyLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Duty'**
  String get avgDutyLabel;

  /// No description provided for @maxDutyLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Duty'**
  String get maxDutyLabel;

  /// No description provided for @minDutyLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Duty'**
  String get minDutyLabel;

  /// No description provided for @controlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get controlsTitle;

  /// No description provided for @manualLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualLabel;

  /// No description provided for @feedbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackLabel;

  /// No description provided for @duration1Min.
  ///
  /// In en, this message translates to:
  /// **'1min'**
  String get duration1Min;

  /// No description provided for @duration2Min.
  ///
  /// In en, this message translates to:
  /// **'2min'**
  String get duration2Min;

  /// No description provided for @frequency50Hz.
  ///
  /// In en, this message translates to:
  /// **'50Hz'**
  String get frequency50Hz;

  /// No description provided for @frequency100Hz.
  ///
  /// In en, this message translates to:
  /// **'100Hz'**
  String get frequency100Hz;

  /// No description provided for @angle180.
  ///
  /// In en, this message translates to:
  /// **'180'**
  String get angle180;

  /// No description provided for @angle360.
  ///
  /// In en, this message translates to:
  /// **'360'**
  String get angle360;

  /// No description provided for @angle180Display.
  ///
  /// In en, this message translates to:
  /// **'180°'**
  String get angle180Display;

  /// No description provided for @angle360Display.
  ///
  /// In en, this message translates to:
  /// **'360°'**
  String get angle360Display;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @hzSuffix.
  ///
  /// In en, this message translates to:
  /// **'Hz'**
  String get hzSuffix;

  /// No description provided for @clearTimelineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear Timeline'**
  String get clearTimelineTooltip;

  /// No description provided for @manualMode.
  ///
  /// In en, this message translates to:
  /// **'Manual Mode'**
  String get manualMode;

  /// No description provided for @frequencyChange.
  ///
  /// In en, this message translates to:
  /// **'Stop playback to change frequency.'**
  String get frequencyChange;

  /// No description provided for @playBackStop.
  ///
  /// In en, this message translates to:
  /// **'Playback stopped'**
  String get playBackStop;

  /// No description provided for @soundMeterIntro.
  ///
  /// In en, this message translates to:
  /// **'Sound meter Introduction'**
  String get soundMeterIntro;

  /// No description provided for @soundMeterDescFull.
  ///
  /// In en, this message translates to:
  /// **'To measure the loudness in the environment in decibel(dB)'**
  String get soundMeterDescFull;

  /// No description provided for @luxMeterDescFull.
  ///
  /// In en, this message translates to:
  /// **'The Lux meter can be used to measure the ambient light intensity. This instruments is compatible with either the built-in light sensor on any Android device or the BH-1750 light sensor.'**
  String get luxMeterDescFull;

  /// No description provided for @luxMeterSensorIntro.
  ///
  /// In en, this message translates to:
  /// **'If you want to use the sensor BH-1750, connect the sensor to PSLab device as shown below'**
  String get luxMeterSensorIntro;

  /// No description provided for @luxMeterBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'The above pin configuration has to be same except for the pin GND. GND is meant for Ground and any of the PSLab device GND pins can be used since they are common.'**
  String get luxMeterBulletPoint1;

  /// No description provided for @luxMeterBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Select sensor by going to the Configure tab from the bottom navigation bar and choose BHT-1750 in the drop down menu under Select Sensor.'**
  String get luxMeterBulletPoint2;

  /// No description provided for @gyroscopeIntro.
  ///
  /// In en, this message translates to:
  /// **'Gyroscope is used to measure rate of rotation of a body along X, Y, and Z axis.'**
  String get gyroscopeIntro;

  /// No description provided for @gyroscopeDescFull.
  ///
  /// In en, this message translates to:
  /// **'Orientation of the positive X, Y, and Z axes. For any positive axis on the device, clockwise rotation outputs negative values, and counterclockwise rotation outputs positive values.'**
  String get gyroscopeDescFull;

  /// No description provided for @accelerometerIntro.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer is used to measure acceleration of a body along the X, Y, and Z axis.'**
  String get accelerometerIntro;

  /// No description provided for @accelerometerImageDesc.
  ///
  /// In en, this message translates to:
  /// **'The figure above shows the direction of all the three axis when the mobile is held straight.'**
  String get accelerometerImageDesc;

  /// No description provided for @accelerometerSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps to measure acceleration in PSLab app:'**
  String get accelerometerSteps;

  /// No description provided for @accelerometerBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Hold the device as shown in the above figure.'**
  String get accelerometerBulletPoint1;

  /// No description provided for @accelerometerBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Accelerate the device along any one or multiple axis.'**
  String get accelerometerBulletPoint2;

  /// No description provided for @accelerometerBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Observe the values in the cards or the plotted graph of any particular axis.'**
  String get accelerometerBulletPoint3;

  /// No description provided for @accelerometerDescFull.
  ///
  /// In en, this message translates to:
  /// **'The Accelerometer instrument can also be used to measure the acceleration of a moving body by placing the device on/inside the body and then accelerating the body.'**
  String get accelerometerDescFull;

  /// No description provided for @accelerometerNote.
  ///
  /// In en, this message translates to:
  /// **'NOTE: Don\'t accelerate the body if the device isn\'t properly attached else the device could be damaged.'**
  String get accelerometerNote;

  /// No description provided for @hideGuide.
  ///
  /// In en, this message translates to:
  /// **'Hide Guide'**
  String get hideGuide;

  /// No description provided for @minLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minLabel;

  /// No description provided for @maxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxLabel;

  /// No description provided for @avgLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avgLabel;

  /// No description provided for @loggedDataMenu.
  ///
  /// In en, this message translates to:
  /// **'Logged Data'**
  String get loggedDataMenu;

  /// No description provided for @configFileMenu.
  ///
  /// In en, this message translates to:
  /// **'Generate Config File'**
  String get configFileMenu;

  /// No description provided for @documentationMenu.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentationMenu;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @buyPsLabMenu.
  ///
  /// In en, this message translates to:
  /// **'Buy PSLab'**
  String get buyPsLabMenu;

  /// No description provided for @faqMenu.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqMenu;

  /// No description provided for @shareAppMenu.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareAppMenu;

  /// No description provided for @privacyPolicyMenu.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyMenu;

  /// No description provided for @shopLink.
  ///
  /// In en, this message translates to:
  /// **'https://pslab.io/shop/'**
  String get shopLink;

  /// No description provided for @shopError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the shop link'**
  String get shopError;

  /// No description provided for @showLuxmeterConfig.
  ///
  /// In en, this message translates to:
  /// **'Lux Meter Configurations'**
  String get showLuxmeterConfig;

  /// No description provided for @luxmeterConfigurations.
  ///
  /// In en, this message translates to:
  /// **'Lux Meter Configurations'**
  String get luxmeterConfigurations;

  /// No description provided for @updatePeriod.
  ///
  /// In en, this message translates to:
  /// **'Update Period'**
  String get updatePeriod;

  /// No description provided for @luxmeterUpdatePeriodHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide time interval at which data will be updated (100 ms to 1000 ms)'**
  String get luxmeterUpdatePeriodHint;

  /// No description provided for @highLimit.
  ///
  /// In en, this message translates to:
  /// **'High Limit'**
  String get highLimit;

  /// No description provided for @luxmeterHighLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide the maximum limit of lux value to be recorded (10 Lx to 10000 Lx)'**
  String get luxmeterHighLimitHint;

  /// No description provided for @sensorGain.
  ///
  /// In en, this message translates to:
  /// **'Sensor Gain'**
  String get sensorGain;

  /// No description provided for @sensorGainHint.
  ///
  /// In en, this message translates to:
  /// **'Please set gain of the sensor'**
  String get sensorGainHint;

  /// No description provided for @locationData.
  ///
  /// In en, this message translates to:
  /// **'Include Location Data'**
  String get locationData;

  /// No description provided for @locationDataHint.
  ///
  /// In en, this message translates to:
  /// **'Include the location data in the logged file'**
  String get locationDataHint;

  /// No description provided for @activeSensor.
  ///
  /// In en, this message translates to:
  /// **'Active Sensor'**
  String get activeSensor;

  /// No description provided for @ms.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get ms;

  /// No description provided for @inBuiltSensor.
  ///
  /// In en, this message translates to:
  /// **'In-built Sensor'**
  String get inBuiltSensor;

  /// No description provided for @updatePeriodErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Entered update period is not within the limits!'**
  String get updatePeriodErrorMessage;

  /// No description provided for @highLimitErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Entered High limit is not within the limits!'**
  String get highLimitErrorMessage;

  /// No description provided for @baroMeterBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'The Barometer can be used to measure Atmospheric pressure. This instrument is compatible with either the built in pressure sensor on any android device or the BMP-180 pressure sensor'**
  String get baroMeterBulletPoint1;

  /// No description provided for @baroMeterBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'If you want to use the sensor BMP-180, connect the sensor to PSLab device as shown in the figure.'**
  String get baroMeterBulletPoint2;

  /// No description provided for @baroMeterBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'The above pin configuration has to be same except for the pin GND. GND is meant for Ground and any of the PSLab device GND pins can be used since they are common.'**
  String get baroMeterBulletPoint3;

  /// No description provided for @baroMeterBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'Select the sensor by going to the Configure tab from the bottom navigation bar and choose BMP-180 in the drop down menu under Select Sensor.'**
  String get baroMeterBulletPoint4;

  /// No description provided for @magnetometerError.
  ///
  /// In en, this message translates to:
  /// **'Magnetometer error:'**
  String get magnetometerError;

  /// No description provided for @accelerometerError.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer error:'**
  String get accelerometerError;

  /// No description provided for @compassTitle.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compassTitle;

  /// No description provided for @parallelToGround.
  ///
  /// In en, this message translates to:
  /// **'Select axes parallel to ground'**
  String get parallelToGround;

  /// No description provided for @thermometerTitle.
  ///
  /// In en, this message translates to:
  /// **'Thermometer'**
  String get thermometerTitle;

  /// No description provided for @thermometerIntro.
  ///
  /// In en, this message translates to:
  /// **'Thermometer instrument is used to measure ambient temprature. It can be measured using inbuilt ambient temprature sensor or through SHT21.'**
  String get thermometerIntro;

  /// No description provided for @celsius.
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get celsius;

  /// No description provided for @temperatureSensorError.
  ///
  /// In en, this message translates to:
  /// **'Temperature sensor error:'**
  String get temperatureSensorError;

  /// No description provided for @temperatureSensorInitialError.
  ///
  /// In en, this message translates to:
  /// **'Temperature sensor initialization error:'**
  String get temperatureSensorInitialError;

  /// No description provided for @temperatureSensorUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Ambient temperature sensor is not available on this device'**
  String get temperatureSensorUnavailableMessage;

  /// No description provided for @sharingMessage.
  ///
  /// In en, this message translates to:
  /// **'Sharing PSLab Data'**
  String get sharingMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteHint.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file?'**
  String get deleteHint;

  /// No description provided for @soundmeterSnackBarMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to access sound sensor'**
  String get soundmeterSnackBarMessage;

  /// No description provided for @dangerous.
  ///
  /// In en, this message translates to:
  /// **'Dangerous'**
  String get dangerous;

  /// No description provided for @documentationLink.
  ///
  /// In en, this message translates to:
  /// **'https://docs.pslab.io/'**
  String get documentationLink;

  /// No description provided for @documentationError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the documentation link'**
  String get documentationError;

  /// No description provided for @androidRatingLink.
  ///
  /// In en, this message translates to:
  /// **'https://play.google.com/store/apps/details?id=io.pslab'**
  String get androidRatingLink;

  /// No description provided for @iOSRatingLink.
  ///
  /// In en, this message translates to:
  /// **'https://apps.apple.com/us/app/pslab/id6740454978?action=write-review'**
  String get iOSRatingLink;

  /// No description provided for @ratingError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get ratingError;

  /// No description provided for @privacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'https://pslab.io/privacy-policy/'**
  String get privacyPolicyLink;

  /// No description provided for @privacyPolicyError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the privacy policy link'**
  String get privacyPolicyError;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @deleteCautionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all logged data?'**
  String get deleteCautionMessage;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @noLoggedData.
  ///
  /// In en, this message translates to:
  /// **'No logged data found.'**
  String get noLoggedData;

  /// No description provided for @importLog.
  ///
  /// In en, this message translates to:
  /// **'Import Log'**
  String get importLog;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save file. No data was recorded.'**
  String get failedToSave;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get fileSaved;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @enterFileName.
  ///
  /// In en, this message translates to:
  /// **'Enter filename (leave empty for auto-generated name)'**
  String get enterFileName;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get fileName;

  /// No description provided for @saveRecording.
  ///
  /// In en, this message translates to:
  /// **'Save Recording'**
  String get saveRecording;

  /// No description provided for @recordingStarted.
  ///
  /// In en, this message translates to:
  /// **'Recording started'**
  String get recordingStarted;

  /// No description provided for @noValidData.
  ///
  /// In en, this message translates to:
  /// **'No valid data to display.'**
  String get noValidData;

  /// No description provided for @csvPickingError.
  ///
  /// In en, this message translates to:
  /// **'Error picking or reading CSV file'**
  String get csvPickingError;

  /// No description provided for @csvReadingError.
  ///
  /// In en, this message translates to:
  /// **'Error reading CSV from file'**
  String get csvReadingError;

  /// No description provided for @sharingError.
  ///
  /// In en, this message translates to:
  /// **'Error sharing file'**
  String get sharingError;

  /// No description provided for @csvGettingError.
  ///
  /// In en, this message translates to:
  /// **'Error getting saved files'**
  String get csvGettingError;

  /// No description provided for @unsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Unsupported platform'**
  String get unsupportedPlatform;

  /// No description provided for @noDataRecorded.
  ///
  /// In en, this message translates to:
  /// **'No data recorded to save for'**
  String get noDataRecorded;

  /// No description provided for @csvFileSaved.
  ///
  /// In en, this message translates to:
  /// **'CSV file saved at'**
  String get csvFileSaved;

  /// No description provided for @csvSavingError.
  ///
  /// In en, this message translates to:
  /// **'Error saving CSV file'**
  String get csvSavingError;

  /// No description provided for @csvDeletingError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting file'**
  String get csvDeletingError;

  /// No description provided for @fileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get fileDeleted;

  /// No description provided for @soundmeterConfig.
  ///
  /// In en, this message translates to:
  /// **'Soundmeter Configurations'**
  String get soundmeterConfig;

  /// No description provided for @barometerConfig.
  ///
  /// In en, this message translates to:
  /// **'Barometer Configurations'**
  String get barometerConfig;

  /// No description provided for @baroUpdatePeriodHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide time interval at which data will be updated (100 ms to 2000 ms)'**
  String get baroUpdatePeriodHint;

  /// No description provided for @barometerHighLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide the maximum limit of atm value to be recorded (0 atm to 1.10 atm)'**
  String get barometerHighLimitHint;

  /// No description provided for @gyroscopeConfigurations.
  ///
  /// In en, this message translates to:
  /// **'Gyroscope Configurations'**
  String get gyroscopeConfigurations;

  /// No description provided for @gyroscopeHighLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide the maximum limit of angular velocity value to be recorded (0 rad/s to 1000 rad/s)'**
  String get gyroscopeHighLimitHint;

  /// No description provided for @accelerometerConfigurations.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer Configurations'**
  String get accelerometerConfigurations;

  /// No description provided for @accelerometerUpdatePeriodHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide time interval at which data will be updated'**
  String get accelerometerUpdatePeriodHint;

  /// No description provided for @accelerometerHighLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide the maximum limit of acceleration value to be recorded'**
  String get accelerometerHighLimitHint;

  /// No description provided for @roboticArmIntro.
  ///
  /// In en, this message translates to:
  /// **'• A robotic arm is a programmable mechanical device that mimics the movement of a human arm.\n• It uses servo motors to control its motion, and these motors are operated using PWM signals.\n• The PSLab provides four PWM square wave generators (SQ1, SQ2, SQ3, SQ4), allowing control of up to four servo motors and enabling a robotic arm with up to four degrees of freedom.'**
  String get roboticArmIntro;

  /// No description provided for @roboticArmConnection.
  ///
  /// In en, this message translates to:
  /// **'• In the above figure, SQ1 is connected to the signal pin of the first servo motor. The servo\'s GND pin is connected to both the PSLab’s GND and the external power supply GND, while the VCC pin is connected to the external power supply VCC.\n• Similarly, connect the remaining servos to SQ2, SQ3, and SQ4 along with their respective GND and power supply connections.\n• Once connected, each servo can be controlled using either circular sliders for manual control or a timeline-based sequence for automated movement.'**
  String get roboticArmConnection;

  /// No description provided for @autoscan.
  ///
  /// In en, this message translates to:
  /// **'Autoscan'**
  String get autoscan;

  /// No description provided for @selectSensor.
  ///
  /// In en, this message translates to:
  /// **'Select Sensor'**
  String get selectSensor;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// No description provided for @autoScanHint.
  ///
  /// In en, this message translates to:
  /// **'Use Autoscan button to find connected sensors to PSLab device'**
  String get autoScanHint;

  /// No description provided for @noSensorDetected.
  ///
  /// In en, this message translates to:
  /// **'No sensors detected'**
  String get noSensorDetected;

  /// No description provided for @screenNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'screen not implemented yet'**
  String get screenNotImplemented;

  /// No description provided for @timeGap.
  ///
  /// In en, this message translates to:
  /// **'Time gap'**
  String get timeGap;

  /// No description provided for @pslabNotConnected.
  ///
  /// In en, this message translates to:
  /// **'PSLab not connected'**
  String get pslabNotConnected;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearData;

  /// No description provided for @numberOfSampes.
  ///
  /// In en, this message translates to:
  /// **'No. of samples'**
  String get numberOfSampes;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @bmp180.
  ///
  /// In en, this message translates to:
  /// **'BMP180'**
  String get bmp180;

  /// No description provided for @plot.
  ///
  /// In en, this message translates to:
  /// **'Plot'**
  String get plot;

  /// No description provided for @dataCleared.
  ///
  /// In en, this message translates to:
  /// **'Data cleared successfully'**
  String get dataCleared;

  /// No description provided for @rawData.
  ///
  /// In en, this message translates to:
  /// **'Raw Data'**
  String get rawData;

  /// No description provided for @pressureUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Pa'**
  String get pressureUnitLabel;

  /// No description provided for @temperatureUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get temperatureUnitLabel;

  /// No description provided for @altitudeUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get altitudeUnitLabel;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @configure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// No description provided for @setGain.
  ///
  /// In en, this message translates to:
  /// **'Set Gain'**
  String get setGain;

  /// No description provided for @setChannel.
  ///
  /// In en, this message translates to:
  /// **'Set Channel'**
  String get setChannel;

  /// No description provided for @setRate.
  ///
  /// In en, this message translates to:
  /// **'Set Rate'**
  String get setRate;

  /// No description provided for @millivolts.
  ///
  /// In en, this message translates to:
  /// **'mV'**
  String get millivolts;

  /// No description provided for @experiments.
  ///
  /// In en, this message translates to:
  /// **'Experiments'**
  String get experiments;

  /// No description provided for @startExperiment.
  ///
  /// In en, this message translates to:
  /// **'Start Experiment'**
  String get startExperiment;

  /// No description provided for @lightIntensityVsDistance.
  ///
  /// In en, this message translates to:
  /// **'Light Intensity vs Distance'**
  String get lightIntensityVsDistance;

  /// No description provided for @lightIntensityVsDistanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Measure how light intensity changes with distance from the source'**
  String get lightIntensityVsDistanceDesc;

  /// No description provided for @stepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Step Completed!'**
  String get stepCompleted;

  /// No description provided for @endExperiment.
  ///
  /// In en, this message translates to:
  /// **'End Experiment'**
  String get endExperiment;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @experimentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Experiment Completed'**
  String get experimentCompleted;

  /// No description provided for @setUp.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setUp;

  /// No description provided for @lightExperimentSetUpContent.
  ///
  /// In en, this message translates to:
  /// **'Place your device near a light source (lamp, window, or flashlight).'**
  String get lightExperimentSetUpContent;

  /// No description provided for @preparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get preparation;

  /// No description provided for @lightExperimentPreparationContent.
  ///
  /// In en, this message translates to:
  /// **'Make sure you have space to move towards the light source gradually.'**
  String get lightExperimentPreparationContent;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @lightExperimentInstructionContent.
  ///
  /// In en, this message translates to:
  /// **'You will measure light intensity at different distances. Follow the on-screen prompts to move closer or farther from the light source.'**
  String get lightExperimentInstructionContent;

  /// No description provided for @moveTowardsLight.
  ///
  /// In en, this message translates to:
  /// **'Move towards the light source'**
  String get moveTowardsLight;

  /// No description provided for @moveAwayFromLight.
  ///
  /// In en, this message translates to:
  /// **'Move away from the light source'**
  String get moveAwayFromLight;

  /// No description provided for @holdPosition.
  ///
  /// In en, this message translates to:
  /// **'Hold your position and let the reading stabilize'**
  String get holdPosition;

  /// No description provided for @followInstructions.
  ///
  /// In en, this message translates to:
  /// **'Follow the on-screen instructions to set up your experiment.'**
  String get followInstructions;

  /// No description provided for @gesture.
  ///
  /// In en, this message translates to:
  /// **'Gesture'**
  String get gesture;

  /// No description provided for @blueLabel.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blueLabel;

  /// No description provided for @greenLabel.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get greenLabel;

  /// No description provided for @proxLabel.
  ///
  /// In en, this message translates to:
  /// **'Prox'**
  String get proxLabel;

  /// No description provided for @redLabel.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get redLabel;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @proximity.
  ///
  /// In en, this message translates to:
  /// **'Proximity'**
  String get proximity;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @lux.
  ///
  /// In en, this message translates to:
  /// **'Lux'**
  String get lux;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @distanceUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'mm'**
  String get distanceUnitLabel;

  /// No description provided for @legacyFirmwareAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Legacy Firmware Detected'**
  String get legacyFirmwareAlertTitle;

  /// No description provided for @legacyFirmwareAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'We have detected that your PSLab device is running legacy firmware. Please note that support for this firmware has ended. For the best experience and continued support, please update your device to the latest firmware version.'**
  String get legacyFirmwareAlertMessage;

  /// No description provided for @holdPositionForPressure.
  ///
  /// In en, this message translates to:
  /// **'Hold position steady for stable pressure reading'**
  String get holdPositionForPressure;

  /// No description provided for @moveToHigherAltitude.
  ///
  /// In en, this message translates to:
  /// **'Move to a higher altitude or floor'**
  String get moveToHigherAltitude;

  /// No description provided for @moveToLowerAltitude.
  ///
  /// In en, this message translates to:
  /// **'Move to a lower altitude or floor'**
  String get moveToLowerAltitude;

  /// No description provided for @pressureVsAltitude.
  ///
  /// In en, this message translates to:
  /// **'Pressure vs Altitude'**
  String get pressureVsAltitude;

  /// No description provided for @pressureVsAltitudeDesc.
  ///
  /// In en, this message translates to:
  /// **'Observe how atmospheric pressure changes with altitude'**
  String get pressureVsAltitudeDesc;

  /// No description provided for @barometerExperimentSetUpContent.
  ///
  /// In en, this message translates to:
  /// **'Ensure your device has a working barometer sensor, or connect a BMP180 sensor using PSLab to complete the experiment.'**
  String get barometerExperimentSetUpContent;

  /// No description provided for @barometerExperimentPreparationContent.
  ///
  /// In en, this message translates to:
  /// **'Start the experiment in a stable position. Pressure decreases as altitude increases, and pressure increases as altitude decreases.'**
  String get barometerExperimentPreparationContent;

  /// No description provided for @barometerExperimentInstructionContent.
  ///
  /// In en, this message translates to:
  /// **'Follow the on-screen instructions to move between different altitudes. The experiment will automatically detect pressure changes.'**
  String get barometerExperimentInstructionContent;

  /// No description provided for @playbackStarted.
  ///
  /// In en, this message translates to:
  /// **'Playback started'**
  String get playbackStarted;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @stopPlayback.
  ///
  /// In en, this message translates to:
  /// **'Stop Playback'**
  String get stopPlayback;

  /// No description provided for @resumePlayback.
  ///
  /// In en, this message translates to:
  /// **'Resume Playback'**
  String get resumePlayback;

  /// No description provided for @pausePlayback.
  ///
  /// In en, this message translates to:
  /// **'Pause Playback'**
  String get pausePlayback;

  /// No description provided for @openStreetMapContributors.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get openStreetMapContributors;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @noLocationDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No location data available'**
  String get noLocationDataAvailable;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @loggedData.
  ///
  /// In en, this message translates to:
  /// **'Logged Data'**
  String get loggedData;

  /// No description provided for @oscilloscopeConfigs.
  ///
  /// In en, this message translates to:
  /// **'Oscilloscope Configurations'**
  String get oscilloscopeConfigs;

  /// No description provided for @automatedMeasurementsInfo.
  ///
  /// In en, this message translates to:
  /// **'Automatically measures and displays waveform characteristics such as Amplitude, Frequency, Period, etc.'**
  String get automatedMeasurementsInfo;

  /// No description provided for @multimeterConfigs.
  ///
  /// In en, this message translates to:
  /// **'Multimeter Configurations'**
  String get multimeterConfigs;

  /// No description provided for @multimeterUpdatePeriodHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide time interval at which data will be updated (100 ms to 1000 ms)'**
  String get multimeterUpdatePeriodHint;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkExperimental.
  ///
  /// In en, this message translates to:
  /// **'Dark (Experimental)'**
  String get darkExperimental;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @multimeterIntro.
  ///
  /// In en, this message translates to:
  /// **'The multimeter can be used to measure electrical quantities such as resistance, capacitance, voltage, frequency and pulse count using the PSLab device.'**
  String get multimeterIntro;

  /// No description provided for @resistanceCapacitanceCaption.
  ///
  /// In en, this message translates to:
  /// **'To measure Resistance or Capacitance:'**
  String get resistanceCapacitanceCaption;

  /// No description provided for @resistanceCapacitanceBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Connect the SEN pin to the resistor or capacitor terminal as shown in the figure.'**
  String get resistanceCapacitanceBulletPoint1;

  /// No description provided for @resistanceCapacitanceBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Connect the CAP pin to the other terminal of the component.'**
  String get resistanceCapacitanceBulletPoint2;

  /// No description provided for @resistanceCapacitanceBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Ensure the component is not connected to any external power source.'**
  String get resistanceCapacitanceBulletPoint3;

  /// No description provided for @resistanceCapacitanceBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'Select the Resistance or Capacitance mode in the Multimeter panel.'**
  String get resistanceCapacitanceBulletPoint4;

  /// No description provided for @voltageMeasurementCaption.
  ///
  /// In en, this message translates to:
  /// **'To measure Voltage:'**
  String get voltageMeasurementCaption;

  /// No description provided for @voltageMeasurementBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Connect the power source output (PV1, PV2 or PV3) to the channel pins CH1 or CH2 as shown in the figure.'**
  String get voltageMeasurementBulletPoint1;

  /// No description provided for @voltageMeasurementBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Connect the ground of the power source to the GND pin.'**
  String get voltageMeasurementBulletPoint2;

  /// No description provided for @voltageMeasurementBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Select the Voltage mode in the Multimeter.'**
  String get voltageMeasurementBulletPoint3;

  /// No description provided for @frequencyPulseCaption.
  ///
  /// In en, this message translates to:
  /// **'To measure Frequency or Count Pulses:'**
  String get frequencyPulseCaption;

  /// No description provided for @frequencyPulseBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Connect the signal source to any one of the digital input pins ID1, ID2, ID3 or ID4.'**
  String get frequencyPulseBulletPoint1;

  /// No description provided for @frequencyPulseBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Ensure the signal ground is connected to GND.'**
  String get frequencyPulseBulletPoint2;

  /// No description provided for @frequencyPulseBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Select Frequency or Pulse Count mode in the Multimeter panel.'**
  String get frequencyPulseBulletPoint3;

  /// No description provided for @logicAnalyzerIntro.
  ///
  /// In en, this message translates to:
  /// **'The Logic Analyzer is used to capture and analyze digital signals. It helps in understanding the time relationship between multiple digital pulses such as square waves, clock signals and protocol signals.'**
  String get logicAnalyzerIntro;

  /// No description provided for @logicAnalyzerWaveGenCaption.
  ///
  /// In en, this message translates to:
  /// **'To generate digital pulses for analysis:'**
  String get logicAnalyzerWaveGenCaption;

  /// No description provided for @logicAnalyzerWaveGenBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Open the Wave Generator instrument from the PSLab app.'**
  String get logicAnalyzerWaveGenBulletPoint1;

  /// No description provided for @logicAnalyzerWaveGenBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Switch the mode to PWM using the MODE button.'**
  String get logicAnalyzerWaveGenBulletPoint2;

  /// No description provided for @logicAnalyzerWaveGenBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Select one or more SQ pins (SQ1, SQ2, SQ3 or SQ4).'**
  String get logicAnalyzerWaveGenBulletPoint3;

  /// No description provided for @logicAnalyzerWaveGenBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'Set frequency and duty cycle for each selected pin.'**
  String get logicAnalyzerWaveGenBulletPoint4;

  /// No description provided for @logicAnalyzerWaveGenBulletPoint5.
  ///
  /// In en, this message translates to:
  /// **'Keep duty cycles different for better understanding of timing.'**
  String get logicAnalyzerWaveGenBulletPoint5;

  /// No description provided for @logicAnalyzerConnectionCaption.
  ///
  /// In en, this message translates to:
  /// **'To connect signals to Logic Analyzer:'**
  String get logicAnalyzerConnectionCaption;

  /// No description provided for @logicAnalyzerConnectionBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Connect the square wave output pins (SQ1, SQ2, etc.) to Logic Analyzer input pins (ID1, ID2, ID3 or ID4).'**
  String get logicAnalyzerConnectionBulletPoint1;

  /// No description provided for @logicAnalyzerConnectionBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Ensure a common ground connection between the signal source and PSLab.'**
  String get logicAnalyzerConnectionBulletPoint2;

  /// No description provided for @logicAnalyzerConnectionBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Maintain the same pin selection throughout the analysis.'**
  String get logicAnalyzerConnectionBulletPoint3;

  /// No description provided for @logicAnalyzerUsageCaption.
  ///
  /// In en, this message translates to:
  /// **'To analyze digital signals:'**
  String get logicAnalyzerUsageCaption;

  /// No description provided for @logicAnalyzerUsageBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Open the Logic Analyzer instrument from the instrument list.'**
  String get logicAnalyzerUsageBulletPoint1;

  /// No description provided for @logicAnalyzerUsageBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Select the required channel mode (Single, Two, Three or Four Channel).'**
  String get logicAnalyzerUsageBulletPoint2;

  /// No description provided for @logicAnalyzerUsageBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Assign ID pins to each channel from the Channel Selection area.'**
  String get logicAnalyzerUsageBulletPoint3;

  /// No description provided for @logicAnalyzerUsageBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'Choose the edge detection mode for each channel.'**
  String get logicAnalyzerUsageBulletPoint4;

  /// No description provided for @logicAnalyzerUsageBulletPoint5.
  ///
  /// In en, this message translates to:
  /// **'Press the Analyze button to fetch and plot the digital signals.'**
  String get logicAnalyzerUsageBulletPoint5;

  /// No description provided for @logicAnalyzerEdgeCaption.
  ///
  /// In en, this message translates to:
  /// **'Edge selection options:'**
  String get logicAnalyzerEdgeCaption;

  /// No description provided for @logicAnalyzerEdgeBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Every Edge – Plots all rising and falling edges.'**
  String get logicAnalyzerEdgeBulletPoint1;

  /// No description provided for @logicAnalyzerEdgeBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Rising Edges – Plots only transitions from LOW to HIGH.'**
  String get logicAnalyzerEdgeBulletPoint2;

  /// No description provided for @logicAnalyzerEdgeBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Falling Edges – Plots only transitions from HIGH to LOW.'**
  String get logicAnalyzerEdgeBulletPoint3;

  /// No description provided for @logicAnalyzerEdgeBulletPoint4.
  ///
  /// In en, this message translates to:
  /// **'Disabled – Ignores the selected channel.'**
  String get logicAnalyzerEdgeBulletPoint4;

  /// No description provided for @logicAnalyzerMeasurementCaption.
  ///
  /// In en, this message translates to:
  /// **'To measure time difference:'**
  String get logicAnalyzerMeasurementCaption;

  /// No description provided for @logicAnalyzerMeasurementBulletPoint1.
  ///
  /// In en, this message translates to:
  /// **'Tap on any rising or falling edge on the plotted waveform.'**
  String get logicAnalyzerMeasurementBulletPoint1;

  /// No description provided for @logicAnalyzerMeasurementBulletPoint2.
  ///
  /// In en, this message translates to:
  /// **'Use the axis indicator to read the corresponding timestamp.'**
  String get logicAnalyzerMeasurementBulletPoint2;

  /// No description provided for @logicAnalyzerMeasurementBulletPoint3.
  ///
  /// In en, this message translates to:
  /// **'Compare timestamps between channels to calculate time intervals.'**
  String get logicAnalyzerMeasurementBulletPoint3;

  /// No description provided for @sht21Config.
  ///
  /// In en, this message translates to:
  /// **'SHT21 Configurations'**
  String get sht21Config;

  /// No description provided for @sht21.
  ///
  /// In en, this message translates to:
  /// **'SHT21'**
  String get sht21;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @humidityUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get humidityUnitLabel;

  /// No description provided for @meterPerSecondSquared.
  ///
  /// In en, this message translates to:
  /// **'m/s²'**
  String get meterPerSecondSquared;

  /// No description provided for @pin_gnd_name.
  ///
  /// In en, this message translates to:
  /// **'GND'**
  String get pin_gnd_name;

  /// No description provided for @pin_gnd_desc.
  ///
  /// In en, this message translates to:
  /// **'Ground Pin (0 V)'**
  String get pin_gnd_desc;

  /// No description provided for @pin_vdd_name.
  ///
  /// In en, this message translates to:
  /// **'VDD'**
  String get pin_vdd_name;

  /// No description provided for @pin_vdd_desc.
  ///
  /// In en, this message translates to:
  /// **'Voltage Supply Pin (+3.3V)'**
  String get pin_vdd_desc;

  /// No description provided for @pin_vcc_name.
  ///
  /// In en, this message translates to:
  /// **'VCC'**
  String get pin_vcc_name;

  /// No description provided for @pin_vcc_desc.
  ///
  /// In en, this message translates to:
  /// **'Voltage Supply Pin (+5 V)'**
  String get pin_vcc_desc;

  /// No description provided for @pin_vin_name.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get pin_vin_name;

  /// No description provided for @pin_vin_desc.
  ///
  /// In en, this message translates to:
  /// **'External Power input Pin (<15 V)'**
  String get pin_vin_desc;

  /// No description provided for @pin_up_name.
  ///
  /// In en, this message translates to:
  /// **'UP'**
  String get pin_up_name;

  /// No description provided for @pin_up_desc.
  ///
  /// In en, this message translates to:
  /// **'Power from USB port'**
  String get pin_up_desc;

  /// No description provided for @pin_down_name.
  ///
  /// In en, this message translates to:
  /// **'DOWN'**
  String get pin_down_name;

  /// No description provided for @pin_down_desc.
  ///
  /// In en, this message translates to:
  /// **'External power from VIN pin'**
  String get pin_down_desc;

  /// No description provided for @pin_bat_name.
  ///
  /// In en, this message translates to:
  /// **'BAT'**
  String get pin_bat_name;

  /// No description provided for @pin_bat_desc.
  ///
  /// In en, this message translates to:
  /// **'CR1225 Coin cell battery'**
  String get pin_bat_desc;

  /// No description provided for @pin_rxd_name.
  ///
  /// In en, this message translates to:
  /// **'RXD'**
  String get pin_rxd_name;

  /// No description provided for @pin_rxd_desc.
  ///
  /// In en, this message translates to:
  /// **'UART Rx Pin for ESP / External / Bluetooth'**
  String get pin_rxd_desc;

  /// No description provided for @pin_txd_name.
  ///
  /// In en, this message translates to:
  /// **'TXD'**
  String get pin_txd_name;

  /// No description provided for @pin_txd_desc.
  ///
  /// In en, this message translates to:
  /// **'UART Tx Pin for ESP / External / Bluetooth'**
  String get pin_txd_desc;

  /// No description provided for @pin_enp_name.
  ///
  /// In en, this message translates to:
  /// **'ENP'**
  String get pin_enp_name;

  /// No description provided for @pin_enp_desc.
  ///
  /// In en, this message translates to:
  /// **'ESP Enable Pin/CH PD'**
  String get pin_enp_desc;

  /// No description provided for @pin_mcl_name.
  ///
  /// In en, this message translates to:
  /// **'MCL'**
  String get pin_mcl_name;

  /// No description provided for @pin_mcl_desc.
  ///
  /// In en, this message translates to:
  /// **'Master Clear Pin'**
  String get pin_mcl_desc;

  /// No description provided for @pin_pgd_name.
  ///
  /// In en, this message translates to:
  /// **'PGD'**
  String get pin_pgd_name;

  /// No description provided for @pin_pgd_desc.
  ///
  /// In en, this message translates to:
  /// **'Programmer Data Pin'**
  String get pin_pgd_desc;

  /// No description provided for @pin_pgc_name.
  ///
  /// In en, this message translates to:
  /// **'PGC'**
  String get pin_pgc_name;

  /// No description provided for @pin_pgc_desc.
  ///
  /// In en, this message translates to:
  /// **'Programmer Clock Pin'**
  String get pin_pgc_desc;

  /// No description provided for @pin_ena_name.
  ///
  /// In en, this message translates to:
  /// **'ENA'**
  String get pin_ena_name;

  /// No description provided for @pin_ena_desc.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Module Enable Pin'**
  String get pin_ena_desc;

  /// No description provided for @pin_sta_name.
  ///
  /// In en, this message translates to:
  /// **'STA'**
  String get pin_sta_name;

  /// No description provided for @pin_sta_desc.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Status Pin (Not Connected)'**
  String get pin_sta_desc;

  /// No description provided for @pin_cs1_name.
  ///
  /// In en, this message translates to:
  /// **'CS1'**
  String get pin_cs1_name;

  /// No description provided for @pin_cs1_desc.
  ///
  /// In en, this message translates to:
  /// **'Channel Select Pin for SPI'**
  String get pin_cs1_desc;

  /// No description provided for @pin_sdi_name.
  ///
  /// In en, this message translates to:
  /// **'SDI'**
  String get pin_sdi_name;

  /// No description provided for @pin_sdi_desc.
  ///
  /// In en, this message translates to:
  /// **'SPI Data In'**
  String get pin_sdi_desc;

  /// No description provided for @pin_sdo_name.
  ///
  /// In en, this message translates to:
  /// **'SDO'**
  String get pin_sdo_name;

  /// No description provided for @pin_sdo_desc.
  ///
  /// In en, this message translates to:
  /// **'SPI Data Out'**
  String get pin_sdo_desc;

  /// No description provided for @pin_sck_name.
  ///
  /// In en, this message translates to:
  /// **'SCK'**
  String get pin_sck_name;

  /// No description provided for @pin_sck_desc.
  ///
  /// In en, this message translates to:
  /// **'SPI Clock Pin'**
  String get pin_sck_desc;

  /// No description provided for @pin_sda_name.
  ///
  /// In en, this message translates to:
  /// **'SDA'**
  String get pin_sda_name;

  /// No description provided for @pin_sda_desc.
  ///
  /// In en, this message translates to:
  /// **'I2C Serial Data Pin'**
  String get pin_sda_desc;

  /// No description provided for @pin_scl_name.
  ///
  /// In en, this message translates to:
  /// **'SCL'**
  String get pin_scl_name;

  /// No description provided for @pin_scl_desc.
  ///
  /// In en, this message translates to:
  /// **'I2C Serial Clock Pin'**
  String get pin_scl_desc;

  /// No description provided for @pin_pcs_name.
  ///
  /// In en, this message translates to:
  /// **'PCS'**
  String get pin_pcs_name;

  /// No description provided for @pin_pcs_desc.
  ///
  /// In en, this message translates to:
  /// **'Programmable Current Source (3.3 mA)'**
  String get pin_pcs_desc;

  /// No description provided for @pin_pv3_name.
  ///
  /// In en, this message translates to:
  /// **'PV3'**
  String get pin_pv3_name;

  /// No description provided for @pin_pv3_desc.
  ///
  /// In en, this message translates to:
  /// **'Programmable Voltage Source (0-3 V)'**
  String get pin_pv3_desc;

  /// No description provided for @pin_pv2_name.
  ///
  /// In en, this message translates to:
  /// **'PV2'**
  String get pin_pv2_name;

  /// No description provided for @pin_pv2_desc.
  ///
  /// In en, this message translates to:
  /// **'Programmable Voltage Source (+3.3V)'**
  String get pin_pv2_desc;

  /// No description provided for @pin_pv1_name.
  ///
  /// In en, this message translates to:
  /// **'PV1'**
  String get pin_pv1_name;

  /// No description provided for @pin_pv1_desc.
  ///
  /// In en, this message translates to:
  /// **'Programmable Voltage Source (± 5.0 V)'**
  String get pin_pv1_desc;

  /// No description provided for @pin_si1_name.
  ///
  /// In en, this message translates to:
  /// **'SI1'**
  String get pin_si1_name;

  /// No description provided for @pin_si1_desc.
  ///
  /// In en, this message translates to:
  /// **'Wave Generator Pin 1 (5 Hz~5 kHz)'**
  String get pin_si1_desc;

  /// No description provided for @pin_si2_name.
  ///
  /// In en, this message translates to:
  /// **'SI2'**
  String get pin_si2_name;

  /// No description provided for @pin_si2_desc.
  ///
  /// In en, this message translates to:
  /// **'Wave Generator Pin 2 (5Hz-5kHz)'**
  String get pin_si2_desc;

  /// No description provided for @pin_sq1_name.
  ///
  /// In en, this message translates to:
  /// **'SQ1'**
  String get pin_sq1_name;

  /// No description provided for @pin_sq1_desc.
  ///
  /// In en, this message translates to:
  /// **'PWM Generator Pin 1 (32 MHz)'**
  String get pin_sq1_desc;

  /// No description provided for @pin_sq2_name.
  ///
  /// In en, this message translates to:
  /// **'SQ2'**
  String get pin_sq2_name;

  /// No description provided for @pin_sq2_desc.
  ///
  /// In en, this message translates to:
  /// **'PWM Generator Pin 2 (32 MHz)'**
  String get pin_sq2_desc;

  /// No description provided for @pin_sq3_name.
  ///
  /// In en, this message translates to:
  /// **'SQ3'**
  String get pin_sq3_name;

  /// No description provided for @pin_sq3_desc.
  ///
  /// In en, this message translates to:
  /// **'PWM Generator Pin 3 (32 MHz)'**
  String get pin_sq3_desc;

  /// No description provided for @pin_sq4_name.
  ///
  /// In en, this message translates to:
  /// **'SQ4'**
  String get pin_sq4_name;

  /// No description provided for @pin_sq4_desc.
  ///
  /// In en, this message translates to:
  /// **'PWM Generator Pin 4 (32 MHz)'**
  String get pin_sq4_desc;

  /// No description provided for @pin_la1_name.
  ///
  /// In en, this message translates to:
  /// **'LA1'**
  String get pin_la1_name;

  /// No description provided for @pin_la1_desc.
  ///
  /// In en, this message translates to:
  /// **'Logic Analyzer Pin 1'**
  String get pin_la1_desc;

  /// No description provided for @pin_la2_name.
  ///
  /// In en, this message translates to:
  /// **'LA2'**
  String get pin_la2_name;

  /// No description provided for @pin_la2_desc.
  ///
  /// In en, this message translates to:
  /// **'Logic Analyzer Pin 2'**
  String get pin_la2_desc;

  /// No description provided for @pin_la3_name.
  ///
  /// In en, this message translates to:
  /// **'LA3'**
  String get pin_la3_name;

  /// No description provided for @pin_la3_desc.
  ///
  /// In en, this message translates to:
  /// **'Logic Analyzer Pin 3'**
  String get pin_la3_desc;

  /// No description provided for @pin_la4_name.
  ///
  /// In en, this message translates to:
  /// **'LA4'**
  String get pin_la4_name;

  /// No description provided for @pin_la4_desc.
  ///
  /// In en, this message translates to:
  /// **'Logic Analyzer Pin 4'**
  String get pin_la4_desc;

  /// No description provided for @pin_ch1_name.
  ///
  /// In en, this message translates to:
  /// **'CH1'**
  String get pin_ch1_name;

  /// No description provided for @pin_ch1_desc.
  ///
  /// In en, this message translates to:
  /// **'Channel 1 (Oscilloscope)'**
  String get pin_ch1_desc;

  /// No description provided for @pin_ch2_name.
  ///
  /// In en, this message translates to:
  /// **'CH2'**
  String get pin_ch2_name;

  /// No description provided for @pin_ch2_desc.
  ///
  /// In en, this message translates to:
  /// **'Channel 2 (Oscilloscope)'**
  String get pin_ch2_desc;

  /// No description provided for @pin_ch3_name.
  ///
  /// In en, this message translates to:
  /// **'CH3'**
  String get pin_ch3_name;

  /// No description provided for @pin_ch3_desc.
  ///
  /// In en, this message translates to:
  /// **'Channel 3 (Oscilloscope)'**
  String get pin_ch3_desc;

  /// No description provided for @pin_ac1_name.
  ///
  /// In en, this message translates to:
  /// **'AC1'**
  String get pin_ac1_name;

  /// No description provided for @pin_ac1_desc.
  ///
  /// In en, this message translates to:
  /// **'Channel for AC Waves (Oscilloscope)'**
  String get pin_ac1_desc;

  /// No description provided for @pin_chg_name.
  ///
  /// In en, this message translates to:
  /// **'CHG'**
  String get pin_chg_name;

  /// No description provided for @pin_chg_desc.
  ///
  /// In en, this message translates to:
  /// **'Channel 3 Gain Control Pin'**
  String get pin_chg_desc;

  /// No description provided for @pin_mic_name.
  ///
  /// In en, this message translates to:
  /// **'MIC'**
  String get pin_mic_name;

  /// No description provided for @pin_mic_desc.
  ///
  /// In en, this message translates to:
  /// **'Microphone (+) Pin'**
  String get pin_mic_desc;

  /// No description provided for @pin_frq_name.
  ///
  /// In en, this message translates to:
  /// **'FRQ'**
  String get pin_frq_name;

  /// No description provided for @pin_frq_desc.
  ///
  /// In en, this message translates to:
  /// **'Frequency Counter Pin'**
  String get pin_frq_desc;

  /// No description provided for @pin_vol_name.
  ///
  /// In en, this message translates to:
  /// **'VOL'**
  String get pin_vol_name;

  /// No description provided for @pin_vol_desc.
  ///
  /// In en, this message translates to:
  /// **'Voltmeter Pin'**
  String get pin_vol_desc;

  /// No description provided for @pin_cap_name.
  ///
  /// In en, this message translates to:
  /// **'CAP'**
  String get pin_cap_name;

  /// No description provided for @pin_cap_desc.
  ///
  /// In en, this message translates to:
  /// **'Capacitance Measurement Pin'**
  String get pin_cap_desc;

  /// No description provided for @pin_res_name.
  ///
  /// In en, this message translates to:
  /// **'RES'**
  String get pin_res_name;

  /// No description provided for @pin_res_desc.
  ///
  /// In en, this message translates to:
  /// **'Resistance Measurement Pin'**
  String get pin_res_desc;

  /// No description provided for @stopSound.
  ///
  /// In en, this message translates to:
  /// **'Stop Sound'**
  String get stopSound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'he',
        'hi',
        'id',
        'it',
        'ja',
        'ml',
        'my',
        'nb',
        'pt',
        'ru',
        'te',
        'uk',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ml':
      return AppLocalizationsMl();
    case 'my':
      return AppLocalizationsMy();
    case 'nb':
      return AppLocalizationsNb();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'te':
      return AppLocalizationsTe();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
