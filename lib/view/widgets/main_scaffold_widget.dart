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

  const MainScaffold(
      {super.key,
      required this.body,
      required this.title,
      this.scaffoldKey,
      this.actions,
      required this.index});

  @override
  State<StatefulWidget> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        title: Text(
          key: widget.scaffoldKey,
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: [
          Consumer<BoardStateProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Image.asset(
                  provider.pslabIsConnected
                      ? widget.icUsbConnected
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
