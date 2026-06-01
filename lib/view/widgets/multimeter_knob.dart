import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/multimeter_state_provider.dart';
import 'package:pslab/theme/colors.dart';

class InnerDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 105.r;

    final paint = Paint()
      ..color = multimeterBorderBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class InnerDialFillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 105.r;

    final fillPaint = Paint()
      ..color = innerDialFillColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class InnerPointerPainter extends CustomPainter {
  final double value;
  final double max;
  final Color color;

  InnerPointerPainter({
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 105.r;

    final pointerAngle = -pi / 2 + (2 * pi * (value / max));

    final pointerPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 30;

    final pointerStart = Offset(
      center.dx - radius * cos(pointerAngle),
      center.dy - radius * sin(pointerAngle),
    );
    final pointerEnd = Offset(
      center.dx + radius * cos(pointerAngle),
      center.dy + radius * sin(pointerAngle),
    );

    final pointerPaintInner = Paint()
      ..color = innerPointerColor
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 10;
    final pointerStartInner = Offset(
      center.dx + radius * 1.0 * cos(pointerAngle),
      center.dy + radius * 1.0 * sin(pointerAngle),
    );
    final pointerEndInner = Offset(
      center.dx + radius * 0.77 * cos(pointerAngle),
      center.dy + radius * 0.77 * sin(pointerAngle),
    );
    canvas.drawLine(pointerStart, pointerEnd, pointerPaint);
    canvas.drawLine(pointerStartInner, pointerEndInner, pointerPaintInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class RadialLabelPainter extends CustomPainter {
  final List<String> labels;
  final List<Color> labelColors;
  final double radius;
  final int selectedIndex;
  final TextStyle baseTextStyle;
  final double arcRadiusOffset;
  final double arcLength;
  final double arcStrokeWidth;

  RadialLabelPainter({
    required this.labels,
    required this.labelColors,
    required this.radius,
    this.selectedIndex = -1,
    this.baseTextStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
    this.arcRadiusOffset = 0,
    this.arcLength = pi / 18,
    this.arcStrokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleIncrement = 2 * pi / labels.length;
    final baseFontSize = baseTextStyle.fontSize ?? 16;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < labels.length; i++) {
      final angle = i * angleIncrement - pi / 2;
      final color = labelColors[i];
      final isSelected = i == selectedIndex;

      final textOffset = Offset(
        center.dx + (radius + 20) * cos(angle),
        center.dy + (radius + 20) * sin(angle),
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: baseTextStyle.copyWith(
          color: color,
          fontSize: isSelected ? baseFontSize * 1.1 : baseFontSize,
        ),
      );
      textPainter.layout();

      final offsetCentered = Offset(
        textOffset.dx - textPainter.width / 2,
        textOffset.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offsetCentered);

      final arcPaint = Paint()
        ..color = color
        ..strokeWidth = isSelected ? arcStrokeWidth * 1.4 : arcStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final arcSpan = isSelected ? arcLength * 1.5 : arcLength;
      final arcRadius = radius + arcRadiusOffset;
      final arcStartAngle = angle - arcSpan / 2;
      final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
      canvas.drawArc(arcRect, arcStartAngle, arcSpan, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadialLabelPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex;
}

class _AdjustModeIntent extends Intent {
  const _AdjustModeIntent(this.direction);

  final int direction;
}

class MultimeterKnob extends StatefulWidget {
  const MultimeterKnob({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MultimeterKnobState createState() => _MultimeterKnobState();
}

class _MultimeterKnobState extends State<MultimeterKnob> {
  static const int modeCount = 11;
  final double maxValue = modeCount.toDouble();

  static const double _plateDiameter = 300.0;

  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  late List<String> knobMarker;

  final FocusNode _knobFocusNode = FocusNode();
  bool _isDragging = false;
  double _pointerTarget = 0.0;

  bool get _isDesktopOrWeb =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    knobMarker = [
      appLocalizations.knobMarkerCh1,
      appLocalizations.knobMarkerCap,
      appLocalizations.knobMarkerVol,
      appLocalizations.knobMarkerRes,
      appLocalizations.knobMarkerCap,
      appLocalizations.knobMarkerLa1,
      appLocalizations.knobMarkerLa2,
      appLocalizations.knobMarkerLa3,
      appLocalizations.knobMarkerLa4,
      appLocalizations.knobMarkerCh3,
      appLocalizations.knobMarkerCh2,
    ];
  }

  @override
  void dispose() {
    _knobFocusNode.dispose();
    super.dispose();
  }

  void _changeMode(int direction) {
    final provider = context.read<MultimeterStateProvider>();
    final nextIndex =
        (provider.getSelectedIndex() + direction + modeCount) % modeCount;
    provider.setSelectedIndex(nextIndex);
  }

  double _nearestEquivalent(double current, int index) {
    final turns = ((current - index) / modeCount).roundToDouble();
    return index + turns * modeCount;
  }

  void _selectFromGlobal(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);
    _updateAngle(localPosition, renderBox.size);
  }

  void _updateAngle(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distanceFromCenter = sqrt(dx * dx + dy * dy);

    if (distanceFromCenter > (_plateDiameter / 2).r) return;

    var angle = atan2(dy, dx);
    if (angle < 0) {
      angle += 2 * pi;
    }

    const startAngle = -pi / 2;
    const totalAngle = 2 * pi;
    final angleNormalized = (angle - startAngle + totalAngle) % totalAngle;
    final anglePerSection = totalAngle / modeCount;
    final section =
        (angleNormalized / anglePerSection).round().clamp(0, modeCount - 1);

    context.read<MultimeterStateProvider>().setSelectedIndex(section);
  }

  void _setDragging(bool value) {
    if (_isDragging == value) return;
    setState(() => _isDragging = value);
  }

  Widget _buildDial() {
    return GestureDetector(
      onTapDown: (details) {
        _knobFocusNode.requestFocus();
        _selectFromGlobal(details.globalPosition);
      },
      onPanStart: (_) => _setDragging(true),
      onPanUpdate: (details) => _selectFromGlobal(details.globalPosition),
      onPanEnd: (_) => _setDragging(false),
      onPanCancel: () => _setDragging(false),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: InnerDialFillPainter(),
            child: SizedBox(
              width: 300.w,
              height: 300.h,
            ),
          ),
          Selector<MultimeterStateProvider, int>(
            selector: (_, provider) => provider.getSelectedIndex(),
            builder: (_, selectedIndex, __) {
              _pointerTarget =
                  _nearestEquivalent(_pointerTarget, selectedIndex);
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _pointerTarget),
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => CustomPaint(
                  painter: InnerPointerPainter(
                    value: value,
                    max: maxValue,
                    color: pointerColor,
                  ),
                  child: SizedBox(
                    width: 300.w,
                    height: 300.h,
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            ignoring: true,
            child: CustomPaint(
              painter: InnerDialPainter(),
              child: SizedBox(
                height: 300.h,
                width: 300.w,
              ),
            ),
          ),
          IgnorePointer(
            ignoring: true,
            child: Selector<MultimeterStateProvider, int>(
              selector: (_, provider) => provider.getSelectedIndex(),
              builder: (_, selectedIndex, __) => CustomPaint(
                painter: RadialLabelPainter(
                  labels: knobMarker,
                  labelColors: knobLabelColors,
                  radius: 112.r,
                  selectedIndex: selectedIndex,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopOrWeb) return _buildDial();

    return Selector<MultimeterStateProvider, int>(
      selector: (_, provider) => provider.getSelectedIndex(),
      builder: (context, selectedIndex, child) => Semantics(
        container: true,
        value: knobMarker[selectedIndex],
        increasedValue: knobMarker[(selectedIndex + 1) % knobMarker.length],
        decreasedValue: knobMarker[
            (selectedIndex - 1 + knobMarker.length) % knobMarker.length],
        onIncrease: () => _changeMode(1),
        onDecrease: () => _changeMode(-1),
        child: child,
      ),
      child: FocusableActionDetector(
        mouseCursor:
            _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowUp): _AdjustModeIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustModeIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _AdjustModeIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustModeIntent(-1),
        },
        actions: <Type, Action<Intent>>{
          _AdjustModeIntent: CallbackAction<_AdjustModeIntent>(
            onInvoke: (intent) {
              _changeMode(intent.direction);
              return null;
            },
          ),
        },
        focusNode: _knobFocusNode,
        autofocus: true,
        child: _buildDial(),
      ),
    );
  }
}
