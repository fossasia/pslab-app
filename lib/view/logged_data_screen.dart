import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/barometer_screen.dart';
import 'package:pslab/view/gyroscope_screen.dart';
import 'package:pslab/view/logged_data_chart_screen.dart';
import 'package:pslab/view/logic_analyzer_screen.dart';
import 'package:pslab/view/luxmeter_screen.dart';
import 'package:pslab/view/map_screen.dart';
import 'package:pslab/view/multimeter_screen.dart';
import 'package:pslab/view/oscilloscope_screen.dart';
import 'package:pslab/view/power_source_screen.dart';
import 'package:pslab/view/soundmeter_screen.dart';
import 'package:pslab/view/wave_generator_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/locator.dart';
import 'accelerometer_screen.dart';
import 'compass_screen.dart';
import 'package:pslab/view/thermometer_screen.dart';

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
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  final CsvService _csvService = CsvService();
  List<LoggedDataFile> _allFiles = [];
  List<LoggedDataFile> _filteredFiles = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  final FocusNode _keyboardFocusNode = FocusNode(debugLabel: 'LoggedDataKeys');
  int _selectedIndex = -1;
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });
    _allFiles = [];
    for (var name in widget.instrumentNames) {
      final files = await _csvService.getSavedFiles(name);
      for (var file in files) {
        _allFiles.add(LoggedDataFile(instrumentName: name, file: file));
      }
    }

    if (Platform.isAndroid) {
      try {
        final List<Map<String, String>> widgetListData = _allFiles.map((f) {
          final fileName = f.file.path.split('/').last;
          return {
            'fileName': fileName,
            'instrument': f.instrumentName,
          };
        }).toList();

        await HomeWidget.saveWidgetData<String>(
            'logs_json_key', jsonEncode(widgetListData));

        await HomeWidget.updateWidget(androidName: 'widget.WidgetReceiver');
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_selectedIndex >= _filteredFiles.length) {
          _selectedIndex = _filteredFiles.length - 1;
        }
      });
      _filterLogs(_searchController.text);
    }
  }

  GlobalKey _keyFor(String path) =>
      _itemKeys.putIfAbsent(path, () => GlobalKey());

  void _ensureSelectedVisible() {
    if (_selectedIndex < 0 || _selectedIndex >= _filteredFiles.length) return;
    final ctx =
        _itemKeys[_filteredFiles[_selectedIndex].file.path]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 200),
        alignment: 0.5,
      );
    }
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_filteredFiles.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selectedIndex =
          (_selectedIndex + 1).clamp(0, _filteredFiles.length - 1));
      _ensureSelectedVisible();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(
          () => _selectedIndex = _selectedIndex <= 0 ? 0 : _selectedIndex - 1);
      _ensureSelectedVisible();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_selectedIndex >= 0 && _selectedIndex < _filteredFiles.length) {
        final selected = _filteredFiles[_selectedIndex];
        _openFile(File(selected.file.path), selected.instrumentName);
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.delete) {
      if (_selectedIndex >= 0 && _selectedIndex < _filteredFiles.length) {
        _deleteFile(_filteredFiles[_selectedIndex].file.path);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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

  Future<void> _renameFile(File file) async {
    final currentName = file.uri.pathSegments.last.replaceAll('.csv', '');
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.renameLog),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  appLocalizations.renameHint,
                  style: TextStyle(fontSize: 14, color: hintTextColor),
                ),
              ),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryRed),
                  ),
                  suffixText: '.csv',
                ),
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                appLocalizations.cancel.toUpperCase(),
                style: TextStyle(color: primaryRed),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(
                appLocalizations.ok,
                style: TextStyle(color: primaryRed),
              ),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.trim().isEmpty) return;
    if (newName.trim() == currentName) return;

    final newPath = await _csvService.renameFile(file.path, newName);
    if (!mounted) return;
    if (newPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLocalizations.fileNameExists,
            style: TextStyle(color: snackBarContentColor),
          ),
          backgroundColor: snackBarBackgroundColor,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appLocalizations.renamed,
          style: TextStyle(color: snackBarContentColor),
        ),
        backgroundColor: snackBarBackgroundColor,
      ),
    );
    _loadFiles();
  }

  Future<void> _deleteAllFiles() async {
    if (_isLoading) {
      return;
    }
    if (_allFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLocalizations.noLoggedData,
            style: TextStyle(color: snackBarContentColor),
          ),
          backgroundColor: snackBarBackgroundColor,
        ),
      );
      return;
    }
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
    // Oscilloscope recordings store waveform frames, not a simple x/y table,
    // so the generic chart viewer can't render them ("No valid data to
    // display"). Tapping the file should behave like Play and open the
    // oscilloscope playback screen, which also shows the recording details.
    if (instrumentName.toLowerCase() == 'oscilloscope' ||
        instrumentName.toLowerCase() ==
            appLocalizations.logicAnalyzer.toLowerCase()) {
      return _playFile(file, instrumentName);
    }
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
        case 'sound meter':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SoundMeterScreen(playbackData: data),
            ),
          );
          break;
        case 'thermometer':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThermometerScreen(playbackData: data),
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
        case 'power source':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PowerSourceScreen(playbackData: data),
            ),
          );
        case 'luxmeter':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LuxMeterScreen(playbackData: data),
            ),
          );
          break;
        case 'wave generator':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WaveGeneratorScreen(playbackData: data),
            ),
          );
          break;
        case 'oscilloscope':
          final recordingName =
              file.uri.pathSegments.last.replaceAll('.csv', '');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OscilloscopeScreen(
                playbackData: data,
                playbackName: recordingName,
              ),
            ),
          );
          break;
        case 'multimeter':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultimeterScreen(playbackData: data),
            ),
          );
          break;
        case 'logic analyzer':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LogicAnalyzerScreen(
                playbackData: data,
                fileName: file.uri.pathSegments.last,
              ),
            ),
          );
          break;
        case 'accelerometer':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccelerometerScreen(playbackData: data),
            ),
          );
          break;
        case 'compass':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompassScreen(playbackData: data),
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

  void _filterLogs(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredFiles = List.from(_allFiles);
      } else {
        final search = query.trim().toLowerCase();
        _filteredFiles = _allFiles.where((loggedFile) {
          final fileName = loggedFile.file.uri.pathSegments.last.toLowerCase();
          final instrumentName = loggedFile.instrumentName.toLowerCase();
          return fileName.contains(search) || instrumentName.contains(search);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryRed,
        iconTheme: IconThemeData(color: appBarContentColor),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _filterLogs,
                style: TextStyle(
                  color: appBarContentColor,
                ),
                decoration: InputDecoration(
                  hintText: appLocalizations.searchLoggedDataHint,
                  hintStyle: TextStyle(
                    color: searchBarHintTextColor,
                  ),
                  border: InputBorder.none,
                ),
                cursorColor: appBarContentColor,
              )
            : Text(
                widget.appBarName,
                style: TextStyle(
                  color: appBarContentColor,
                  fontSize: 15,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              tooltip: appLocalizations.close,
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _filteredFiles = List.from(_allFiles);
                });
              },
            )
          else ...[
            IconButton(
              tooltip: appLocalizations.search,
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  _filteredFiles = List.from(_allFiles);
                });
              },
            ),
            IconButton(
              tooltip: appLocalizations.options,
              icon: const Icon(Icons.more_vert),
              onPressed: _showOptionsMenu,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredFiles.isEmpty
              ? Center(
                  child: Text(
                    appLocalizations.noLoggedData,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                )
              : Focus(
                  focusNode: _keyboardFocusNode,
                  canRequestFocus: !_isSearching,
                  autofocus: !_isSearching,
                  onKeyEvent: (node, event) => _handleKey(event),
                  child: RefreshIndicator(
                    onRefresh: _loadFiles,
                    child: ListView.builder(
                      itemCount: _filteredFiles.length,
                      itemBuilder: (context, index) {
                        final file = File(_filteredFiles[index].file.path);
                        final stat = file.statSync();
                        final fileName = file.uri.pathSegments.last;
                        final instrumentName =
                            _filteredFiles[index].instrumentName;
                        final formattedDate =
                            DateFormat.yMMMd().add_jm().format(stat.modified);
                        final bool selected = index == _selectedIndex;

                        return Card(
                          key: _keyFor(file.path),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          color: selected
                              ? primaryRed.withValues(alpha: 0.08)
                              : Theme.of(context).colorScheme.surface,
                          margin:
                              const EdgeInsets.only(left: 8, right: 8, top: 8),
                          child: ListTile(
                            onTap: () {
                              setState(() => _selectedIndex = index);
                              _openFile(file, instrumentName);
                            },
                            leading: Image.asset(
                              widget.instrumentIcons[widget.instrumentNames
                                  .indexOf(instrumentName)],
                              color: primaryRed,
                            ),
                            title: Text(fileName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
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
                                        backgroundColor:
                                            snackBarBackgroundColor,
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
                                } else if (value == appLocalizations.rename) {
                                  _renameFile(file);
                                } else if (value == appLocalizations.delete) {
                                  _deleteFile(file.path);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                if (instrumentName == appLocalizations.soundMeter.toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.barometer
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.powerSource
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.gyroscope
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.luxMeter
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.waveGenerator
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.oscilloscope
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.multimeter
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.logicAnalyzer
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.accelerometer
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.compassTitle
                                            .toLowerCase() ||
                                    instrumentName ==
                                        appLocalizations.thermometerTitle
                                            .toLowerCase())
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
                                  value: appLocalizations.rename,
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Icons.drive_file_rename_outline,
                                      color: primaryRed,
                                    ),
                                    title: Text(
                                      appLocalizations.rename,
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
                ),
    );
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
