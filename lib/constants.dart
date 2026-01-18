import 'dart:core';

import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

const instrumentsScreenTitleKey = 'instruments_screen_title';
const accelerometerScreenTitleKey = 'accelerometer_screen_title';
const powerSourceScreenTitleKey = 'power_source_screen_title';
const multimeterScreenTitleKey = 'multimeter_screen_title';
const waveGeneratorScreenTitleKey = 'wave_generator_screen_title';
const oscilloscopeScreenTitleKey = 'oscilloscope_screen_title';

AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

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
  'assets/icons/tile_icon_gas.png', // dust sensor (temporary icon)
  'assets/icons/tile_icon_gas.png', // sound meter (temporary icon)
];

List<String> instrumentNames = [
  appLocalizations.oscilloscope.toLowerCase(),
  appLocalizations.multimeter.toLowerCase(),
  appLocalizations.logicAnalyzer.toLowerCase(),
  appLocalizations.sensors.toLowerCase(),
  appLocalizations.waveGenerator.toLowerCase(),
  appLocalizations.powerSource.toLowerCase(),
  appLocalizations.luxMeter.toLowerCase(),
  appLocalizations.accelerometer.toLowerCase(),
  appLocalizations.barometer.toLowerCase(),
  appLocalizations.compass.toLowerCase(),
  appLocalizations.gyroscope.toLowerCase(),
  appLocalizations.thermometer.toLowerCase(),
  appLocalizations.roboticArmTitle.toLowerCase(),
  appLocalizations.gasSensor.toLowerCase(),
  appLocalizations.dustSensor.toLowerCase(),
  appLocalizations.soundMeter.toLowerCase()
];
