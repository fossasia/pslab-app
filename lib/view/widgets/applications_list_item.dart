import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class ApplicationsListItem extends StatelessWidget {
  final String heading;
  final String description;
  final String instrumentIcon;
  static const String verticalBarsIcon =
      'assets/icons/tile_icon_vertical_bars.png';
  static const String horizontalBarsIcon =
      'assets/icons/tile_icon_horizontal_bars.png';

  static const double _kBaselineWidth = 450.0;
  static const double _kBaselineHeight = 200.0;
  static const double _kFallbackHeight = 225.0;

  const ApplicationsListItem({
    super.key,
    required this.heading,
    required this.description,
    required this.instrumentIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 2,
      color: primaryRed,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _kBaselineWidth;

          final double widthScale = w / _kBaselineWidth;
          final double tileHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : _kFallbackHeight;
          final double heightScale = tileHeight / _kBaselineHeight;
          final double scale =
              (widthScale < heightScale ? widthScale : heightScale)
                  .clamp(0.5, 1.0)
                  .toDouble();

          final double pad = 20 * scale;
          final double inset = 10 * scale;
          final double headingSize = 22 * scale;
          final double descSize = 16 * scale;

          final double widthCap = (w * 0.32).clamp(0.0, double.infinity);
          final double heightCap =
              ((tileHeight - inset * 2) * 0.5).clamp(0.0, double.infinity);
          final double icon =
              (100 * scale).clamp(0.0, widthCap).clamp(0.0, heightCap);

          return SizedBox(
            height: tileHeight,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: 0,
                  bottom: inset,
                  right: inset,
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          verticalBarsIcon,
                          width: icon,
                          fit: BoxFit.fill,
                          color: instrumentCardContentColor,
                        ),
                      ),
                      SizedBox(height: icon, width: icon),
                    ],
                  ),
                ),
                Positioned(
                  right: inset,
                  bottom: inset,
                  left: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: Image.asset(
                          horizontalBarsIcon,
                          height: icon,
                          fit: BoxFit.fill,
                          color: instrumentCardContentColor,
                        ),
                      ),
                      SizedBox(
                        height: icon,
                        width: icon,
                        child: Image.asset(
                          instrumentIcon,
                          fit: BoxFit.fill,
                          color: instrumentCardContentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: pad,
                  left: pad,
                  right: icon,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          heading,
                          style: TextStyle(
                            fontSize: headingSize,
                            fontWeight: FontWeight.bold,
                            color: instrumentCardContentColor,
                          ),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: descSize,
                          color: instrumentCardContentColor,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.start,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
