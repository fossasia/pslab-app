import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pslab/colors.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/applications_list_item.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});
  @override
  State<StatefulWidget> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<int> _filteredIndices = <int>[];
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
      case 7:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/accelerometer') {
          Navigator.popUntil(context, ModalRoute.withName('/accelerometer'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/accelerometer',
            (route) => route.isFirst,
          );
        }
        break;
      case 6:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/luxmeter') {
          Navigator.popUntil(context, ModalRoute.withName('/luxmeter'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/luxmeter',
            (route) => route.isFirst,
          );
        }
        break;
      case 10:
        if (Navigator.canPop(context) &&
            ModalRoute.of(context)?.settings.name == '/gyroscope') {
          Navigator.popUntil(context, ModalRoute.withName('/gyroscope'));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/gyroscope',
            (route) => route.isFirst,
          );
        }
        break;
      default:
        break;
    }
  }

  void _filterInstruments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIndices =
            List<int>.generate(instrumentHeadings.length, (index) => index);
      } else {
        _filteredIndices = List.generate(instrumentHeadings.length, (i) => i)
            .where((i) => instrumentHeadings[i]
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _filteredIndices =
        List<int>.generate(instrumentHeadings.length, (index) => index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
    Permission.microphone.request();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 0,
      title: instrumentsTitle,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterInstruments,
                  decoration: InputDecoration(
                    hintText: searchInstrumentsHint,
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(153),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(179),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(179),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterInstruments('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: primaryRed,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: primaryRed,
                        width: 2.5,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _filteredIndices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            noInstrumentsFoundMessage,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(179),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tryDifferentSearchSuggestion,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(128),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ScrollConfiguration(
                      behavior: const ScrollBehavior(),
                      child: ListView.builder(
                        itemCount: _filteredIndices.length,
                        itemBuilder: (context, index) {
                          final int originalIndex = _filteredIndices[index];
                          return GestureDetector(
                            onTap: () => _onItemTapped(originalIndex),
                            child: ApplicationsListItem(
                              heading: instrumentHeadings[originalIndex],
                              description: instrumentDesc[originalIndex],
                              instrumentIcon: instrumentIcons[originalIndex],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
