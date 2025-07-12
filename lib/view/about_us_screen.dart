import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});
  @override
  State<StatefulWidget> createState() => _AboutUsScreenState();
}

Widget buildContactList(List<Map<String, dynamic>> items) {
  return ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: items.length,
    separatorBuilder: (_, __) => const Divider(thickness: 0.5, height: 1),
    itemBuilder: (context, index) {
      final item = items[index];
      return ListTile(
        leading: item['icon'] as Icon,
        title: Text(
          item['title'],
          style: const TextStyle(fontSize: 15),
        ),
        onTap: () async {
          final uri = Uri.parse(item['url']);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            debugPrint('Could not launch ${item['url']}');
          }
        },
      );
    },
  );
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  String get iconAboutUs => 'assets/images/logo.png';
  final List<Map<String, dynamic>> contactItems = [
    {
      'icon': const Icon(Icons.mail),
      'title': appLocalizations.contactUs,
      'url': 'mailto:${appLocalizations.mail}'
    },
    {
      'icon': const Icon(Icons.link),
      'title': appLocalizations.visitOurWebsite,
      'url': appLocalizations.website
    },
    {
      'icon': const Icon(FontAwesomeIcons.github, size: 20),
      'title': appLocalizations.forkUsOnGithub,
      'url': appLocalizations.github
    },
    {
      'icon': const Icon(Icons.facebook_sharp),
      'title': appLocalizations.likeUsOnFacebook,
      'url': appLocalizations.facebook
    },
    {
      'icon': const Icon(FontAwesomeIcons.xTwitter, size: 20),
      'title': appLocalizations.followUsOnX,
      'url': appLocalizations.x
    },
    {
      'icon': const Icon(FontAwesomeIcons.youtube, size: 20),
      'title': appLocalizations.watchUsOnYoutube,
      'url': appLocalizations.youtube
    },
    {
      'icon': const Icon(Icons.person),
      'title': appLocalizations.developersLink,
      'url': appLocalizations.developers
    },
  ];

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: appLocalizations.aboutUs,
      index: 5,
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 30,
            ),
            Center(
              child: Image.asset(
                iconAboutUs,
                width: 250,
                height: 250,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Text(
                  appLocalizations.pslabDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            ListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(appLocalizations.feedbackNBugs,
                      style: const TextStyle(
                        fontSize: 15,
                      )),
                  onTap: () async {
                    await launchUrl(Uri.parse(appLocalizations.feedbackForm));
                  },
                ),
                const Divider(
                  thickness: 0.5,
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(Icons.widgets),
                  title: FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (BuildContext context,
                          AsyncSnapshot<PackageInfo> snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            snapshot.data!.version,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          );
                        } else {
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          );
                        }
                      }),
                )
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 15, top: 10, bottom: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                appLocalizations.connectWithUs,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            buildContactList(contactItems)
          ],
        ),
      ))),
    );
  }
}
