import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/applications_list_item.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:pslab/colors.dart';

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<int> _filteredIndices = [];
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

  void _filterInstruments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIndices = List.generate(instrumentHeadings.length, (index) => index);
      } else {
        _filteredIndices = [];
        for (int i = 0; i < instrumentHeadings.length; i++) {
          if (instrumentHeadings[i].toLowerCase().contains(query.toLowerCase())) {
            _filteredIndices.add(i);
          }
        }
      }
    });
  }

  @override
  void initState() {
    _filteredIndices = List.generate(instrumentHeadings.length, (index) => index);
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 0,
      title: 'Instruments',
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterInstruments,
                  decoration: InputDecoration(
                    hintText: 'Search instruments...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No instruments found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                    final originalIndex = _filteredIndices[index];
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
