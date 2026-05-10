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
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 28,
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
      'url': 'mailto:${appLocalizations.mail}',
    },
    {
      'icon': const Icon(Icons.link),
      'title': appLocalizations.visitOurWebsite,
      'url': appLocalizations.website,
    },
    {
      'icon': const FaIcon(FontAwesomeIcons.github, size: 20),
      'title': appLocalizations.forkUsOnGithub,
      'url': appLocalizations.github,
    },
    {
      'icon': const Icon(Icons.facebook_sharp),
      'title': appLocalizations.likeUsOnFacebook,
      'url': appLocalizations.facebook,
    },
    {
      'icon': const FaIcon(FontAwesomeIcons.xTwitter, size: 20),
      'title': appLocalizations.followUsOnX,
      'url': appLocalizations.x,
    },
    {
      'icon': const FaIcon(FontAwesomeIcons.youtube, size: 20),
      'title': appLocalizations.watchUsOnYoutube,
      'url': appLocalizations.youtube,
    },
    {
      'icon': const Icon(Icons.person),
      'title': appLocalizations.developersLink,
      'url': appLocalizations.developers,
    },
  ];

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: appLocalizations.aboutUs,
      index: 5,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  iconAboutUs,
                  width: 130,
                  height: 130,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  appLocalizations.pslabDescription,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 0.5),
              ListTile(
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 28,
                leading: const Icon(Icons.link),
                title: Text(
                  appLocalizations.feedbackNBugs,
                  style: const TextStyle(fontSize: 15),
                ),
                onTap: () async {
                  await launchUrl(Uri.parse(appLocalizations.feedbackForm));
                },
              ),
              const Divider(thickness: 0.5),
              ListTile(
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 28,
                leading: const Icon(Icons.widgets),
                title: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!.version,
                        style: const TextStyle(fontSize: 15),
                      );
                    }

                    return const Text(
                      'Loading...',
                      style: TextStyle(fontSize: 15),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              buildSectionTitle(appLocalizations.connectWithUs),
              const Divider(thickness: 0.5, height: 1),
              buildContactList(contactItems),
            ],
          ),
        ),
      ),
    );
  }
}
