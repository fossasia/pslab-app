import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import '../../theme/colors.dart';
import '../pin_layout_screen.dart';
import 'navigation_drawer.dart';

class MainScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final Key? scaffoldKey;
  final int index;
  final List<Widget>? actions;
  final String icUsbDisconnected = 'assets/icons/ic_usb_disconnected.png';
  final String icUsbConnected = 'assets/icons/ic_usb_connected.png';
  final String icWiFiConnected = 'assets/icons/ic_wifi_connected.png';
  final bool showSearch;
  final Function(String)? onSearchChanged;
  final String? searchHint;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    this.scaffoldKey,
    this.actions,
    required this.index,
    this.showSearch = false,
    this.onSearchChanged,
    this.searchHint,
  });

  @override
  State<StatefulWidget> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearching) {
        _isSearching = false;
        _animationController.reverse();
        _searchController.clear();
        if (widget.onSearchChanged != null) {
          widget.onSearchChanged!('');
        }
      } else {
        _isSearching = true;
        _animationController.forward();
      }
    });
  }

  void _onSearchChanged(String query) {
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double iconGlyph = (screenWidth * 0.05).clamp(14.0, 24.0);
    final double btnMin = (screenWidth * 0.075).clamp(24.0, 36.0);
    final double titleSize = (screenWidth * 0.04).clamp(13.0, 18.0);
    final double btnHPad = (screenWidth * 0.018).clamp(2.0, 10.0);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: appBarColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: Builder(builder: (context) {
          return IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: appLocalizations.openMenu,
            iconSize: iconGlyph,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: btnHPad),
            constraints: BoxConstraints(
              minWidth: btnMin,
              minHeight: btnMin,
            ),
            icon: Icon(
              Icons.menu,
              color: appBarContentColor,
            ),
          );
        }),
        titleSpacing: 0,
        backgroundColor: appBarColor,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 0),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: _isSearching
              ? TextField(
                  key: const ValueKey('search_field'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  autofocus: true,
                  style: TextStyle(
                    color: appBarContentColor,
                    fontSize: titleSize,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: TextStyle(
                      color: searchBarHintTextColor,
                      fontSize: titleSize,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: appBarContentColor,
                )
              : Text(
                  key: widget.scaffoldKey,
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: appBarContentColor,
                    fontSize: titleSize,
                  ),
                ),
        ),
        actions: _isSearching
            ? [
                IconButton(
                  iconSize: iconGlyph,
                  tooltip: appLocalizations.clearSearch,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: btnHPad),
                  constraints: BoxConstraints(
                    minWidth: btnMin,
                    minHeight: btnMin,
                  ),
                  icon: Icon(
                    Icons.clear,
                    color: appBarContentColor,
                  ),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _searchController.clear();
                      _onSearchChanged('');
                    } else {
                      _toggleSearch();
                    }
                  },
                ),
              ]
            : [
                if (widget.showSearch)
                  IconButton(
                    tooltip: appLocalizations.search,
                    icon: Icon(
                      Icons.search,
                      color: appBarContentColor,
                    ),
                    iconSize: iconGlyph,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: btnHPad),
                    constraints: BoxConstraints(
                      minWidth: btnMin,
                      minHeight: btnMin,
                    ),
                    onPressed: _toggleSearch,
                  ),
                Consumer<BoardStateProvider>(
                  builder: (context, provider, _) {
                    return IconButton(
                      tooltip: provider.pslabIsConnected
                          ? (provider.scienceLabCommon.isWiFiConnected()
                              ? appLocalizations.wifiConnected
                              : appLocalizations.usbConnected)
                          : appLocalizations.connectDevice,
                      icon: Image.asset(
                        provider.pslabIsConnected
                            ? (provider.scienceLabCommon.isWiFiConnected()
                                ? widget.icWiFiConnected
                                : widget.icUsbConnected)
                            : widget.icUsbDisconnected,
                        width: iconGlyph,
                        height: iconGlyph,
                      ),
                      iconSize: iconGlyph,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(horizontal: btnHPad),
                      constraints: BoxConstraints(
                        minWidth: btnMin,
                        minHeight: btnMin,
                      ),
                      onPressed: () {
                        provider.initialize();
                        if (Navigator.canPop(context) &&
                            ModalRoute.of(context)?.settings.name ==
                                '/connectDevice') {
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
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: appBarContentColor,
                    size: iconGlyph,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: iconGlyph,
                  constraints: BoxConstraints(
                    minWidth: btnMin,
                    minHeight: btnMin,
                  ),
                  tooltip: 'Options',
                  onSelected: (String value) {
                    if (value == 'pin_layout') {
                      if (ModalRoute.of(context)?.settings.name ==
                          '/pinLayout') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PSLabPinLayoutScreen(),
                            settings: const RouteSettings(name: '/pinLayout'),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PSLabPinLayoutScreen(),
                            settings: const RouteSettings(name: '/pinLayout'),
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'pin_layout',
                      child: Text('Pin Layout'),
                    ),
                  ],
                ),
                ...(widget.actions ?? const []),
              ],
      ),
      body: widget.body,
      drawer: NavDrawer(
        selectedIndex: widget.index,
      ),
    );
  }
}
