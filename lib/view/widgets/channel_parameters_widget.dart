import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/oscilloscope_state_provider.dart';
import 'package:pslab/others/logger_service.dart';
import '../../others/permissions.dart';
import '../../theme/colors.dart';

class ChannelParametersWidget extends StatefulWidget {
  const ChannelParametersWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ChannelParametersState();
}

class _ChannelParametersState extends State<ChannelParametersWidget> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  late List<String> yAxisRanges;

  @override
  void initState() {
    super.initState();
    yAxisRanges = [
      appLocalizations.yAxisRange16V,
      appLocalizations.yAxisRange8V,
      appLocalizations.yAxisRange4V,
      appLocalizations.yAxisRange3V,
      appLocalizations.yAxisRange2V,
      appLocalizations.yAxisRange1_5V,
      appLocalizations.yAxisRange1V,
      appLocalizations.yAxisRange500mV,
      appLocalizations.yAxisRange160V,
    ];
  }

  Widget _buildChannelRow(
      String title, bool isSelected, Function(bool?) onChanged,
      [String? staticRange]) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              activeColor: checkBoxActiveColor,
              value: isSelected,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            staticRange != null && staticRange.isNotEmpty
                ? '$title ($staticRange)'
                : title,
            style: TextStyle(
              color: oscilloscopeOptionLabelColor,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicRadio(
      String title, bool isSelected, Function(bool?) onChanged) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 0.9,
            child: RadioGroup<bool>(
              groupValue: isSelected,
              onChanged: onChanged,
              child: Radio<bool>(
                activeColor: radioButtonActiveColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -4),
                value: true,
                toggleable: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              color: oscilloscopeOptionLabelColor,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    OscilloscopeStateProvider oscilloscopeStateProvider =
        Provider.of<OscilloscopeStateProvider>(context, listen: false);

    String currentGlobalRange =
        yAxisRanges[oscilloscopeStateProvider.oscillscopeRangeSelection];

    return Stack(
      children: [
        Container(
          height: 90,
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8, bottom: 5),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: primaryRed),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 8,
                child: _buildChannelRow(
                  appLocalizations.ch1,
                  oscilloscopeStateProvider.isCH1Selected,
                  (value) => setState(() => oscilloscopeStateProvider
                      .setChannelSelected('CH1', value ?? false)),
                  '+/- 16V',
                ),
              ),
              Positioned(
                bottom: 4,
                left: 8,
                child: _buildChannelRow(
                  appLocalizations.ch2,
                  oscilloscopeStateProvider.isCH2Selected,
                  (value) => setState(() => oscilloscopeStateProvider
                      .setChannelSelected('CH2', value ?? false)),
                  '+/- 16V',
                ),
              ),
              Positioned(
                top: 4,
                left: 165,
                child: _buildChannelRow(
                  "CH3",
                  oscilloscopeStateProvider.isCH3Selected,
                  (value) => setState(() => oscilloscopeStateProvider
                      .setChannelSelected('CH3', value ?? false)),
                  '+/- 3.3V',
                ),
              ),
              Positioned(
                bottom: 4,
                left: 168,
                child: SizedBox(
                  height: 36,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        appLocalizations.rangeScale,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: DropdownMenu<String>(
                          width: 135,
                          initialSelection: currentGlobalRange,
                          dropdownMenuEntries: yAxisRanges.map((String value) {
                            return DropdownMenuEntry<String>(
                              label: value,
                              value: value,
                            );
                          }).toList(),
                          inputDecorationTheme: const InputDecorationTheme(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textStyle: TextStyle(
                            color: oscilloscopeOptionLabelColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (String? value) {
                            if (value == null) return;
                            int index = yAxisRanges.indexOf(value);
                            setState(() {
                              oscilloscopeStateProvider
                                  .oscillscopeRangeSelection = index;
                              switch (index) {
                                case 0:
                                  oscilloscopeStateProvider.setYAxisScale(16);
                                  break;
                                case 1:
                                  oscilloscopeStateProvider.setYAxisScale(8);
                                  break;
                                case 2:
                                  oscilloscopeStateProvider.setYAxisScale(4);
                                  break;
                                case 3:
                                  oscilloscopeStateProvider.setYAxisScale(3);
                                  break;
                                case 4:
                                  oscilloscopeStateProvider.setYAxisScale(2);
                                  break;
                                case 5:
                                  oscilloscopeStateProvider.setYAxisScale(1.5);
                                  break;
                                case 6:
                                  oscilloscopeStateProvider.setYAxisScale(1);
                                  break;
                                case 7:
                                  oscilloscopeStateProvider.setYAxisScale(0.5);
                                  break;
                                case 8:
                                  oscilloscopeStateProvider.setYAxisScale(160);
                                  break;
                                default:
                                  oscilloscopeStateProvider.setYAxisScale(16);
                                  break;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                bottom: 4,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMicRadio(
                      appLocalizations.builtinMic,
                      oscilloscopeStateProvider.isBuiltInMICSelected,
                      (value) async {
                        if (value == true) {
                          final AppPermissionStatus status =
                              await PSLabPermissions.request(
                                  AppPermission.microphone);
                          if (status != AppPermissionStatus.granted) {
                            logger.e("Microphone permission was denied.");
                            return;
                          }
                        }
                        setState(() {
                          if (value == null || !value) {
                            oscilloscopeStateProvider.isBuiltInMICSelected =
                                false;
                            oscilloscopeStateProvider.isAudioInputSelected =
                                false;
                            oscilloscopeStateProvider.setTimebaseDivisions(8);
                            oscilloscopeStateProvider.removeChannelData('MIC');
                          } else {
                            oscilloscopeStateProvider.setTimebaseDivisions(6);
                            oscilloscopeStateProvider.isAudioInputSelected =
                                true;
                            oscilloscopeStateProvider.isBuiltInMICSelected =
                                true;
                            oscilloscopeStateProvider.isMICSelected = false;
                          }
                        });
                      },
                    ),
                    _buildMicRadio(
                      appLocalizations.pslabMic,
                      oscilloscopeStateProvider.isMICSelected,
                      (value) {
                        setState(() {
                          if (value == null || !value) {
                            oscilloscopeStateProvider.isMICSelected = false;
                            oscilloscopeStateProvider.isAudioInputSelected =
                                false;
                            oscilloscopeStateProvider.removeChannelData('MIC');
                          } else {
                            oscilloscopeStateProvider.isAudioInputSelected =
                                true;
                            oscilloscopeStateProvider.isMICSelected = true;
                            oscilloscopeStateProvider.isBuiltInMICSelected =
                                false;
                          }
                        });
                      },
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
          top: 1,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: oscilloscopeOptionTitleBoxColor),
              child: Text(
                appLocalizations.channels,
                style: TextStyle(
                  color: oscilloscopeOptionTitleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
