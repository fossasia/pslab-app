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
      if (format == 'JSON') {
        fileContent = jsonEncode(data);
      } else if (format == 'TXT') {
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

  Future<List<List<dynamic>>?> pickAndReadFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await readDataFromFile(file);
      }
    } catch (e) {
      logger.e('${appLocalizations.csvPickingError}: $e');
    }
    return null;
  }

  Future<List<List<dynamic>>> readDataFromFile(File file) async {
    try {
      final extension = file.path.split('.').last.toLowerCase();

      if (extension == 'json') {
        final content = await file.readAsString();
        final decoded = jsonDecode(content) as List<dynamic>;
        return decoded.map((e) => (e as List<dynamic>).toList()).toList();
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
