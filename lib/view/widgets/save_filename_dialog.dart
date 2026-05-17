import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

Future<String?> showSaveFileNameDialog(BuildContext context) {
  final AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final TextEditingController filenameController = TextEditingController(
    text: '${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv',
  );

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(appLocalizations.saveRecording),
        content: TextField(
          controller: filenameController,
          maxLength: kMaxFileNameLength,
          decoration: InputDecoration(
            hintText: appLocalizations.enterFileName,
            labelText: appLocalizations.fileName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalizations.cancel.toUpperCase()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, filenameController.text.trim());
            },
            child: Text(appLocalizations.save),
          ),
        ],
      );
    },
  );
}
