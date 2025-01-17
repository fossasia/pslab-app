import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final Key? scaffoldKey;
  final List<Widget>? actions;

  const CommonScaffold({
    super.key,
    required this.body,
    required this.title,
    this.scaffoldKey,
    this.actions,
  });

  @override
  State<StatefulWidget> createState() => _CommonScaffoldState();
}

class _CommonScaffoldState extends State<CommonScaffold> {
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
            icon: const Icon(
              Icons.arrow_back,
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
            fontSize: 15,
          ),
        ),
        actions: [
          if (widget.actions != null) ...widget.actions!,
        ],
      ),
      body: widget.body,
    );
  }
}
