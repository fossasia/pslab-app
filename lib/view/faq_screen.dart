import 'package:flutter/material.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pslab/constants.dart';

class FAQScreen extends StatelessWidget {
  static const List<FAQItem> faqs = [
    FAQItem(
      question: FAQConstants.whatIsPslab,
      answer: FAQConstants.whatIsPslabAnswer,
    ),
    FAQItem(
      question: FAQConstants.whereToBuy,
      answer: FAQConstants.whereToBuyAnswer,
      linkText: FAQConstants.whereToBuyLinkText,
      linkUrl: FAQConstants.whereToBuyLinkUrl,
    ),
    FAQItem(
      question: FAQConstants.downloadAndroidApp,
      answer: FAQConstants.downloadAndroidAppAnswer,
      linkText: FAQConstants.downloadAndroidAppLinkText,
      linkUrl: FAQConstants.downloadAndroidAppLinkUrl,
    ),
    FAQItem(
      question: FAQConstants.downloadDesktopApp,
      answer: FAQConstants.downloadDesktopAppAnswer,
    ),
    FAQItem(
      question: FAQConstants.howToConnect,
      answer: FAQConstants.howToConnectAnswer,
    ),
    FAQItem(
        question: FAQConstants.reportBug,
        answer: FAQConstants.reportBugAnswer,
        linkText: FAQConstants.reportBugLinkText,
        linkUrl: FAQConstants.reportBugLinkUrl),
    FAQItem(
      question: FAQConstants.recordData,
      answer: FAQConstants.recordDataAnswer,
    ),
    FAQItem(
      question: FAQConstants.usePhoneSensors,
      answer: FAQConstants.usePhoneSensorsAnswer,
    ),
    FAQItem(
      question: FAQConstants.compatibleSensors,
      answer: FAQConstants.compatibleSensorsAnswer,
    ),
  ];

  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: faqTitle,
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
              Q,
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
                A,
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
      throw '$launchError $url';
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
