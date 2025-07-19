import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/logged_data_chart_screen.dart';

import '../l10n/app_localizations.dart';
import '../providers/locator.dart';

class LoggedDataScreen extends StatefulWidget {
  final String instrumentName;
  final String appBarName;
  final String instrumentIcon;

  const LoggedDataScreen(
      {super.key,
      required this.instrumentName,
      required this.appBarName,
      required this.instrumentIcon});

  @override
  State<LoggedDataScreen> createState() => _LoggedDataScreenState();
}

class _LoggedDataScreenState extends State<LoggedDataScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final CsvService _csvService = CsvService();
  List<FileSystemEntity> _files = [];
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
    final files = await _csvService.getSavedFiles(widget.instrumentName);
    if (mounted) {
      setState(() {
        _files = files;
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
                    child: Text(appLocalizations.cancel),
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
              child: Text(appLocalizations.cancel),
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
      await _csvService.deleteAllFiles(widget.instrumentName);
      _loadFiles();
    }
  }

  Map<String, dynamic> _getChartConfig() {
    switch (widget.instrumentName.toLowerCase()) {
      case 'luxmeter':
        return {
          'xAxisLabel': appLocalizations.timeAxisLabel,
          'yAxisLabel': appLocalizations.lx,
          'xDataColumnIndex': 1,
          'yDataColumnIndex': 2,
        };
      case 'soundmeter':
        return {
          'xAxisLabel': appLocalizations.timeAxisLabel,
          'yAxisLabel': appLocalizations.db,
          'xDataColumnIndex': 1,
          'yDataColumnIndex': 2,
        };
      case 'barometer':
        return {
          'xAxisLabel': appLocalizations.timeAxisLabel,
          'yAxisLabel': appLocalizations.atm,
          'xDataColumnIndex': 1,
          'yDataColumnIndex': 2,
        };
      default:
        return {
          'xAxisLabel': appLocalizations.timeAxisLabel,
          'yAxisLabel': 'Value',
          'xDataColumnIndex': 1,
          'yDataColumnIndex': 2,
        };
    }
  }

  Future<void> _openFile(File file) async {
    final data = await _csvService.readCsvFromFile(file);
    if (mounted) {
      final config = _getChartConfig();
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
          ),
        ),
      );
    }
  }

  Future<void> _pickAndImportFile() async {
    final data = await _csvService.pickAndReadCsvFile();
    if (data != null && mounted) {
      final config = _getChartConfig();
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
          ),
        ),
      );
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
            _pickAndImportFile();
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
                      final file = _files[index] as File;
                      final stat = file.statSync();
                      final fileName = file.path.split('/').last;
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
                          onTap: () => _openFile(file),
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: Image.asset(
                              widget.instrumentIcon,
                              color: primaryRed,
                            ),
                          ),
                          title: Text(fileName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${(stat.size / 1024).toStringAsFixed(2)} KB\n$formattedDate'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.share, color: primaryRed),
                                onPressed: () =>
                                    _csvService.shareFile(file.path),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: primaryRed),
                                onPressed: () => _deleteFile(file.path),
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
