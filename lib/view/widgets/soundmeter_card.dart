import 'dart:math';
import 'package:pslab/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:pslab/providers/soundmeter_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/instruments_stats.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

import '../../others/sound_classification.dart';
import 'gauge_widget.dart';

class SoundMeterCard extends StatefulWidget {
  const SoundMeterCard({super.key});
  @override
  State<StatefulWidget> createState() => _SoundMeterCardState();
}

class _SoundMeterCardState extends State<SoundMeterCard> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  bool _showClassification = false;

  void _toggleTopPanel() {
    setState(() {
      _showClassification = !_showClassification;
    });
  }

  Widget _buildFlipTransition(Widget child, Animation<double> animation) {
    final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);

    return AnimatedBuilder(
      animation: rotateAnim,
      child: child,
      builder: (context, widget) {
        final isUnder = (ValueKey(_showClassification) != widget?.key);
        var tilt = ((animation.value * 0.5).abs() - 0.5) * 0.003;
        tilt *= isUnder ? -1.0 : 1.0;
        final value =
            isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;

        return Transform(
          transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
          alignment: Alignment.center,
          child: widget,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    SoundMeterStateProvider provider =
        Provider.of<SoundMeterStateProvider>(context);

    final cardMargin = screenWidth < 400 ? 8.0 : 12.0;
    final cardPadding = screenWidth < 400 ? 12.0 : 20.0;
    final gaugeSize = isLargeScreen ? 260.0 : screenWidth * 0.55;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 20.0 : 15.0;

    return Card(
      margin: EdgeInsets.all(cardMargin),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(cardPadding),
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: _buildFlipTransition,
              layoutBuilder: (widget, list) =>
                  Stack(children: [widget!, ...list]),
              child: _showClassification
                  ? _buildClassificationList(
                      key: const ValueKey(true), provider: provider)
                  : _buildGaugePanel(
                      key: const ValueKey(false),
                      provider: provider,
                      gaugeSize: gaugeSize,
                      titleFontSize: titleFontSize,
                      statFontSize: statFontSize,
                    ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.swipe,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: _toggleTopPanel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugePanel({
    required Key key,
    required SoundMeterStateProvider provider,
    required double gaugeSize,
    required double titleFontSize,
    required double statFontSize,
  }) {
    return Column(
      key: key,
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: InstrumentGauge(
                size: gaugeSize,
                currentValue: provider.getCurrentDb(),
                minValue: 0,
                maxValue: 200,
                interval: 20,
                unit: appLocalizations.db,
                decimalPlaces: 1,
              ),
            ),
          ),
        ),
        Instrumentstats(
          titleFontSize: titleFontSize,
          statFontSize: statFontSize,
          maxValue: provider.getMaxDb(),
          minValue: provider.getMinDb(),
          avgValue: provider.getAverageDb(),
          unit: appLocalizations.db,
        ),
      ],
    );
  }

  Widget _buildClassificationList({
    required Key key,
    required SoundMeterStateProvider provider,
  }) {
    final activeEvents = provider.activeEvents;

    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations.analysis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Theme.of(context).textTheme.bodySmall?.color ??
                  Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: activeEvents.isEmpty ||
                    (activeEvents.length == 1 &&
                        activeEvents.first.label == "Silence")
                ? _buildEmptyState()
                : ListView(
                    padding: EdgeInsets.zero,
                    children: activeEvents
                        .map((e) => Padding(
                              // Tightened the spacing between items from 24 to 16
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildListItem(e),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(ActiveSoundEvent event) {
    final percent = (event.confidence * 100).toInt();
    final fraction = event.confidence.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                event.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "$percent%",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 10,
              width: constraints.maxWidth * fraction,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF29B6F6),
                    const Color(0xFF29B6F6).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        appLocalizations.waitingAudio,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
          fontSize: 15,
        ),
      ),
    );
  }
}
