import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class ApplicationsListItem extends StatelessWidget {
  final String heading;
  final String description;
  final String instrumentIcon;
  final String verticalBarsIcon = 'assets/icons/tile_icon_vertical_bars.png';
  final String horizontalBarsIcon =
      'assets/icons/tile_icon_horizontal_bars.png';

  const ApplicationsListItem(
      {super.key,
      required this.heading,
      required this.description,
      required this.instrumentIcon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 2,
      child: Container(
        height: 225,
        decoration: BoxDecoration(
            color: primaryRed, borderRadius: BorderRadius.circular(5)),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 10,
              right: 10,
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      verticalBarsIcon,
                      width: 100,
                      fit: BoxFit.fill,
                      color: instrumentCardContentColor,
                    ),
                  ),
                  const SizedBox(
                    height: 100,
                    width: 100,
                  )
                ],
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              left: 0,
              child: Row(
                children: [
                  Expanded(
                    child: Image.asset(
                      horizontalBarsIcon,
                      height: 100,
                      fit: BoxFit.fill,
                      color: instrumentCardContentColor,
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Image.asset(
                      instrumentIcon,
                      fit: BoxFit.fill,
                      color: instrumentCardContentColor,
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: instrumentCardContentColor,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: instrumentCardContentColor,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
