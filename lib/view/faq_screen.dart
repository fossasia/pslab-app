import 'package:flutter/material.dart';
import 'package:pslab/colors.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class FAQScreen extends StatelessWidget {
  static const List<FAQItem> faqs = [
    FAQItem(
      question: "What is Pocket Science Lab? What can I do with it?",
      answer:
          "Pocket Science Lab (PSLab) is a small USB powered hardware board that can be used for measurements and experiments. It works as an extension for Android phones or PCs. PSLab comes with a built-in Oscilloscope, Multimeter, Wave Generator, Logic Analyzer, Power Source, and many more instruments. It can also be used as a robotics control app. And, we are constantly adding more digital instruments. PSLab is many devices in one. Simply connect two wires to the relevant pins (description is on the back of the PSLab board) and start measuring. You can use our Open Source Android or desktop app to view and collect the data. You can also plug in hundreds of compatible I²C standard sensors to the PSLab pin slots. It works without the need for programming. So, what experiments you do is just limited to your imagination!",
    ),
    FAQItem(
      question: "Where can I buy a Pocket Science Lab?",
      answer:
          "There is an overview page for shops where you can buy a Pocket Science Lab device in different regions on the website at ",
      linkText: "https://pslab.io/shop/",
      linkUrl: "https://pslab.io/shop/",
    ),
    FAQItem(
        question:
            "Where can I download the Android App for Pocket Science Lab?",
        answer:
            "The app can be downloaded from F-Droid or Play Store. Simply click on the links to be directed over!",
        linkText: "Playstore",
        linkUrl:
            "https://play.google.com/store/apps/details?id=io.pslab&hl=en_IN"),
    FAQItem(
      question:
          "Where can I download the desktop app for Pocket Science Lab for Windows, Linux and Mac?",
      answer:
          "We are developing a desktop app for Windows, Linux and Mac in our desktop Git repository. You can find it in the install branch of the project here. The app is still under development. We are using technologies like Electron and Python, that work on all platforms. However, to make the final installer work everywhere requires some tweaks and improvements here and there. So, please expect some glitches. You can use the tracker in the repository to submit issues, bugs and feature requests.",
    ),
    FAQItem(
      question:
          "How can I connect to the device? What kind of USB cable do I need? What is an OTG USB cable?",
      answer:
          "To connect to the device you need an OTG USB cable (OTG = On the go) which is a USB cable that allows connected devices to switch back and forth between the roles of host and device. USB cables that are not OTG compatible will NOT work. It is also possible to extend the PSLab with an ESP WiFi chip or a Bluetooth chip and communicate through these gateways using the Android app. You can refer to the hardware developer documentation and code on GitHub for more details here.",
    ),
    FAQItem(
        question:
            "I found a bug in one of your apps or hardware. What to do? Where should I report it?",
        answer:
            "We have issue trackers in all our projects. They are currently hosted on GitHub. In order to submit a bug or feature request you need to login to the service.",
        linkText: "A list of our PSLab repositories is here",
        linkUrl: "https://github.com/fossasia"),
    FAQItem(
      question:
          "Can I record or save data in the apps and export or import it?",
      answer:
          "Yes, we have implemented a record and play function or a way to save and open configurations in the instruments on the Android and desktop app. Data you record can be imported into the apps and viewed. This feature is still under heavy development, but works well in most places. You can find it in the top bar of the apps. There are buttons to record, play, save and open data.",
    ),
    FAQItem(
      question:
          "My Android phone already has some sensors, can I use them with the PSLab app as well?",
      answer:
          "Yes, absolutely. You can install the PSLab Android app (Play Store, Fdroid) on your phone and use it with devices such as Luxmeter or Compass. We are adding support for more built-in sensors step by step.",
    ),
    FAQItem(
      question:
          "Which external sensors can I use with a PSLab device and the apps? Which ones are compatible?",
      answer:
          "In our apps we use the industry standard I²C (Wikipedia). You can get the data from sensors that are connected to the device through the USB port using an OTG USB cable (OTG = On the go) which is a USB cable that allows connected devices to switch back and forth between the roles of host and device. For the transfer we use UART (universal asynchronous receiver-transmitter, Wikipedia). Many sensors can be used with specific instruments, e.g. Barometer, Thermometer, Gyroscope etc. You can access the configuration for sensors in the instrument settings on the top right burger menu of each instrument. All sensors using the I²C standard are compatible with the device. There are connection pins for analogue and digital sensors. You find the description of the pins on the back of the device. Even if there is no specific instrument in one of our apps yet, you can still view and store the raw data using the Oscilloscope instrument component. There is a page with a list of recommended sensors on the website.",
    ),
  ];

  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'FAQs',
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
        shape: Border(),
        collapsedShape: Border(),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Row(children: [
            Text(
              'Q:',
              style: TextStyle(
                color: primaryRed,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Flexible(
              child: Text(
                '${faq.question}',
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
            padding: const EdgeInsets.only(top: 0), // Space before answer
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'A:',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Flexible(
                child: Text(
                  '${faq.answer}',
                  style: TextStyle(
                    color: Colors.black,
                  ),
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
                    SizedBox(
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
      throw 'Could not launch $url';
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
