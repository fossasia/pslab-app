import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @oscilloscope.
  ///
  /// In en, this message translates to:
  /// **'OSCILLOSCOPE'**
  String get oscilloscope;

  /// No description provided for @multimeter.
  ///
  /// In en, this message translates to:
  /// **'MULTIMETER'**
  String get multimeter;

  /// No description provided for @logicAnalyzer.
  ///
  /// In en, this message translates to:
  /// **'LOGIC ANALYZER'**
  String get logicAnalyzer;

  /// No description provided for @sensors.
  ///
  /// In en, this message translates to:
  /// **'SENSORS'**
  String get sensors;

  /// No description provided for @waveGenerator.
  ///
  /// In en, this message translates to:
  /// **'WAVE GENERATOR'**
  String get waveGenerator;

  /// No description provided for @powerSource.
  ///
  /// In en, this message translates to:
  /// **'POWER SOURCE'**
  String get powerSource;

  /// No description provided for @luxMeter.
  ///
  /// In en, this message translates to:
  /// **'LUX METER'**
  String get luxMeter;

  /// No description provided for @accelerometer.
  ///
  /// In en, this message translates to:
  /// **'ACCELEROMETER'**
  String get accelerometer;

  /// No description provided for @barometer.
  ///
  /// In en, this message translates to:
  /// **'BAROMETER'**
  String get barometer;

  /// No description provided for @compass.
  ///
  /// In en, this message translates to:
  /// **'COMPASS'**
  String get compass;

  /// No description provided for @gyroscope.
  ///
  /// In en, this message translates to:
  /// **'GYROSCOPE'**
  String get gyroscope;

  /// No description provided for @thermometer.
  ///
  /// In en, this message translates to:
  /// **'THERMOMETER'**
  String get thermometer;

  /// No description provided for @roboticArm.
  ///
  /// In en, this message translates to:
  /// **'ROBOTIC ARM'**
  String get roboticArm;

  /// No description provided for @gasSensor.
  ///
  /// In en, this message translates to:
  /// **'GAS SENSOR'**
  String get gasSensor;

  /// No description provided for @dustSensor.
  ///
  /// In en, this message translates to:
  /// **'DUST SENSOR'**
  String get dustSensor;

  /// No description provided for @soundMeter.
  ///
  /// In en, this message translates to:
  /// **'SOUND METER'**
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
  /// **'Air quality sensor for detecting a wide range of gases, including NH3, NOx, alcohol, benzene, smoke and CO2'**
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
  /// **'1. Connect a micro USB(Mini B) to PSLab'**
  String get step1ConnectMicroUsb;

  /// No description provided for @step2ConnectOtg.
  ///
  /// In en, this message translates to:
  /// **'2. Connect the other end of the micro USB cable to a OTG'**
  String get step2ConnectOtg;

  /// No description provided for @step3ConnectPhone.
  ///
  /// In en, this message translates to:
  /// **'3. Connect the OTG to the phone'**
  String get step3ConnectPhone;

  /// No description provided for @bluetoothWifiConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect using Bluetooth or Wi-Fi'**
  String get bluetoothWifiConnection;

  /// No description provided for @bluetooth.
  ///
  /// In en, this message translates to:
  /// **'BLUETOOTH'**
  String get bluetooth;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'WIFI'**
  String get wifi;

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
  /// **'EVERY EDGE'**
  String get analysisOptionEveryEdge;

  /// No description provided for @analysisOptionEveryFallingEdge.
  ///
  /// In en, this message translates to:
  /// **'EVERY FALLING EDGE'**
  String get analysisOptionEveryFallingEdge;

  /// No description provided for @analysisOptionEveryRisingEdge.
  ///
  /// In en, this message translates to:
  /// **'EVERY RISING EDGE'**
  String get analysisOptionEveryRisingEdge;

  /// No description provided for @analysisOptionEveryFourthRisingEdge.
  ///
  /// In en, this message translates to:
  /// **'EVERY FOURTH RISING EDGE'**
  String get analysisOptionEveryFourthRisingEdge;

  /// No description provided for @analysisOptionDisabled.
  ///
  /// In en, this message translates to:
  /// **'DISABLED'**
  String get analysisOptionDisabled;

  /// No description provided for @analyze.
  ///
  /// In en, this message translates to:
  /// **'ANALYZE'**
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
  /// **'CANCEL'**
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
  /// **'The goal of PSLab is to create an Open Source hardware device (open on all layers) that can be used for experiments by teachers, students and citizen scientists. Our tiny pocket lab provides an array of sensors for doing science and engineering experiments. It provides functions of numerous measurement devices including an oscilloscope, a waveform generator, a frequency generator, a frequency counter, a programmable voltage, current source and as a data logger.'**
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
  /// **'To connect to the device you need an OTG USB cable (OTG = On the go) which is a USB cable that allows connected devices to switch back and forth between the roles of host and device. USB cables that are not OTG compatible will NOT work. It is also possible to extend the PSLab with an ESP WiFi chip or a Bluetooth chip and communicate through these gateways using the Android app. You can refer to the hardware developer documentation and code on GitHub for more details here.'**
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
  /// **'Lx'**
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
  /// **'LOW'**
  String get low;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
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

  /// No description provided for @updatePeriodHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide time interval at which data will be updated (100 ms to 1000 ms)'**
  String get updatePeriodHint;

  /// No description provided for @highLimit.
  ///
  /// In en, this message translates to:
  /// **'High Limit'**
  String get highLimit;

  /// No description provided for @highLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide the maximum limit of lux value to be recorded (10 Lx to 10000 Lx)'**
  String get highLimitHint;

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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
