import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/theme/colors.dart';

class SaveDialogResult {
  final String fileName;
  final String format;
  SaveDialogResult(this.fileName, this.format);
}

Future<SaveDialogResult?> showAdaptiveSaveDialog(
  BuildContext context, {
  required String defaultFormat,
  String? customTitle,
  List<Widget>? extraWidgets,
}) {
  return showDialog<SaveDialogResult>(
    context: context,
    builder: (context) => _AdaptiveSaveDialog(
      defaultFormat: defaultFormat,
      customTitle: customTitle,
      extraWidgets: extraWidgets,
    ),
  );
}

class _AdaptiveSaveDialog extends StatefulWidget {
  final String defaultFormat;
  final String? customTitle;
  final List<Widget>? extraWidgets;

  const _AdaptiveSaveDialog({
    required this.defaultFormat,
    this.customTitle,
    this.extraWidgets,
  });

  @override
  State<_AdaptiveSaveDialog> createState() => _AdaptiveSaveDialogState();
}

class _AdaptiveSaveDialogState extends State<_AdaptiveSaveDialog> {
  late TextEditingController _controller;
  late String _selectedFormat;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.defaultFormat.toUpperCase();
    _controller = TextEditingController(
      text: DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now()),
    );
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final OutlineInputBorder defaultBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(4),
    );
    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: primaryRed, width: 2.0),
      borderRadius: BorderRadius.circular(4),
    );

    final double titleFontSize = isLandscape ? 14.0 : 18.0;
    final double inputFontSize = isLandscape ? 12.0 : 14.0;
    final double buttonFontSize = isLandscape ? 12.0 : 14.0;
    final EdgeInsets inputPadding = isLandscape
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 12);

    return Dialog(
      alignment: isLandscape ? Alignment.topCenter : Alignment.center,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: isLandscape
          ? const EdgeInsets.only(
              top: 24.0, left: 32.0, right: 32.0, bottom: 8.0)
          : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      child: SingleChildScrollView(
        child: Padding(
          padding: isLandscape
              ? const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 10.0)
              : const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customTitle ?? appLocalizations.saveRecording,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: titleFontSize,
                ),
              ),
              SizedBox(height: isLandscape ? 8 : 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: kMaxFileNameLength,
                      cursorColor: primaryRed,
                      style: TextStyle(fontSize: inputFontSize),
                      decoration: InputDecoration(
                        hintText: appLocalizations.enterFileName,
                        labelText: appLocalizations.fileName,
                        floatingLabelStyle: TextStyle(color: primaryRed),
                        counterText: '',
                        isDense: true,
                        border: defaultBorder,
                        enabledBorder: defaultBorder,
                        focusedBorder: focusedBorder,
                        contentPadding: inputPadding,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: isLandscape ? 80 : 90,
                    child: DropdownButtonFormField<String>(
                      value: _selectedFormat,
                      iconEnabledColor: primaryRed,
                      style: TextStyle(
                          fontSize: inputFontSize, color: Colors.black),
                      decoration: InputDecoration(
                        isDense: true,
                        border: defaultBorder,
                        enabledBorder: defaultBorder,
                        focusedBorder: focusedBorder,
                        contentPadding: inputPadding,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CSV', child: Text('.csv')),
                        DropdownMenuItem(value: 'TXT', child: Text('.txt')),
                        DropdownMenuItem(value: 'JSON', child: Text('.json')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedFormat = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (widget.extraWidgets != null) ...[
                SizedBox(height: isLandscape ? 6 : 12),
                ...widget.extraWidgets!,
              ],
              SizedBox(height: isLandscape ? 12 : 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: primaryRed,
                      visualDensity: isLandscape
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      textStyle: TextStyle(fontSize: buttonFontSize),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(appLocalizations.cancel.toUpperCase()),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      visualDensity: isLandscape
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      textStyle: TextStyle(fontSize: buttonFontSize),
                      padding: isLandscape
                          ? const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6)
                          : const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(
                          context,
                          SaveDialogResult(
                              _controller.text.trim(), _selectedFormat));
                    },
                    child: Text(appLocalizations.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
