import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';

class InstrumentOverviewDrawer extends StatefulWidget {
  final String instrumentName;
  final List<Widget> content;
  final VoidCallback? onHide;

  const InstrumentOverviewDrawer({
    super.key,
    required this.instrumentName,
    required this.content,
    this.onHide,
  });

  @override
  State<InstrumentOverviewDrawer> createState() =>
      _InstrumentOverviewDrawerState();
}

class _InstrumentOverviewDrawerState extends State<InstrumentOverviewDrawer>
    with SingleTickerProviderStateMixin {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  double _currentHeightFactor = 0.5;

  final double _minHeightFactor = 0.15;
  final double _maxHeightFactor = 0.90;

  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomedIn = false;

  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    if (_isDesktopOrWeb) {
      _transformationController.addListener(() {
        final isZoomed =
            _transformationController.value.getMaxScaleOnAxis() > 1.05;
        if (isZoomed != _isZoomedIn) {
          setState(() {
            _isZoomedIn = isZoomed;
          });
        }
      });
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!_isDesktopOrWeb) return;

    if (event is PointerScrollEvent) {
      final keys = HardwareKeyboard.instance.logicalKeysPressed;
      final isCtrlPressed = keys.contains(LogicalKeyboardKey.controlLeft) ||
          keys.contains(LogicalKeyboardKey.controlRight) ||
          keys.contains(LogicalKeyboardKey.metaLeft) ||
          keys.contains(LogicalKeyboardKey.metaRight);

      if (isCtrlPressed) {
        final double zoomFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
        final Matrix4 matrix = _transformationController.value;
        final double currentScale = matrix.getMaxScaleOnAxis();

        double targetScale = (currentScale * zoomFactor).clamp(1.0, 4.0);

        if (targetScale <= 1.01) {
          _transformationController.value = Matrix4.identity();
          return;
        }

        double actualZoomFactor = targetScale / currentScale;

        if (actualZoomFactor != 1.0) {
          final Offset focalPoint = event.localPosition;

          final Matrix4 newMatrix = Matrix4.identity()
            ..translateByDouble(focalPoint.dx, focalPoint.dy, 0.0, 1.0)
            ..scaleByDouble(actualZoomFactor, actualZoomFactor, 1.0, 1.0)
            ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0.0, 1.0);

          _transformationController.value = matrix * newMatrix;
        }
      }
    }
  }

  void _onHeaderDragUpdate(DragUpdateDetails details) {
    setState(() {
      double delta = details.primaryDelta! / MediaQuery.of(context).size.height;
      _currentHeightFactor -= delta;
      _currentHeightFactor =
          _currentHeightFactor.clamp(_minHeightFactor, _maxHeightFactor);
    });
  }

  void _onHeaderDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
      _hideDrawer();
    } else if (details.primaryVelocity != null &&
        details.primaryVelocity! < -500) {
      setState(() {
        _currentHeightFactor = _maxHeightFactor;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _hideDrawer() {
    _animationController.reverse().then((_) {
      if (widget.onHide != null) {
        widget.onHide!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _hideDrawer,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: screenHeight * _currentHeightFactor,
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 800),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: guideDrawerBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onVerticalDragUpdate: _onHeaderDragUpdate,
                        onVerticalDragEnd: _onHeaderDragEnd,
                        onTap: () {
                          if (_currentHeightFactor < 0.5) {
                            setState(() {
                              _currentHeightFactor = _maxHeightFactor;
                            });
                          } else {
                            _hideDrawer();
                          }
                        },
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16.0),
                              topRight: Radius.circular(16.0),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _currentHeightFactor >= 0.5
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_up,
                                color: appBarContentColor,
                                size: 24.0,
                              ),
                              Text(
                                _currentHeightFactor >= 0.5
                                    ? appLocalizations.hideGuide
                                    : appLocalizations.showGuide,
                                style: TextStyle(
                                  color: appBarContentColor,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            Widget contentColumn = SizedBox(
                              width: constraints.maxWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.instrumentName,
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: guideDrawerHeadingColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    ...widget.content,
                                    const SizedBox(height: 20.0),
                                  ],
                                ),
                              ),
                            );

                            if (_isDesktopOrWeb) {
                              return Listener(
                                onPointerSignal: _handlePointerSignal,
                                child: InteractiveViewer(
                                  transformationController:
                                      _transformationController,
                                  boundaryMargin: EdgeInsets.zero,
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  scaleEnabled: false,
                                  panEnabled: _isZoomedIn,
                                  child: SingleChildScrollView(
                                    physics: _isZoomedIn
                                        ? const NeverScrollableScrollPhysics()
                                        : null,
                                    child: contentColumn,
                                  ),
                                ),
                              );
                            }

                            return InteractiveViewer(
                              boundaryMargin: EdgeInsets.zero,
                              minScale: 1.0,
                              maxScale: 4.0,
                              constrained: false,
                              child: contentColumn,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InstrumentIntroText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const InstrumentIntroText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Text(
        text,
        style: style ??
            TextStyle(
              fontSize: 15.0,
              color: blackTextColor,
              height: 1.5,
            ),
      ),
    );
  }
}

class InstrumentHeading extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const InstrumentHeading({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: style ??
            TextStyle(
              fontSize: 20.0,
              color: guideDrawerHeadingColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class InstrumentBulletPoint extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const InstrumentBulletPoint({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(
              Icons.circle,
              size: 6.0,
              color: guideDrawerHighlightColor,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: style ??
                  TextStyle(
                    fontSize: 15.0,
                    color: blackTextColor,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class InstrumentImage extends StatelessWidget {
  final String imagePath;
  final String? caption;
  final double? height;
  final BoxFit fit;

  const InstrumentImage({
    super.key,
    required this.imagePath,
    this.caption,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18.0),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: height ?? MediaQuery.of(context).size.height * 0.5,
              maxWidth: double.infinity,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                imagePath,
                fit: fit,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 48.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8.0),
            Text(
              caption!,
              style: TextStyle(
                fontSize: 14.0,
                color: guideDrawerHighlightColor,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
