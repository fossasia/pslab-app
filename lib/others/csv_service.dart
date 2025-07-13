import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pslab/others/logger_service.dart';
import 'package:pslab/view/about_us_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class CsvService {
  static const String csvDirectory = 'PSLab';

  Future<Directory> getInstrumentDirectory(String instrumentName) async {
    if (Platform.isAndroid) {
      await requestStoragePermission();
      final directory =
          Directory('/storage/emulated/0/Android/media/PSLab/$instrumentName');
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
      throw UnsupportedError('Unsupported platform');
    }
  }

  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        await openAppSettings();
      }
    }
  }

  Future<File?> saveCsvFile(
      String instrumentName, String fileName, List<List<dynamic>> data) async {
    try {
      if (data.length <= 1) {
        logger.w('No data recorded to save for $fileName');
        return null;
      }
      final directory = await getInstrumentDirectory(instrumentName);

      String finalFileName;
      if (fileName.isEmpty) {
        finalFileName =
            '${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv';
      } else {
        finalFileName = fileName.endsWith('.csv') ? fileName : '$fileName.csv';
      }

      final file = File('${directory.path}/$finalFileName');

      String csvData = const ListToCsvConverter().convert(data);
      await file.writeAsString(csvData);
      logger.i('CSV file saved at: ${file.path}');
      return file;
    } catch (e) {
      logger.e('Error saving CSV file: $e');
      return null;
    }
  }

  Future<List<FileSystemEntity>> getSavedFiles(String instrumentName) async {
    try {
      final directory = await getInstrumentDirectory(instrumentName);
      final files = directory
          .listSync()
          .where((item) => item.path.endsWith('.csv'))
          .toList();
      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      logger.e('Error getting saved files: $e');
      return [];
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logger.i('File deleted: $filePath');
      }
    } catch (e) {
      logger.e('Error deleting file: $e');
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
      logger.e('Error sharing file: $e');
    }
  }

  Future<List<List<dynamic>>?> pickAndReadCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await readCsvFromFile(file);
      }
    } catch (e) {
      logger.e('Error picking or reading CSV file: $e');
    }
    return null;
  }

  Future<List<List<dynamic>>> readCsvFromFile(File file) async {
    try {
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(shouldParseNumbers: true))
          .toList();
      return fields;
    } catch (e) {
      logger.e('Error reading CSV from file: $e');
      return [];
    }
  }

  void writeMetaData(String instrumentName, List<List<dynamic>> data) {
    if (data.isNotEmpty && data[0].isNotEmpty && data[0][0] == instrumentName) {
      return;
    }

    final now = DateTime.now();
    final sdf = DateFormat('yyyy-MM-dd HH:mm:ss');
    final metaDataTime = sdf.format(now);
    final metaData = [
      instrumentName,
      metaDataTime.split(' ')[0],
      metaDataTime.split(' ')[1]
    ];
    data.insert(0, metaData);
  }
}
