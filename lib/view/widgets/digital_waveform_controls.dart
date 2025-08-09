import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class DigitalWaveformControls extends StatefulWidget {
  const DigitalWaveformControls({super.key});

  @override
  State<StatefulWidget> createState() => _DigitalWaveformControlsState();
}

class _DigitalWaveformControlsState extends State<DigitalWaveformControls> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(width: 3, color: primaryRed),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        appLocalizations.sqr1.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () => {},
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        appLocalizations.sqr2.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () => {},
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        appLocalizations.sqr3.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () => {},
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        appLocalizations.sqr4.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () => {},
                    ),
                  ),
                ],
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 35,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.freq,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {},
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 35,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.phase,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {},
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 35,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          appLocalizations.duty,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: oscilloscopeOptionTitleBoxColor),
              child: Text(
                appLocalizations.digital,
                style: TextStyle(
                  color: oscilloscopeOptionTitleColor,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
