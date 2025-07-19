import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

class CommonScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final Key? scaffoldKey;
  final List<Widget>? actions;
  final VoidCallback? onGuidePressed;
  final VoidCallback? onOptionsPressed;
  final VoidCallback? onRecordPressed;
  final bool isRecording;
  final String icRecord = 'assets/icons/ic_record_white.png';

  const CommonScaffold({
    super.key,
    required this.body,
    required this.title,
    this.scaffoldKey,
    this.actions,
    this.onGuidePressed,
    this.onOptionsPressed,
    this.onRecordPressed,
    this.isRecording = false,
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
          if (widget.onRecordPressed != null)
            IconButton(
              onPressed: widget.onRecordPressed,
              icon: Image.asset(
                widget.icRecord,
                width: 24,
                height: 24,
              ),
              tooltip:
                  widget.isRecording ? 'Stop Recording' : 'Start Recording',
            ),
          if (widget.onGuidePressed != null)
            IconButton(
              onPressed: widget.onGuidePressed,
              icon: Icon(
                Icons.info,
                color: appBarContentColor,
              ),
            ),
          if (widget.onOptionsPressed != null)
            IconButton(
              onPressed: widget.onOptionsPressed,
              icon: Icon(
                Icons.more_vert,
                color: appBarContentColor,
              ),
            ),
          if (widget.actions != null) ...widget.actions!,
        ],
      ),
      body: widget.body,
    );
  }
}
