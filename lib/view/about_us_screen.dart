import 'package:flutter/material.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<AboutUsScreen> {
  String get iconAboutUs => 'assets/icons/icon.png';

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: aboutUs,
      index: 5,
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Image.asset(
                iconAboutUs,
                width: 120,
                height: 120,
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Text(
                  pslabDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
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
                  title: Text(feedbackNBugs,
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                  onTap: () async {
                    await launchUrl(Uri.parse(feedbackForm));
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
                              fontSize: 14,
                            ),
                          );
                        } else {
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 14,
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
                connectWithUs[0],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            ListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.mail),
                  title: Text(connectWithUs[1],
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                  onTap: () async {
                    await launchUrl(Uri.parse('mailto:$mail'));
                  },
                ),
                const Divider(
                  thickness: 0.5,
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(connectWithUs[2],
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                  onTap: () async {
                    await launchUrl(Uri.parse(website));
                  },
                ),
                const Divider(
                  thickness: 0.5,
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.github,
                    size: 20,
                  ),
                  title: Text(connectWithUs[3],
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                  onTap: () async {
                    await launchUrl(Uri.parse(github));
                  },
                ),
                const Divider(
                  thickness: 0.5,
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(Icons.facebook_sharp),
                  title: Text(connectWithUs[4],
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                  onTap: () async {
                    await launchUrl(Uri.parse(facebook));
                  },
                ),
                const Divider(
                  thickness: 0.5,
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.xTwitter,
                    size: 20,
                  ),
                  title: Text(connectWithUs[5],
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                  onTap: () async {
                    await launchUrl(Uri.parse(x));
                  },
                ),
                const Divider(
                  thickness: 0.5,
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.youtube,
                    size: 20,
                  ),
                  title: Text(connectWithUs[6],
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                  onTap: () async {
                    await launchUrl(Uri.parse(youtube));
                  },
                ),
                const Divider(
                  thickness: 0.5,
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(connectWithUs[7],
                      style: const TextStyle(
                        fontSize: 14,
                      )),
                  onTap: () async {
                    await launchUrl(Uri.parse(developers));
                  },
                )
              ],
            )
          ],
        ),
      ))),
    );
  }
}
