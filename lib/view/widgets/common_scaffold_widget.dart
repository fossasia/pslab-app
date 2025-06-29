import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

class CommonScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final Key? scaffoldKey;
  final List<Widget>? actions;
  final VoidCallback? onGuidePressed;
  const CommonScaffold({
    super.key,
    required this.body,
    required this.title,
    this.scaffoldKey,
    this.actions,
    this.onGuidePressed,
  });
  @override
  State<StatefulWidget> createState() => _CommonScaffoldState();
}

class _CommonScaffoldState extends State<CommonScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: appBarColor),
        leading: Builder(builder: (context) {
          return IconButton(
            onPressed: () {
              if (Navigator.canPop(context) &&
                  ModalRoute.of(context)?.settings.name == '/') {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => route.isFirst,
                );
              }
            },
            icon: Icon(
              Icons.arrow_back,
              color: appBarContentColor,
            ),
          );
        }),
        backgroundColor: primaryRed,
        title: Text(
          key: widget.scaffoldKey,
          widget.title,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
        actions: [
          if (widget.onGuidePressed != null)
            IconButton(
              onPressed: widget.onGuidePressed,
              icon: const Icon(
                Icons.info,
                color: Colors.white,
              ),
            ),
          if (widget.actions != null) ...widget.actions!,
        ],
      ),
      body: widget.body,
    );
  }
}
