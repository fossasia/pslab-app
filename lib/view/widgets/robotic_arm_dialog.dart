import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locator.dart';

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
  late double currentValue;
  late TextEditingController controller;
  late FocusNode _focusNode;
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
    controller = TextEditingController(text: currentValue.round().toString());
    _focusNode = FocusNode();
  }

  void updateValue(double newVal) {
    setState(() {
      currentValue = newVal.clamp(0, 360);
      controller.text = currentValue.round().toString();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top),
        child: Material(
          elevation: 4,
          child: Container(
            width: screenWidth * 0.40,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black54, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      padding: EdgeInsets.zero,
                      onPressed: () => updateValue(
                          (double.tryParse(controller.text) ?? 0) - 1),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 10),
                        decoration: InputDecoration(
                          labelText: 'Servo${widget.index + 1}',
                          labelStyle:
                              const TextStyle(fontSize: 8, color: Colors.black),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 12),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.black87, width: 1.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
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
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      onPressed: () => updateValue(
                          (double.tryParse(controller.text) ?? 0) + 1),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _angleButton(0),
                    _angleButton(90),
                    _angleButton(135),
                    _angleButton(180),
                    _angleButton(270),
                    _angleButton(360),
                  ],
                ),
                SizedBox(height: screenHeight * 0.020),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: Colors.black26),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      child: Text(appLocalizations.cancel),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        final value = double.tryParse(controller.text);
                        if (value != null && value >= 0 && value <= 360) {
                          widget.onValueConfirmed(value.floorToDouble());
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(appLocalizations.enterAngleRange)),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black26),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 11, color: Colors.black26),
                      ),
                      child: Text(appLocalizations.ok),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _angleButton(int angle) {
    return TextButton(
      onPressed: () => updateValue(angle.toDouble()),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        '$angle°',
        style: const TextStyle(
          fontSize: 9,
          color: Colors.black,
        ),
      ),
    );
  }
}
