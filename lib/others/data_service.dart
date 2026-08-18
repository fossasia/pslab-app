import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart' as csv;
import 'package:file_picker/file_picker.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../providers/locator.dart';

class DataService {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  bool _isSupportedFormat(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.csv') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.json');
  }

  Future<Directory> getInstrumentDirectory(String instrumentName) async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      final directory = Directory('${externalDir?.path}/PSLab/$instrumentName');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } else if (Platform.isIOS ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux) {
      final dir = await getApplicationDocumentsDirectory();
      final directory = Directory('${dir.path}/PSLab/$instrumentName');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } else {
      throw UnsupportedError(appLocalizations.unsupportedPlatform);
    }
  }

  Future<File?> saveDataFile(String instrumentName, String fileName,
      List<List<dynamic>> data, String format) async {
    try {
      if (data.length <= 1) {
        logger.w('${appLocalizations.noDataRecorded} $fileName');
        return null;
      }
      final directory = await getInstrumentDirectory(instrumentName);

      String ext = format.toLowerCase();
      String finalFileName;
      if (fileName.isEmpty) {
        finalFileName =
            '${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.$ext';
      } else {
        finalFileName =
            fileName.endsWith('.$ext') ? fileName : '$fileName.$ext';
      }

      final file = File('${directory.path}/$finalFileName');

      String fileContent;
      String upperFormat = format.toUpperCase();
      if (upperFormat == 'JSON') {
        fileContent = jsonEncode(data);
      } else if (upperFormat == 'TXT') {
        final codec = csv.Csv(fieldDelimiter: '\t');
        fileContent = codec.encode(data);
      } else {
        final codec = csv.Csv();
        fileContent = codec.encode(data);
      }

      await file.writeAsString(fileContent);
      logger.i('${appLocalizations.csvFileSaved}: ${file.path}');

      if (Platform.isAndroid) {
        try {
          final externalDir = await getExternalStorageDirectory();
          final pslabDir = Directory('${externalDir?.path}/PSLab');

          final logEntries =
              <({String fileName, String instrument, DateTime modified})>[];
          if (await pslabDir.exists()) {
            for (final entity in pslabDir.listSync(followLinks: false)) {
              if (entity is! Directory) continue;
              final instrument = entity.path.split('/').last;
              for (final file in entity
                  .listSync(followLinks: false)
                  .whereType<File>()
                  .where((f) => _isSupportedFormat(f.path))) {
                logEntries.add((
                  fileName: file.path.split('/').last,
                  instrument: instrument,
                  modified: file.statSync().modified,
                ));
              }
            }
          }
          logEntries.sort((a, b) => b.modified.compareTo(a.modified));
          final widgetListData = logEntries
              .take(20)
              .map((e) => {'fileName': e.fileName, 'instrument': e.instrument})
              .toList();

          await HomeWidget.saveWidgetData<String>(
              'logs_json_key', jsonEncode(widgetListData));
          await HomeWidget.updateWidget(androidName: 'widget.WidgetReceiver');
        } catch (widgetError) {
          logger.w('Error during widget update: $widgetError');
        }
      }

      return file;
    } catch (e) {
      logger.e('${appLocalizations.csvSavingError}: $e');
      return null;
    }
  }

  Future<List<FileSystemEntity>> getSavedFiles(String instrumentName) async {
    try {
      final directory = await getInstrumentDirectory(instrumentName);
      final files = directory
          .listSync()
          .where((item) => _isSupportedFormat(item.path))
          .toList();
      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      logger.e('${appLocalizations.csvGettingError}: $e');
      return [];
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logger.i('${appLocalizations.fileDeleted}: $filePath');
      }
    } catch (e) {
      logger.e('${appLocalizations.csvDeletingError}: $e');
    }
  }

  Future<String?> renameFile(String filePath, String newBaseName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final trimmed = newBaseName.trim().replaceAll(RegExp(r'[\\/]'), '');
      if (trimmed.isEmpty) return null;

      final extension = file.path.split('.').last;
      final newName =
          trimmed.endsWith('.$extension') ? trimmed : '$trimmed.$extension';
      final newPath = '${file.parent.path}/$newName';

      if (newPath == filePath) return filePath;
      if (await File(newPath).exists()) {
        logger.w('Cannot rename: $newName already exists.');
        return null;
      }

      final renamed = await file.rename(newPath);
      logger.i('File renamed to ${renamed.path}');
      return renamed.path;
    } catch (e) {
      logger.e('Error renaming file: $e');
      return null;
    }
  }

  Future<void> deleteAllFiles(String instrumentName) async {
    try {
      final directory = await getInstrumentDirectory(instrumentName);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        logger.i('All files for $instrumentName deleted.');
      }
    } catch (e) {
      logger.e('Error deleting all files for $instrumentName: $e');
    }
  }

  Future<void> shareFile(String filePath) async {
    try {
      final xFile = XFile(filePath);
      await SharePlus.instance.share(
          ShareParams(files: [xFile], text: appLocalizations.sharingMessage));
    } catch (e) {
      logger.e('${appLocalizations.sharingError}: $e');
    }
  }

  Future<(List<List<dynamic>>, String, String)?> pickAndReadFile(
      List<String> allowedInstruments) async {
    try {
      logger.i(
          'Opening file picker. Allowed instruments count: ${allowedInstruments.length}');
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'json'],
      );

      if (result != null && result.path != null) {
        final file = File(result.path!);
        final fileName = result.name;
        logger.i('File selected: ${file.path}');

        final data = await readDataFromFile(file);

        if (data.length < 2) {
          logger.w('Validation Failed: Imported file has insufficient rows.');
          return (<List<dynamic>>[], '', fileName);
        }

        String detectedInstrument = '';
        if (data[0].isNotEmpty) {
          detectedInstrument = data[0][0].toString().toLowerCase().trim();
        }

        String? matchedInstrument =
            allowedInstruments.cast<String?>().firstWhere(
                  (inst) => inst!.toLowerCase() == detectedInstrument,
                  orElse: () => null,
                );

        if (matchedInstrument == null && data.length > 1) {
          final fileHeaders =
              data[1].map((e) => e.toString().toLowerCase().trim()).toList();
          for (String allowedInst in allowedInstruments) {
            if (_verifyInstrumentHeaders(allowedInst, fileHeaders)) {
              matchedInstrument = allowedInst;
              logger.i(
                  'Matched instrument "$matchedInstrument" via header fallback.');
              break;
            }
          }
        }

        if (matchedInstrument == null) {
          logger.w(
              'Validation Failed: "$detectedInstrument" is not allowed here.');
          return (<List<dynamic>>[], detectedInstrument, fileName);
        }

        if (!_isValidFormat(data, matchedInstrument)) {
          logger.w('File format validation failed for $matchedInstrument.');
          return (<List<dynamic>>[], matchedInstrument, fileName);
        }

        return (data, matchedInstrument, fileName);
      }
    } catch (e) {
      logger.e('${appLocalizations.csvPickingError}: $e');
    }
    return null;
  }

  bool _isValidFormat(List<List<dynamic>> data, String detectedInstrument) {
    int headerIndex = 1;

    if (data.length <= headerIndex) {
      logger.w('Validation Failed: No data found after headers.');
      return false;
    }
    final headers = data[headerIndex]
        .map((e) => e.toString().toLowerCase().trim())
        .toList();
    logger.i('Extracted file headers: $headers');

    bool hasRequiredColumns =
        _verifyInstrumentHeaders(detectedInstrument, headers);
    if (!hasRequiredColumns) return false;

    int expectedColumnCount = data[headerIndex].length;
    logger.i('Expecting all data rows to have $expectedColumnCount columns.');

    for (int i = headerIndex + 1; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      if (data[i].length != expectedColumnCount) {
        logger.w(
            'Validation Failed at Row $i: Column mismatch. Expected $expectedColumnCount, got ${data[i].length}.');
        logger.w('Problematic Row Data: ${data[i]}');
        return false;
      }
    }

    return true;
  }

  bool _verifyInstrumentHeaders(String instrument, List<String> fileHeaders) {
    final Map<String, List<String>> requiredColumns = {
      appLocalizations.accelerometer.toLowerCase(): [
        'timestamp',
        'datetime',
        'readingsx',
        'readingsy',
        'readingsz'
      ],
      appLocalizations.barometer.toLowerCase(): [
        'timestamp',
        'datetime',
        'pressure',
        'altitude'
      ],
      appLocalizations.compass.toLowerCase(): [
        'timestamp',
        'datetime',
        'bx',
        'by',
        'bz',
        'degree'
      ],
      appLocalizations.gasSensor.toLowerCase(): [
        'timestamp',
        'datetime',
        'readings',
        'active gas'
      ],
      appLocalizations.gyroscope.toLowerCase(): [
        'timestamp',
        'datetime',
        'readingsx',
        'readingsy',
        'readingsz'
      ],
      appLocalizations.logicAnalyzer.toLowerCase(): [
        'timestamp',
        'datetime',
        'readings',
        'maxy',
        'miny',
        'channels',
        'edges'
      ],
      appLocalizations.luxMeter.toLowerCase(): [
        'timestamp',
        'datetime',
        'readings'
      ],
      appLocalizations.multimeter.toLowerCase(): [
        'timestamp',
        'datetime',
        'mode',
        'reading',
        'unit'
      ],
      appLocalizations.oledDisplayTitle.toLowerCase(): [
        'timestamp',
        'datetime',
        'framebufferhex'
      ],
      appLocalizations.oscilloscope.toLowerCase(): [
        'timestamp',
        'datetime',
        'readings',
        'channels',
        'xaxisscale',
        'yaxisscale'
      ],
      appLocalizations.powerSource.toLowerCase(): [
        'timestamp',
        'datetime',
        'pv1',
        'pv2',
        'pv3',
        'pcs'
      ],
      appLocalizations.roboticArmTitle.toLowerCase(): [
        'timestamp',
        'servo1',
        'servo2',
        'servo3',
        'servo4',
        'datetime'
      ],
      appLocalizations.soundMeter.toLowerCase(): [
        'timestamp',
        'datetime',
        'readings'
      ],
      appLocalizations.thermometer.toLowerCase(): [
        'timestamp',
        'datetime',
        'readings'
      ],
      appLocalizations.waveGenerator.toLowerCase(): [
        'timestamp',
        'datetime',
        'waveform data'
      ],
    };

    final required = requiredColumns[instrument.toLowerCase()];

    if (required == null) return true;
    for (String col in required) {
      if (!fileHeaders.any((header) => header == col)) {
        logger
            .w('Missing required column "$col" for instrument "$instrument".');
        return false;
      }
    }

    return true;
  }

  Future<List<List<dynamic>>> readDataFromFile(File file) async {
    try {
      final extension = file.path.split('.').last.toLowerCase();

      if (extension == 'json') {
        final content = await file.readAsString();

        try {
          final decoded = jsonDecode(content) as List<dynamic>;

          return decoded.map((row) {
            return (row as List<dynamic>).map((cell) {
              if (cell is String) {
                return num.tryParse(cell) ?? cell;
              }
              return cell;
            }).toList();
          }).toList();
        } catch (e) {
          logger.w(
              'JSON parse failed. Falling back to CSV parser for corrupted file. Error: $e');

          final codec = csv.Csv(dynamicTyping: true);
          final lines = const LineSplitter().convert(content);
          final List<List<dynamic>> rows = [];

          for (final line in lines) {
            final parsedRow = codec.decode(line);
            if (parsedRow.isNotEmpty) {
              rows.add(parsedRow.first);
            }
          }
          return rows;
        }
      } else {
        final lines = file
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        final List<List<dynamic>> rows = [];

        final codec = extension == 'txt'
            ? csv.Csv(fieldDelimiter: '\t', dynamicTyping: true)
            : csv.Csv(dynamicTyping: true);

        await for (final line in lines) {
          final parsedRow = codec.decode(line);
          if (parsedRow.isNotEmpty) {
            rows.add(parsedRow.first);
          }
        }
        return rows;
      }
    } catch (e) {
      logger.e('${appLocalizations.csvReadingError}: $e');
      return [];
    }
  }

  void writeMetaData(String instrumentName, List<List<dynamic>> data,
      {String? extraMetadata}) {
    if (data.isNotEmpty && data[0].isNotEmpty && data[0][0] == instrumentName) {
      return;
    }

    final now = DateTime.now();
    final sdf = DateFormat('yyyy-MM-dd HH:mm:ss');
    final metaDataTime = sdf.format(now);
    final metaData = <dynamic>[
      instrumentName,
      metaDataTime.split(' ')[0],
      metaDataTime.split(' ')[1],
      if (extraMetadata != null) extraMetadata,
    ];
    data.insert(0, metaData);
  }
}
