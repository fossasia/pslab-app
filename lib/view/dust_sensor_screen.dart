import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/dust_sensor_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/theme/colors.dart';

import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/providers/locator.dart';

class DustSensorScreen extends StatefulWidget {
  const DustSensorScreen({super.key});

  @override
  State<DustSensorScreen> createState() => _DustSensorScreenState();
}

class _DustSensorScreenState extends State<DustSensorScreen> {
  bool _showGuide = false;
  ScienceLab? _scienceLab;

  void _showInstrumentGuide() => setState(() => _showGuide = true);
  void _hideInstrumentGuide() => setState(() => _showGuide = false);

  bool _isDeviceConnected() {
    try {
      _scienceLab ??= getIt.get<ScienceLab>();
      return _scienceLab != null && _scienceLab!.isConnected();
    } catch (_) {
      return false;
    }
  }

  String _airQualityLabel(double? ppm) {
    if (ppm == null) return "--";
    if (ppm < 1.0) return "Good";
    if (ppm < 2.5) return "Moderate";
    if (ppm < 4.0) return "Poor";
    return "Hazardous";
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (_) => DustSensorStateProvider(),
      child: Consumer<DustSensorStateProvider>(
        builder: (context, provider, _) {
          final connected = _isDeviceConnected();

          // Perfect PR behavior:
          // - No fake data when not connected
          // - Stop/clear anything if user disconnects
          if (!connected && provider.isStreaming) {
            provider.stop();
            provider.clearGraph();
          }

          // Safe nullable handling
          final double? ppm = connected ? provider.ppm : null;

          final String ppmText = ppm == null ? "--" : ppm.toStringAsFixed(2);
          final String airQuality = _airQualityLabel(ppm);

          return Stack(
            children: [
              CommonScaffold(
                title: loc.dustSensor,
                onGuidePressed: _showInstrumentGuide,
                onOptionsPressed: () {
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      MediaQuery.of(context).size.width,
                      0,
                      0,
                      MediaQuery.of(context).size.height,
                    ),
                    items: [
                      const PopupMenuItem(
                        value: 'clear',
                        child: Text("Clear graph"),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        enabled: connected,
                        child: Text(provider.isStreaming ? "Stop" : "Start"),
                      ),
                    ],
                  ).then((value) {
                    if (value == null) return;

                    if (value == 'clear') {
                      provider.clearGraph();
                    }

                    if (value == 'toggle' && connected) {
                      provider.isStreaming ? provider.stop() : provider.start();
                    }
                  });
                },
                onRecordPressed: null, // Can be added later like Barometer
                isRecording: false,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Top section (Java-like)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 45,
                              child: Column(
                                children: [
                                  _InfoBox(
                                    title: "Particles (PPM)",
                                    value: ppmText,
                                  ),
                                  const SizedBox(height: 12),
                                  _InfoBox(
                                    title: "Air Quality",
                                    value: airQuality,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 55,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: _DustGauge(
                                  value: ppm ?? 0.0,
                                  min: 0,
                                  max: 5,
                                  displayText: ppm == null
                                      ? "-- PPM"
                                      : "${ppm.toStringAsFixed(2)} PPM",
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Chart section
                        Expanded(
                          child: Card(
                            elevation: 0,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              color: chartBackgroundColor,
                              child: (!connected || provider.spots.isEmpty)
                                  ? Center(
                                      child: Text(
                                        "No chart data available.",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: chartTextColor),
                                      ),
                                    )
                                  : LineChart(
                                      LineChartData(
                                        backgroundColor: chartBackgroundColor,
                                        minX: provider.spots.first.x,
                                        maxX: provider.spots.last.x,
                                        minY: 0,
                                        maxY: 5.5,
                                        gridData: const FlGridData(show: true),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(
                                            color: chartBorderColor,
                                          ),
                                        ),
                                        titlesData: FlTitlesData(
                                          topTitles: AxisTitles(
                                            axisNameWidget: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16),
                                              child: Text(
                                                loc.timeAxisLabel,
                                                style: TextStyle(
                                                  color: chartTextColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            axisNameSize: 22,
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 28,
                                              interval: 10,
                                              getTitlesWidget: (value, meta) =>
                                                  SideTitleWidget(
                                                meta: meta,
                                                child: Text(
                                                  value.toInt().toString(),
                                                  style: TextStyle(
                                                    color: chartTextColor,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            axisNameWidget: Text(
                                              "PPM",
                                              style: TextStyle(
                                                color: chartTextColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 32,
                                              interval: 1,
                                              getTitlesWidget: (value, meta) =>
                                                  SideTitleWidget(
                                                meta: meta,
                                                child: Text(
                                                  value.toStringAsFixed(0),
                                                  style: TextStyle(
                                                    color: chartTextColor,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: provider.spots,
                                            isCurved: true,
                                            color: xOrientationChartLineColor,
                                            barWidth: 2,
                                            dotData:
                                                const FlDotData(show: false),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          "⚠️ Connect PSLab device to start measuring.",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Simple guide overlay (kept minimal for PR)
              if (_showGuide)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _hideInstrumentGuide,
                    child: Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: Card(
                        margin: const EdgeInsets.all(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            loc.dustSensorDesc,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _InfoBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.titleMedium),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: t.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DustGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String displayText;

  const _DustGauge({
    required this.value,
    required this.min,
    required this.max,
    required this.displayText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GaugePainter(
        value: value,
        min: min,
        max: max,
        textStyle: Theme.of(context).textTheme.titleMedium ??
            const TextStyle(fontSize: 14),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 65),
          child: Text(
            displayText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final TextStyle textStyle;

  _GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final bgPaint = Paint()
      ..color = Colors.lightBlue.withAlpha(230)
      ..style = PaintingStyle.fill;

    final rimPaint = Paint()
      ..color = Colors.lightBlue.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;

    canvas.drawCircle(center, radius * 0.92, bgPaint);
    canvas.drawCircle(center, radius * 0.92, rimPaint);

    final tickPaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..strokeWidth = radius * 0.02
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepAngle * i / 10);
      final p1 = Offset(
        center.dx + math.cos(angle) * radius * 0.72,
        center.dy + math.sin(angle) * radius * 0.72,
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * radius * 0.82,
        center.dy + math.sin(angle) * radius * 0.82,
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = radius * 0.05
      ..strokeCap = StrokeCap.round;

    final clamped = value.clamp(min, max);
    final ratio = (clamped - min) / (max - min);
    final needleAngle = startAngle + sweepAngle * ratio;

    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * radius * 0.55,
      center.dy + math.sin(needleAngle) * radius * 0.55,
    );

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(
      center,
      radius * 0.06,
      Paint()..color = Colors.white.withAlpha(230),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max;
  }
}
