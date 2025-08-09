import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class AnalogWaveformControls extends StatefulWidget {
  const AnalogWaveformControls({super.key});

  @override
  State<StatefulWidget> createState() => _AnalogWaveformControlsState();
}

class _AnalogWaveformControlsState extends State<AnalogWaveformControls> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  String iconSin = "assets/icons/ic_sin.png";
  String iconTriangular = "assets/icons/ic_triangular.png";
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
                        appLocalizations.wave1,
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
                        appLocalizations.wave2,
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
                      flex: 15,
                      child: IconButton(
                        style: TextButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: Image.asset(
                          iconSin,
                          color: Colors.white,
                        ),
                        onPressed: () => {},
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 15,
                      child: IconButton(
                        style: TextButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: Image.asset(
                          iconTriangular,
                          color: Colors.white,
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
                appLocalizations.analog,
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
