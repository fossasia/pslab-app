import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class AngleInputTopDialog extends StatefulWidget {
  final int index;
  final double initialValue;
  final void Function(double) onValueConfirmed;

  const AngleInputTopDialog({
    super.key,
    required this.index,
    required this.initialValue,
    required this.onValueConfirmed,
  });

  @override
  State<AngleInputTopDialog> createState() => _AngleInputTopDialogState();
}

class _AngleInputTopDialogState extends State<AngleInputTopDialog> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late double currentValue;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
    controller = TextEditingController(text: currentValue.round().toString());
  }

  void updateValue(double newVal) {
    setState(() {
      currentValue = newVal.clamp(0, 360);
      controller.text = currentValue.round().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenWidth * 0.4,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: primaryRed, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${appLocalizations.setAngle} ${widget.index + 1}',
                style: TextStyle(
                  color: primaryRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => updateValue(
                        (double.tryParse(controller.text) ?? 0) - 1),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          setState(() {
                            currentValue = parsed.clamp(0, 360);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => updateValue(
                        (double.tryParse(controller.text) ?? 0) + 1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [0, 45, 90, 135, 180, 270, 360].map((val) {
                  return OutlinedButton(
                    onPressed: () => updateValue(val.floorToDouble()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '$val${appLocalizations.degreeSymbol}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 11),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(appLocalizations.cancel),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {
                      final value = double.tryParse(controller.text);
                      if (value != null && value >= 0 && value <= 360) {
                        widget.onValueConfirmed(value.floorToDouble());
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(appLocalizations.enterAngleRange)),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 11),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(appLocalizations.ok),
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
