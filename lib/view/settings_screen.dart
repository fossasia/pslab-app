import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:pslab/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isTxtFormatSelected =
      (GetIt.instance.get<BoardStateProvider>().exportFormat == txtFormat);
  bool isCsvFormatSelected =
      (GetIt.instance.get<BoardStateProvider>().exportFormat == csvFormat);

  void _showExportFormatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(export,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          children: [
            RadioListTile<bool>(
              title: Text(txtFormat),
              value: true,
              groupValue: isTxtFormatSelected,
              activeColor: primaryRed,
              onChanged: (bool? value) {
                setState(
                  () {
                    isTxtFormatSelected = true;
                    isCsvFormatSelected = false;
                    GetIt.instance.get<BoardStateProvider>().exportFormat =
                        txtFormat;
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
            RadioListTile<bool>(
              title: Text(csvFormat),
              value: true,
              groupValue: isCsvFormatSelected,
              activeColor: primaryRed,
              onChanged: (bool? value) {
                setState(
                  () {
                    isTxtFormatSelected = false;
                    isCsvFormatSelected = true;
                    GetIt.instance.get<BoardStateProvider>().exportFormat =
                        csvFormat;
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
                    cancel,
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
      title: settings,
      index: 4,
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 10),
            CheckboxListTile(
              title: Text(start),
              subtitle: Text(autoStartText),
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
              title: Text(export),
              subtitle: Text(currentFormat +
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
