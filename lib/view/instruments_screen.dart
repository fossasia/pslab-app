import 'package:flutter/material.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/applications_list_item.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      index: 0,
      title: 'Instruments',
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior(),
          child: ListView.builder(
            itemCount: instrumentHeadings.length,
            itemBuilder: (context, index) {
              return ApplicationsListItem(
                heading: instrumentHeadings[index],
                description: instrumentDesc[index],
                instrumentIcon: instrumentIcons[index],
              );
            },
          ),
        ),
      ),
    );
  }
}
