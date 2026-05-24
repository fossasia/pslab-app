import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/oss_licenses.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SoftwareLicensesScreen extends StatelessWidget {
  const SoftwareLicensesScreen({super.key});
  static Future<List<Package>> loadLicenses() async {
    final lm = <String, List<String>>{};
    await for (var l in LicenseRegistry.licenses) {
      for (var p in l.packages) {
        final lp = lm.putIfAbsent(p, () => []);
        lp.addAll(l.paragraphs.map((p) => p.text));
      }
    }
    final licenses = allDependencies.toList();
    for (var key in lm.keys) {
      licenses.add(Package(
          name: key,
          description: '',
          authors: [],
          version: '',
          license: lm[key]!.join('\n\n'),
          isMarkdown: false,
          isSdk: false,
          dependencies: []));
    }
    return licenses..sort((a, b) => a.name.compareTo(b.name));
  }

  static final _licenses = loadLicenses();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MainScaffold(
      title: l10n.softwareLicenses,
      index: 12,
      body: FutureBuilder<List<Package>>(
        future: _licenses,
        initialData: const [],
        builder: (context, snapshot) {
          final packages = snapshot.data ?? const <Package>[];
          return ListView.separated(
            padding: const EdgeInsets.all(0),
            itemCount: packages.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    l10n.licensesIntro,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                );
              }
              final package = packages[index - 1];
              return ListTile(
                title: Text('${package.name} ${package.version}'),
                subtitle: package.description.isNotEmpty
                    ? Text(package.description)
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        MiscOssLicenseSingle(package: package),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
          );
        },
      ),
    );
  }
}

class MiscOssLicenseSingle extends StatelessWidget {
  final Package package;

  const MiscOssLicenseSingle({super.key, required this.package});
  String _bodyText() {
    return package.license!.split('\n').map((line) {
      if (line.startsWith('//')) line = line.substring(2);
      line = line.trim();
      return line;
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final headingStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        );
    return Scaffold(
      appBar: AppBar(title: Text('${package.name} ${package.version}')),
      body: Container(
        color: Theme.of(context).canvasColor,
        child: ListView(
          children: [
            if (package.description.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
                child: Text(l10n.licenseDescription, style: headingStyle),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0),
                child: Text(
                  package.description,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
            if (package.homepage != null) ...[
              Padding(
                padding:
                    const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
                child: Text(l10n.licenseHomepage, style: headingStyle),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0),
                child: InkWell(
                  child: Text(
                    package.homepage!,
                    style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                  onTap: () => launchUrlString(package.homepage!),
                ),
              ),
            ],
            if (package.description.isNotEmpty || package.homepage != null)
              const Divider(),
            Padding(
              padding:
                  const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
              child: Text(l10n.licenseText, style: headingStyle),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0),
              child: Text(
                _bodyText(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          ],
        ),
      ),
    );
  }
}
