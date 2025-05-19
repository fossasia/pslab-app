import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
