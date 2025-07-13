import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/colors.dart';

class NavDrawer extends StatefulWidget {
  final int selectedIndex;

  const NavDrawer({super.key, required this.selectedIndex});

  @override
  State<StatefulWidget> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final String navHeaderLogo = 'assets/icons/ic_nav_header_logo.png';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).orientation == Orientation.portrait
          ? MediaQuery.of(context).size.width * 0.75
          : MediaQuery.of(context).size.width * 0.45,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior(),
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Image.asset(navHeaderLogo,
                        fit: BoxFit.contain,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Consumer<BoardStateProvider>(
                    builder: (context, provider, _) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          provider.pslabVersionID,
                          style: const TextStyle(
                              fontSize: 14, fontStyle: FontStyle.normal),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.apps,
                color:
                    widget.selectedIndex == 0 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.instrumentsTitle,
                style: TextStyle(
                  color: widget.selectedIndex == 0
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                // Check if the HomeScreen is already in the navigation stack
                if (Navigator.canPop(context) &&
                    ModalRoute.of(context)?.settings.name == '/') {
                  // If it's already in the stack, pop to it
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                } else {
                  // Otherwise, navigate to HomeScreen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => route.isFirst,
                  );
                }
              },
            ),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.wifi_tethering,
                color:
                    widget.selectedIndex == 1 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.loggedDataMenu,
                style: TextStyle(
                  color: widget.selectedIndex == 1
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            const Divider(),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.developer_board,
                color:
                    widget.selectedIndex == 2 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.connectDevice,
                style: TextStyle(
                  color: widget.selectedIndex == 2
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                if (Navigator.canPop(context) &&
                    ModalRoute.of(context)?.settings.name == '/connectDevice') {
                  Navigator.popUntil(
                      context, ModalRoute.withName('/connectDevice'));
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/connectDevice',
                    (route) => route.isFirst,
                  );
                }
              },
            ),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.create_new_folder,
                color:
                    widget.selectedIndex == 3 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.configFileMenu,
                style: TextStyle(
                  color: widget.selectedIndex == 3
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.settings,
                color:
                    widget.selectedIndex == 4 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.settings,
                style: TextStyle(
                  color: widget.selectedIndex == 4
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                if (Navigator.canPop(context) &&
                    ModalRoute.of(context)?.settings.name == '/settings') {
                  Navigator.popUntil(context, ModalRoute.withName('/settings'));
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/settings',
                    (route) => route.isFirst,
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.info,
                color:
                    widget.selectedIndex == 5 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.aboutUs,
                style: TextStyle(
                  color: widget.selectedIndex == 5
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                if (Navigator.canPop(context) &&
                    ModalRoute.of(context)?.settings.name == '/aboutUs') {
                  Navigator.popUntil(context, ModalRoute.withName('/aboutUs'));
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/aboutUs',
                    (route) => route.isFirst,
                  );
                }
              },
            ),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.menu_book,
                color:
                    widget.selectedIndex == 6 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.documentationMenu,
                style: TextStyle(
                  color: widget.selectedIndex == 6
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.star,
                color:
                    widget.selectedIndex == 7 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.rateApp,
                style: TextStyle(
                  color: widget.selectedIndex == 7
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
                focusColor: listTileFocusColor,
                dense: true,
                leading: Icon(
                  Icons.shopping_cart,
                  color:
                      widget.selectedIndex == 8 ? selectedMenuColor : menuColor,
                ),
                title: Text(
                  appLocalizations.buyPsLabMenu,
                  style: TextStyle(
                    color: widget.selectedIndex == 8
                        ? selectedMenuColor
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onTap: () async {
                  final launched =
                      await launchUrl(Uri.parse(appLocalizations.shopLink));
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLocalizations.shopError)),
                    );
                  }
                }),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.feedback,
                color:
                    widget.selectedIndex == 9 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.faqMenu,
                style: TextStyle(
                  color: widget.selectedIndex == 9
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                if (Navigator.canPop(context) &&
                    ModalRoute.of(context)?.settings.name == '/faq') {
                  Navigator.popUntil(context, ModalRoute.withName('/faq'));
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/faq',
                    (route) => route.isFirst,
                  );
                }
              },
            ),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.share,
                color:
                    widget.selectedIndex == 10 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.shareAppMenu,
                style: TextStyle(
                  color: widget.selectedIndex == 10
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.article,
                color:
                    widget.selectedIndex == 11 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.privacyPolicyMenu,
                style: TextStyle(
                  color: widget.selectedIndex == 11
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: listTileFocusColor,
              dense: true,
              leading: Icon(
                Icons.attribution,
                color:
                    widget.selectedIndex == 12 ? selectedMenuColor : menuColor,
              ),
              title: Text(
                appLocalizations.softwareLicenses,
                style: TextStyle(
                  color: widget.selectedIndex == 12
                      ? selectedMenuColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                if (Navigator.canPop(context) &&
                    ModalRoute.of(context)?.settings.name ==
                        '/softwareLicenses') {
                  Navigator.popUntil(
                      context, ModalRoute.withName('/softwareLicenses'));
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/softwareLicenses',
                    (route) => route.isFirst,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
