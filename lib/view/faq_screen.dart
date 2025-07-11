import 'package:flutter/material.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class FAQScreen extends StatelessWidget {
  final AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<FAQItem> faqs = [
      FAQItem(
        question: appLocalizations.faqWhatIsPslab,
        answer: appLocalizations.faqWhatIsPslabAnswer,
      ),
      FAQItem(
        question: appLocalizations.faqWhereToBuy,
        answer: appLocalizations.faqWhereToBuyAnswer,
        linkText: appLocalizations.faqWhereToBuyLinkText,
        linkUrl: appLocalizations.faqWhereToBuyLinkUrl,
      ),
      FAQItem(
        question: appLocalizations.faqDownloadAndroidApp,
        answer: appLocalizations.faqDownloadAndroidAppAnswer,
        linkText: appLocalizations.faqDownloadAndroidAppLinkText,
        linkUrl: appLocalizations.faqDownloadAndroidAppLinkUrl,
      ),
      FAQItem(
        question: appLocalizations.faqDownloadDesktopApp,
        answer: appLocalizations.faqDownloadDesktopAppAnswer,
      ),
      FAQItem(
        question: appLocalizations.faqHowToConnect,
        answer: appLocalizations.faqHowToConnectAnswer,
      ),
      FAQItem(
          question: appLocalizations.faqReportBug,
          answer: appLocalizations.faqReportBugAnswer,
          linkText: appLocalizations.faqReportBugLinkText,
          linkUrl: appLocalizations.faqReportBugLinkUrl),
      FAQItem(
        question: appLocalizations.faqRecordData,
        answer: appLocalizations.faqRecordDataAnswer,
      ),
      FAQItem(
        question: appLocalizations.faqUsePhoneSensors,
        answer: appLocalizations.faqUsePhoneSensorsAnswer,
      ),
      FAQItem(
        question: appLocalizations.faqCompatibleSensors,
        answer: appLocalizations.faqCompatibleSensorsAnswer,
      ),
    ];
    return MainScaffold(
      title: appLocalizations.faqTitle,
      index: 6,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: faqs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => _buildFAQItem(faqs[index]),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Row(children: [
            Text(
              appLocalizations.faqQ,
              style: TextStyle(
                color: primaryRed,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Flexible(
              child: Text(
                faq.question,
                style: TextStyle(
                  color: primaryRed,
                ),
              ),
            ),
          ]),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(5, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        trailing: const SizedBox(),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                appLocalizations.faqA,
              ),
              const SizedBox(
                width: 10,
              ),
              Flexible(
                child: Text(
                  faq.answer,
                ),
              ),
            ]),
          ),
          if (faq.linkText != null && faq.linkUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => _launchURL(faq.linkUrl!),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 25,
                    ),
                    Text(
                      faq.linkText!,
                      style: TextStyle(
                        color: primaryRed,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw '${appLocalizations.launchError} $url';
    }
  }
}

class FAQItem {
  final String question;
  final String answer;
  final String? linkText;
  final String? linkUrl;

  const FAQItem({
    required this.question,
    required this.answer,
    this.linkText,
    this.linkUrl,
  });
}
