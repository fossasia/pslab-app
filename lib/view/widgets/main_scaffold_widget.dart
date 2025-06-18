import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/board_state_provider.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarColor: Color(0xFFD32F2F)),
        leading: Builder(builder: (context) {
          return IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
          );
        }),
        backgroundColor: const Color(0xFFD32F2F),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: Colors.white,
                )
              : Text(
                  key: ValueKey('title_${widget.title}'),
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
        ),
        actions: _isSearching
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.white,
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
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                    onPressed: _toggleSearch,
                  ),
                Consumer<BoardStateProvider>(
                  builder: (context, provider, _) {
                    return IconButton(
                      icon: Image.asset(
                        provider.pslabIsConnected
                            ? (provider.scienceLabCommon.isWiFiConnected()
                                ? widget.icWiFiConnected
                                : widget.icUsbConnected)
                            : widget.icUsbDisconnected,
                        width: 24,
                        height: 24,
                      ),
                      onPressed: () {
                        /**/
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    /**/
                  },
                ),
              ],
      ),
      body: widget.body,
      drawer: NavDrawer(
        selectedIndex: widget.index,
      ),
    );
  }
}
