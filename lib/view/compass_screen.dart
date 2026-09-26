import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/export_helper.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/compass_config_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/compass_provider.dart';
import '../providers/compass_config_provider.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';
import '../constants.dart';

class CompassScreen extends StatelessWidget {
  final List<List<dynamic>>? playbackData;

  const CompassScreen({super.key, this.playbackData});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CompassProvider()),
        ChangeNotifierProvider(create: (_) => CompassConfigProvider()),
      ],
      child: CompassScreenContent(playbackData: playbackData),
    );
  }
}

class CompassScreenContent extends StatefulWidget {
  final List<List<dynamic>>? playbackData;

  const CompassScreenContent({super.key, this.playbackData});

  @override
  State<CompassScreenContent> createState() => _CompassScreenContentState();
}

class _CompassScreenContentState extends State<CompassScreenContent> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  late CompassProvider _provider;
  late CompassConfigProvider _configProvider;

  bool _showGuide = false;
  static const String guideImagePath = 'assets/images/find_mobile_axis.png';

  @override
  void initState() {
    super.initState();
    _provider = context.read<CompassProvider>();
    _configProvider = context.read<CompassConfigProvider>();

    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.playbackData != null) {
          _provider.startPlayback(widget.playbackData!);
        } else {
          _provider.setConfigProvider(_configProvider);
          _provider.initializeSensors();
        }
      }
    });
  }

  @override
  void dispose() {
    _provider.disposeSensors();
    super.dispose();
  }

  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  void _showOptionsMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        0,
        0,
        MediaQuery.of(context).size.height,
      ),
      items: [
        PopupMenuItem(
          value: 'show_logged_data',
          child: Text(appLocalizations.showLoggedData),
        ),
        PopupMenuItem(
          value: 'compass_config',
          child: Text('${appLocalizations.compassTitle} Config'),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'compass_config':
            _navigateToConfig();
            break;
        }
      }
    });
  }

  void _navigateToConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangeNotifierProvider<CompassConfigProvider>.value(
          value: _configProvider,
          child: const CompassConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.compassTitle.toLowerCase()],
          appBarName: appLocalizations.compassTitle,
          instrumentIcons: [instrumentIcons[9]],
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_provider.isRecording) {
      final data = _provider.stopRecording();
      await ExportHelper.handleSaveData(
        context: context,
        instrumentName: appLocalizations.compass.toLowerCase(),
        data: data,
      );
    } else {
      await _provider.startRecording();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appLocalizations.recordingStarted}...',
            style: TextStyle(color: snackBarContentColor),
          ),
          backgroundColor: snackBarBackgroundColor,
        ),
      );
    }
  }

  List<Widget> _getCompassContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.compassGuideBody,
      ),
      const InstrumentImage(
        imagePath: guideImagePath,
        height: 200.0,
      ),
      InstrumentIntroText(
        text: appLocalizations.compassGuideImageCaption,
      ),
      InstrumentCompatibilitySection(
        phoneSupported: true,
        pslabOptionalSensor: true,
        note: appLocalizations.compassCompatNote,
      ),
    ];
  }

  String _getCardinalDirection(double degree) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final normalized = (degree % 360 + 360) % 360;
    final index = ((normalized + 22.5) % 360 ~/ 45);
    return directions[index];
  }

  String _getFullDirectionName(String cardinal) {
    switch (cardinal) {
      case 'N':
        return 'North';
      case 'NE':
        return 'Northeast';
      case 'E':
        return 'East';
      case 'SE':
        return 'Southeast';
      case 'S':
        return 'South';
      case 'SW':
        return 'Southwest';
      case 'W':
        return 'West';
      case 'NW':
        return 'Northwest';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompassProvider>(
      builder: (context, compassProvider, child) {
        final double headingDegrees =
            compassProvider.getDegreeForAxis(compassProvider.selectedAxis);
        final String cardinal = _getCardinalDirection(headingDegrees);
        final String fullDirection = _getFullDirectionName(cardinal);
        final double bx = compassProvider.magnetometerEvent.x;
        final double by = compassProvider.magnetometerEvent.y;
        final double bz = compassProvider.magnetometerEvent.z;
        final double bTotal = sqrt(bx * bx + by * by + bz * bz);
        final double ax = compassProvider.accelerometerEvent.x;
        final double ay = compassProvider.accelerometerEvent.y;
        final double az = compassProvider.accelerometerEvent.z;
        final double pitchDeg = atan2(ay, sqrt(ax * ax + az * az)) * (180 / pi);
        final double rollDeg = atan2(-ax, sqrt(ay * ay + az * az)) * (180 / pi);
        final int maxTilt = max(pitchDeg.abs(), rollDeg.abs()).round();
        final bool isLevel = maxTilt <= 5;

        return Stack(
          children: [
            CommonScaffold(
              title: compassProvider.isPlayingBack
                  ? '${appLocalizations.compassTitle} - ${appLocalizations.playback}'
                  : appLocalizations.compassTitle,
              onGuidePressed: _showInstrumentGuide,
              onOptionsPressed:
                  compassProvider.isPlayingBack ? null : _showOptionsMenu,
              onRecordPressed:
                  compassProvider.isPlayingBack ? null : _toggleRecording,
              isRecording: compassProvider.isRecording,
              isPlayingBack: compassProvider.isPlayingBack,
              isPlaybackPaused: compassProvider.isPlaybackPaused,
              onPlaybackPauseResume: compassProvider.isPlayingBack
                  ? (compassProvider.isPlaybackPaused
                      ? compassProvider.resumePlayback
                      : compassProvider.pausePlayback)
                  : null,
              onPlaybackStop: compassProvider.isPlayingBack
                  ? () async {
                      await compassProvider.stopPlayback();
                    }
                  : null,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double compassSize = min(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ).clamp(170.0, 300.0);

                            return Center(
                              child: Container(
                                width: compassSize,
                                height: compassSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    RepaintBoundary(
                                      child: CustomPaint(
                                        size: Size(compassSize, compassSize),
                                        painter: _StaticBezelPainter(
                                          accentRed: primaryRed,
                                        ),
                                      ),
                                    ),
                                    Transform.rotate(
                                      angle: compassProvider.currentDegree,
                                      child: RepaintBoundary(
                                        child: CustomPaint(
                                          size: Size(compassSize, compassSize),
                                          painter: _StaticDialDiskPainter(
                                            accentRed: primaryRed,
                                          ),
                                        ),
                                      ),
                                    ),
                                    RepaintBoundary(
                                      child: CustomPaint(
                                        size: Size(compassSize, compassSize),
                                        painter: _UprightCenterHubPainter(
                                          headingText:
                                              '${headingDegrees.toStringAsFixed(1)}°',
                                          cardinalText: cardinal,
                                          axisText:
                                              '${compassProvider.selectedAxis}-Axis',
                                          accentRed: primaryRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${headingDegrees.toStringAsFixed(1)}°',
                            style: TextStyle(
                              color: blackTextColor,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: primaryRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryRed.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '$cardinal • $fullDirection',
                              style: TextStyle(
                                color: primaryRed,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildBottomInfoCard(
                        compassProvider: compassProvider,
                        bx: bx,
                        by: by,
                        bz: bz,
                        bTotal: bTotal,
                        maxTilt: maxTilt,
                        isLevel: isLevel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showGuide)
              InstrumentOverviewDrawer(
                instrumentName: appLocalizations.compassGuideTitle,
                content: _getCompassContent(),
                onHide: _hideInstrumentGuide,
              ),
          ],
        );
      },
    );
  }

  Widget _buildBottomInfoCard({
    required CompassProvider compassProvider,
    required double bx,
    required double by,
    required double bz,
    required double bTotal,
    required int maxTilt,
    required bool isLevel,
  }) {
    String fieldStatus = 'Normal Field';
    Color statusColor = const Color(0xFF2E7D32);
    if (bTotal > 75.0) {
      fieldStatus = 'Magnet Nearby';
      statusColor = primaryRed;
    } else if (bTotal < 20.0) {
      fieldStatus = 'Weak Field';
      statusColor = const Color(0xFFEF6C00);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryRed,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildCompactMetricBox('Bx', bx.toStringAsFixed(1), 'µT'),
              const SizedBox(width: 6),
              _buildCompactMetricBox('By', by.toStringAsFixed(1), 'µT'),
              const SizedBox(width: 6),
              _buildCompactMetricBox('Bz', bz.toStringAsFixed(1), 'µT'),
              const SizedBox(width: 6),
              _buildCompactMetricBox(
                'Total',
                bTotal.toStringAsFixed(1),
                'µT',
                isHighlighted: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: primaryRed.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLevel
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFEF6C00),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLevel ? 'Phone Level' : 'Tilted ($maxTilt°)',
                      style: TextStyle(
                        fontSize: 12,
                        color: blackTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: primaryRed.withValues(alpha: 0.2),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      bTotal > 75.0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fieldStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            appLocalizations.parallelToGround,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: blackTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactAxisChip(compassProvider, 'X', 'X Axis'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactAxisChip(compassProvider, 'Y', 'Y Axis'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactAxisChip(compassProvider, 'Z', 'Z Axis'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetricBox(
    String label,
    String value,
    String unit, {
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color:
              isHighlighted ? primaryRed.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isHighlighted ? primaryRed : primaryRed.withValues(alpha: 0.28),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? primaryRed : const Color(0xFF616161),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        color: isHighlighted ? primaryRed : blackTextColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAxisChip(
    CompassProvider compassProvider,
    String axis,
    String label,
  ) {
    final bool isSelected = compassProvider.selectedAxis == axis;
    return GestureDetector(
      onTap: () => compassProvider.onAxisSelected(axis),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryRed : primaryRed.withValues(alpha: 0.35),
            width: 0.9,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isSelected ? Colors.white : blackTextColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StaticBezelPainter extends CustomPainter {
  final Color accentRed;

  const _StaticBezelPainter({required this.accentRed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final bezelRect = Rect.fromCircle(center: center, radius: radius * 0.96);
    final bezelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF0F2F5),
          Color(0xFFE2E6EA),
        ],
      ).createShader(bezelRect);
    canvas.drawCircle(center, radius * 0.96, bezelPaint);

    canvas.drawCircle(
      center,
      radius * 0.96,
      Paint()
        ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final faceRect = Rect.fromCircle(center: center, radius: radius * 0.90);
    final facePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.15),
        radius: 0.95,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFBFBFD),
          Color(0xFFEEF1F5),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(faceRect);
    canvas.drawCircle(center, radius * 0.90, facePaint);

    final rimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.90, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _StaticBezelPainter oldDelegate) => false;
}

class _StaticDialDiskPainter extends CustomPainter {
  final Color accentRed;

  const _StaticDialDiskPainter({required this.accentRed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    _drawTicksAndDegrees(canvas, radius);
    _drawCardinalLabels(canvas, radius);
    _drawCrosshairAndRings(canvas, radius);
    _drawMagneticNeedle(canvas, radius);

    canvas.restore();
  }

  void _drawTicksAndDegrees(Canvas canvas, double radius) {
    final tickOuterRadius = radius * 0.85;

    final majorTickPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final mediumTickPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 0.8;

    final northTickPaint = Paint()
      ..color = accentRed
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int deg = 0; deg < 360; deg += 2) {
      final angle = (deg - 90) * pi / 180;
      final isMajor = deg % 30 == 0;
      final isMedium = deg % 10 == 0;

      double tickLength;
      Paint currentPaint;

      if (deg == 0) {
        tickLength = radius * 0.09;
        currentPaint = northTickPaint;
      } else if (isMajor) {
        tickLength = radius * 0.075;
        currentPaint = majorTickPaint;
      } else if (isMedium) {
        tickLength = radius * 0.05;
        currentPaint = mediumTickPaint;
      } else {
        tickLength = radius * 0.028;
        currentPaint = minorTickPaint;
      }

      final cosA = cos(angle);
      final sinA = sin(angle);

      final p1 = Offset(cosA * tickOuterRadius, sinA * tickOuterRadius);
      final p2 = Offset(
        cosA * (tickOuterRadius - tickLength),
        sinA * (tickOuterRadius - tickLength),
      );

      canvas.drawLine(p1, p2, currentPaint);

      if (isMajor) {
        canvas.save();
        final textRadius = radius * 0.71;
        final textPos = Offset(cosA * textRadius, sinA * textRadius);
        canvas.translate(textPos.dx, textPos.dy);
        canvas.rotate(angle + pi / 2);

        tp.text = TextSpan(
          text: '$deg',
          style: TextStyle(
            color: deg == 0 ? accentRed : const Color(0xFF212121),
            fontSize: radius * 0.065,
            fontWeight: deg == 0 ? FontWeight.bold : FontWeight.w600,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  void _drawCardinalLabels(Canvas canvas, double radius) {
    const cardinals = {
      0: 'N',
      45: 'NE',
      90: 'E',
      135: 'SE',
      180: 'S',
      225: 'SW',
      270: 'W',
      315: 'NW',
    };

    final tp = TextPainter(textDirection: TextDirection.ltr);

    cardinals.forEach((deg, label) {
      final isPrimary = deg % 90 == 0;
      final angle = (deg - 90) * pi / 180;
      final labelRadius = isPrimary ? radius * 0.54 : radius * 0.56;

      canvas.save();
      final pos = Offset(cos(angle) * labelRadius, sin(angle) * labelRadius);
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + pi / 2);

      tp.text = TextSpan(
        text: label,
        style: TextStyle(
          color: deg == 0
              ? accentRed
              : isPrimary
                  ? const Color(0xFF141414)
                  : Colors.black.withValues(alpha: 0.45),
          fontSize: isPrimary ? radius * 0.115 : radius * 0.065,
          fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: 1.0,
        ),
      );

      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    });
  }

  void _drawCrosshairAndRings(Canvas canvas, double radius) {
    final ringPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset.zero, radius * 0.63, ringPaint);
    canvas.drawCircle(Offset.zero, radius * 0.42, ringPaint);

    final crosshairPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(-radius * 0.42, 0),
      Offset(radius * 0.42, 0),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(0, -radius * 0.42),
      Offset(0, radius * 0.42),
      crosshairPaint,
    );
  }

  void _drawMagneticNeedle(Canvas canvas, double radius) {
    final needleLength = radius * 0.62;
    final needleWidth = radius * 0.075;
    final darkerRed = Color.lerp(accentRed, Colors.black, 0.22)!;

    final northLeftPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(-needleWidth, 0)
      ..lineTo(0, 0)
      ..close();

    final northRightPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(needleWidth, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(northLeftPath, Paint()..color = accentRed);
    canvas.drawPath(northRightPath, Paint()..color = darkerRed);

    final southLeftPath = Path()
      ..moveTo(0, needleLength)
      ..lineTo(-needleWidth, 0)
      ..lineTo(0, 0)
      ..close();

    final southRightPath = Path()
      ..moveTo(0, needleLength)
      ..lineTo(needleWidth, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(southLeftPath, Paint()..color = const Color(0xFF333333));
    canvas.drawPath(southRightPath, Paint()..color = const Color(0xFF141414));
  }

  @override
  bool shouldRepaint(covariant _StaticDialDiskPainter oldDelegate) => false;
}

class _UprightCenterHubPainter extends CustomPainter {
  final String headingText;
  final String cardinalText;
  final String axisText;
  final Color accentRed;

  const _UprightCenterHubPainter({
    required this.headingText,
    required this.cardinalText,
    required this.axisText,
    required this.accentRed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final path = Path();
    final topY = center.dy - radius * 0.95;
    path.moveTo(center.dx, topY + radius * 0.085);
    path.lineTo(center.dx - radius * 0.042, topY);
    path.lineTo(center.dx + radius * 0.042, topY);
    path.close();
    canvas.drawPath(path, Paint()..color = accentRed);
    final hubRadius = radius * 0.25;

    canvas.drawCircle(
      center,
      hubRadius * 1.07,
      Paint()..color = const Color(0xFF1E1E1E),
    );

    final hubPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF2F4F7)],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius));
    canvas.drawCircle(center, hubRadius, hubPaint);

    canvas.drawCircle(
      center,
      hubRadius * 0.94,
      Paint()
        ..color = accentRed.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final cardinalPainter = TextPainter(
      text: TextSpan(
        text: cardinalText,
        style: TextStyle(
          color: accentRed,
          fontSize: radius * 0.085,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    cardinalPainter.paint(
      canvas,
      Offset(
          center.dx - cardinalPainter.width / 2, center.dy - hubRadius * 0.68),
    );

    final degreePainter = TextPainter(
      text: TextSpan(
        text: headingText,
        style: TextStyle(
          color: const Color(0xFF141414),
          fontSize: radius * 0.095,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    degreePainter.paint(
      canvas,
      Offset(center.dx - degreePainter.width / 2,
          center.dy - degreePainter.height / 2 + 2),
    );

    final axisPainter = TextPainter(
      text: TextSpan(
        text: axisText,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.55),
          fontSize: radius * 0.055,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    axisPainter.paint(
      canvas,
      Offset(center.dx - axisPainter.width / 2, center.dy + hubRadius * 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _UprightCenterHubPainter oldDelegate) {
    return oldDelegate.headingText != headingText ||
        oldDelegate.cardinalText != cardinalText ||
        oldDelegate.axisText != axisText;
  }
}
