import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/barometer_screen.dart';
import 'package:pslab/view/gyroscope_screen.dart';
import 'package:pslab/view/logged_data_chart_screen.dart';
import 'package:pslab/view/luxmeter_screen.dart';
import 'package:pslab/view/map_screen.dart';
import 'package:pslab/view/soundmeter_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/locator.dart';

class LoggedDataScreen extends StatefulWidget {
  final List<String> instrumentNames;
  final String appBarName;
  final List<String> instrumentIcons;

  const LoggedDataScreen(
      {super.key,
      required this.instrumentNames,
      required this.appBarName,
      required this.instrumentIcons});

  @override
  State<LoggedDataScreen> createState() => _LoggedDataScreenState();
}

class LoggedDataFile {
  final String instrumentName;
  final FileSystemEntity file;

  LoggedDataFile({required this.instrumentName, required this.file});
}

class _LoggedDataScreenState extends State<LoggedDataScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final CsvService _csvService = CsvService();
  List<LoggedDataFile> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });
    _files = [];
    for (var name in widget.instrumentNames) {
      final files = await _csvService.getSavedFiles(name);
      for (var file in files) {
        _files.add(LoggedDataFile(instrumentName: name, file: file));
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(String filePath, {bool askConfirm = true}) async {
    bool confirmed = true;
    if (askConfirm) {
      confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(appLocalizations.deleteFile),
                content: Text(appLocalizations.deleteHint),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(appLocalizations.cancel.toUpperCase()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(appLocalizations.delete),
                  ),
                ],
              );
            },
          ) ??
          false;
    }

    if (confirmed) {
      await _csvService.deleteFile(filePath);
      _loadFiles();
    }
  }

  Future<void> _deleteAllFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.deleteAllData),
          content: Text(appLocalizations.deleteCautionMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(appLocalizations.cancel.toUpperCase()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(appLocalizations.deleteAll),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      for (var name in widget.instrumentNames) {
        await _csvService.deleteAllFiles(name);
      }
      _loadFiles();
    }
  }

  Map<String, dynamic> _getChartConfig(String instrumentName) {
    switch (instrumentName.toLowerCase()) {
      case 'luxmeter':
        return {
          'xAxisLabel': appLocalizations.timeAxisLabel,
          'yAxisLabel': appLocalizations.lx,
          'xDataColumnIndex': 0,
          'yDataColumnIndex': 2,
        };
      case 'soundmeter':
        return {
          'xAxisLabel': appLocalizations.timeAxisLabel,
          'yAxisLabel': appLocalizations.db,
          'xDataColumnIndex': 0,
          'yDataColumnIndex': 2,
        };
      case 'barometer':
        return {
          'xAxisLabel': appLocalizations.timeAxisLabel,
          'yAxisLabel': appLocalizations.atm,
          'xDataColumnIndex': 0,
          'yDataColumnIndex': 2,
        };
      default:
        return {
          'xAxisLabel': appLocalizations.timeAxisLabel,
          'yAxisLabel': 'Value',
          'xDataColumnIndex': 0,
          'yDataColumnIndex': 2,
        };
    }
  }

  Future<void> _openFile(File file, String instrumentName) async {
    final data = await _csvService.readCsvFromFile(file);
    if (mounted) {
      if (instrumentName.toLowerCase() == 'robotic arm') {
        Navigator.pop(context, data);
      } else {
        final config = _getChartConfig(instrumentName);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoggedDataChartScreen(
              data: data,
              fileName: file.path.split('/').last,
              xAxisLabel: config['xAxisLabel'],
              yAxisLabel: config['yAxisLabel'],
              xDataColumnIndex: config['xDataColumnIndex'],
              yDataColumnIndex: config['yDataColumnIndex'],
              instrumentName: instrumentName,
            ),
          ),
        );
      }
    }
  }

  Future<void> _playFile(File file, String instrumentName) async {
    final data = await _csvService.readCsvFromFile(file);
    if (data.isNotEmpty && mounted) {
      switch (instrumentName) {
        case 'soundmeter':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SoundMeterScreen(playbackData: data),
            ),
          );
          break;
        case 'barometer':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarometerScreen(playbackData: data),
            ),
          );
          break;
        case 'gyroscope':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GyroscopeScreen(playbackData: data),
            ),
          );
          break;
        case 'luxmeter':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LuxMeterScreen(playbackData: data),
            ),
          );
          break;
      }
    }
  }

  Future<void> _pickAndImportFile(String instrumentName) async {
    final data = await _csvService.pickAndReadCsvFile();
    if (data != null && mounted) {
      if (instrumentName.toLowerCase() == 'robotic arm') {
        Navigator.pop(context, data);
      } else {
        final config = _getChartConfig(instrumentName);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoggedDataChartScreen(
              data: data,
              fileName: 'Imported Log',
              xAxisLabel: config['xAxisLabel'],
              yAxisLabel: config['yAxisLabel'],
              xDataColumnIndex: config['xDataColumnIndex'],
              yDataColumnIndex: config['yDataColumnIndex'],
              instrumentName: instrumentName,
            ),
          ),
        );
      }
    }
  }

  void _showOptionsMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        kToolbarHeight,
        0,
        0,
      ),
      items: [
        if (widget.instrumentNames.length == 1)
          PopupMenuItem(
            value: 'import_log',
            child: Text(appLocalizations.importLog),
          ),
        PopupMenuItem(
          value: 'delete_all',
          child: Text(appLocalizations.deleteAllData),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'import_log':
            _pickAndImportFile(widget.instrumentNames.first);
            break;
          case 'delete_all':
            _deleteAllFiles();
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.appBarName,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
        backgroundColor: primaryRed,
        iconTheme: IconThemeData(color: appBarContentColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Text(
                    appLocalizations.noLoggedData,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFiles,
                  child: ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index].file as File;
                      final stat = file.statSync();
                      final fileName = file.path.split('/').last;
                      final instrumentName = _files[index].instrumentName;
                      final formattedDate =
                          DateFormat.yMMMd().add_jm().format(stat.modified);

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        margin:
                            const EdgeInsets.only(left: 8, right: 8, top: 8),
                        child: ListTile(
                          onTap: () => _openFile(file, instrumentName),
                          leading: Image.asset(
                            widget.instrumentIcons[
                                widget.instrumentNames.indexOf(instrumentName)],
                            color: primaryRed,
                          ),
                          title: Text(fileName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${(stat.size / 1024).toStringAsFixed(2)} KB\n$formattedDate'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.black),
                            onSelected: (value) async {
                              if (value == appLocalizations.play) {
                                _playFile(file, instrumentName);
                              } else if (value == appLocalizations.location) {
                                final data =
                                    await _csvService.readCsvFromFile(file);
                                if (!context.mounted) return;
                                double latitude = 0;
                                double longitude = 0;
                                if (data[data.length - 1]
                                        [data[data.length - 1].length - 2]
                                    is double) {
                                  latitude = data[data.length - 1]
                                          [data[data.length - 1].length - 2]
                                      .toDouble();
                                  longitude = data[data.length - 1]
                                          [data[data.length - 1].length - 1]
                                      .toDouble();
                                }
                                if (latitude == 0 && longitude == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        appLocalizations
                                            .noLocationDataAvailable,
                                        style: TextStyle(
                                            color: snackBarContentColor),
                                      ),
                                      backgroundColor: snackBarBackgroundColor,
                                    ),
                                  );
                                  return;
                                }
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapScreen(
                                      latitude: latitude,
                                      longitude: longitude,
                                    ),
                                  ),
                                );
                              } else if (value == appLocalizations.share) {
                                _csvService.shareFile(file.path);
                              } else if (value == appLocalizations.delete) {
                                _deleteFile(file.path);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              if (instrumentName ==
                                      appLocalizations.soundMeter
                                          .toLowerCase() ||
                                  instrumentName ==
                                      appLocalizations.barometer
                                          .toLowerCase() ||
                                  instrumentName ==
                                      appLocalizations.gyroscope
                                          .toLowerCase() ||
                                  instrumentName ==
                                      appLocalizations.luxMeter.toLowerCase())
                                PopupMenuItem<String>(
                                  value: appLocalizations.play,
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Icons.play_arrow,
                                      color: primaryRed,
                                    ),
                                    title: Text(
                                      appLocalizations.play,
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              PopupMenuItem<String>(
                                value: appLocalizations.location,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.map,
                                    color: primaryRed,
                                  ),
                                  title: Text(
                                    appLocalizations.location,
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: appLocalizations.share,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.share,
                                    color: primaryRed,
                                  ),
                                  title: Text(
                                    appLocalizations.share,
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: appLocalizations.delete,
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.delete,
                                    color: primaryRed,
                                  ),
                                  title: Text(
                                    appLocalizations.delete,
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
