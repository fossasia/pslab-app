import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/applications_list_item.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/oscilloscope') {
          Navigator.popUntil(context, ModalRoute.withName('/oscilloscope'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/oscilloscope',
            (route) => route.isFirst,
          );
        }
        break;
      default:
        break;
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
    super.initState();
    Permission.microphone.request();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 0,
      title: 'Instruments',
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior(),
          child: ListView.builder(
            itemCount: instrumentHeadings.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: ApplicationsListItem(
                  heading: instrumentHeadings[index],
                  description: instrumentDesc[index],
                  instrumentIcon: instrumentIcons[index],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
