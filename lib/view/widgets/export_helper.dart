import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/settings_config_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/save_filename_dialog.dart';

import '../../others/data_service.dart';

class ExportHelper {
  static Future<void> handleSaveData({
    required BuildContext context,
    required String instrumentName,
    required List<List<dynamic>> data,
    String? extraMetadata,
    String? customTitle,
    List<Widget>? extraWidgets,
  }) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final dataService = DataService();
    final defaultFormat =
        Provider.of<SettingsConfigProvider>(context, listen: false)
            .config
            .exportFormat;

    final SaveDialogResult? result = await showAdaptiveSaveDialog(
      context,
      defaultFormat: defaultFormat,
      customTitle: customTitle,
      extraWidgets: extraWidgets,
    );

    if (result != null && result.fileName.isNotEmpty) {
      dataService.writeMetaData(
        instrumentName,
        data,
        extraMetadata: extraMetadata,
      );

      final file = await dataService.saveDataFile(
        instrumentName,
        result.fileName,
        data,
        result.format,
      );

      if (context.mounted) {
        if (file != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${appLocalizations.fileSaved}: ${file.path.split('/').last}',
                style: TextStyle(color: snackBarContentColor),
              ),
              backgroundColor: snackBarBackgroundColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appLocalizations.failedToSave,
                style: TextStyle(color: snackBarContentColor),
              ),
              backgroundColor: snackBarBackgroundColor,
            ),
          );
        }
      }
    }
  }
}
