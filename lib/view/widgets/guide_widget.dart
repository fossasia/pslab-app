import 'package:flutter/material.dart';
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
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null) {
      if (details.primaryVelocity! > 300) {
        _hideDrawer();
      } else if (details.primaryVelocity! < -300) {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    return Material(
      color: guideDrawerHighlightColor,
      child: GestureDetector(
        onVerticalDragEnd: _onVerticalDragEnd,
        onTap: _hideDrawer,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                onVerticalDragEnd: _onVerticalDragEnd,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    minHeight: 200.0,
                  ),
                  decoration: BoxDecoration(
                    color: guideDrawerBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: primaryRed,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16.0),
                            topRight: Radius.circular(16.0),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: _hideDrawer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 2.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: appBarContentColor,
                                  size: 16.0,
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  appLocalizations.hideGuide,
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
                      ),
                      Flexible(
                        child: LayoutBuilder(builder: (context, constraints) {
                          return SingleChildScrollView(
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
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InstrumentIntroText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const InstrumentIntroText({
    super.key,
    required this.text,
    this.style,
  });
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
  const InstrumentHeading({
    super.key,
    required this.text,
    this.style,
  });
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
  const InstrumentBulletPoint({
    super.key,
    required this.text,
    this.style,
  });
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
          SizedBox(
            height: height ?? 200.0,
            width: double.infinity,
            child: ClipRRect(
              child: Image.asset(
                imagePath,
                fit: fit,
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
