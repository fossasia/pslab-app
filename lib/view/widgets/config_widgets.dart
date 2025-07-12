import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class ConfigInputItem extends StatelessWidget {
  final AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final String title;
  final String value;
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? hint;

  ConfigInputItem({
    super.key,
    required this.title,
    required this.value,
    required this.controller,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: hintTextColor,
        ),
      ),
      onTap: () =>
          _showInputDialog(context, title, controller, onChanged, hint),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showInputDialog(
      BuildContext context,
      String title,
      TextEditingController controller,
      Function(String) onChanged,
      String? hint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: hintTextColor,
                    ),
                  ),
                ),
              TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: false),
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryRed),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                appLocalizations.cancel,
                style: TextStyle(color: primaryRed),
              ),
            ),
            TextButton(
              onPressed: () {
                onChanged(controller.text);
                Navigator.of(context).pop();
              },
              child: Text(
                appLocalizations.ok,
                style: TextStyle(color: primaryRed),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ConfigDropdownItem extends StatelessWidget {
  final AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final String title;
  final String selectedValue;
  final List<ConfigOption> options;
  final Function(String) onChanged;

  ConfigDropdownItem({
    super.key,
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        selectedValue,
        style: TextStyle(
          fontSize: 14,
          color: hintTextColor,
        ),
      ),
      onTap: () => _showDropdownDialog(context),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showDropdownDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return RadioListTile<String>(
                title: Text(option.displayName),
                value: option.value,
                groupValue: selectedValue,
                onChanged: (String? value) {
                  if (value != null) {
                    onChanged(value);
                    Navigator.of(context).pop();
                  }
                },
                activeColor: primaryRed,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                appLocalizations.cancel,
                style: TextStyle(color: primaryRed),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ConfigCheckboxItem extends StatelessWidget {
  final AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  ConfigCheckboxItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: hintTextColor,
        ),
      ),
      trailing: Checkbox(
        value: value,
        onChanged: (bool? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        activeColor: checkBoxActiveColor,
      ),
      onTap: () {
        onChanged(!value);
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}

class ConfigOption {
  final String value;
  final String displayName;

  const ConfigOption({
    required this.value,
    required this.displayName,
  });
}
