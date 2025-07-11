import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool isTxtFormatSelected = false;
  bool isCsvFormatSelected = false;

  @override
  void initState() {
    super.initState();
    isTxtFormatSelected =
        (GetIt.instance.get<BoardStateProvider>().exportFormat ==
            appLocalizations.txtFormat);
    isCsvFormatSelected =
        (GetIt.instance.get<BoardStateProvider>().exportFormat ==
            appLocalizations.csvFormat);
  }

  void _showExportFormatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(appLocalizations.export,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          children: [
            RadioListTile<bool>(
              title: Text(appLocalizations.txtFormat),
              value: true,
              groupValue: isTxtFormatSelected,
              activeColor: primaryRed,
              onChanged: (bool? value) {
                setState(
                  () {
                    isTxtFormatSelected = true;
                    isCsvFormatSelected = false;
                    GetIt.instance.get<BoardStateProvider>().exportFormat =
                        appLocalizations.txtFormat;
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
            RadioListTile<bool>(
              title: Text(appLocalizations.csvFormat),
              value: true,
              groupValue: isCsvFormatSelected,
              activeColor: primaryRed,
              onChanged: (bool? value) {
                setState(
                  () {
                    isTxtFormatSelected = false;
                    isCsvFormatSelected = true;
                    GetIt.instance.get<BoardStateProvider>().exportFormat =
                        appLocalizations.csvFormat;
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, bottom: 5),
                  child: Text(
                    appLocalizations.cancel,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: appLocalizations.settings,
      index: 4,
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 10),
            CheckboxListTile(
              title: Text(appLocalizations.autoStart),
              subtitle: Text(appLocalizations.autoStartText),
              value: GetIt.instance.get<BoardStateProvider>().autoStart,
              onChanged: (bool? value) {
                setState(() {
                  GetIt.instance.get<BoardStateProvider>().autoStart = value!;
                });
              },
              activeColor: primaryRed,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: Text(appLocalizations.export),
              subtitle: Text(appLocalizations.currentFormat +
                  GetIt.instance.get<BoardStateProvider>().exportFormat),
              onTap: () {
                _showExportFormatDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}
