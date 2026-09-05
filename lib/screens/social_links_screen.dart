import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class SocialLinksScreen extends StatelessWidget {
  const SocialLinksScreen({super.key});
  Future<void> _open(String value) async {
    final uri = Uri.parse(value);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.bg,
    appBar: AppBar(title: const Text('Krem|Ai Links'), backgroundColor: Colors.transparent),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Stay connected', style: TextStyle(color: context.text, fontSize: 26, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('Support, releases, and your customer portal.', style: TextStyle(color: context.textM)),
      const SizedBox(height: 20),
      _link(context, Icons.dashboard_rounded, 'Customer Portal', 'Login, keys, downloads, and community', 'https://portal.kremcheats.com'),
      _link(context, Icons.forum_rounded, 'Discord Support', 'Community and support tickets', 'https://discord.gg/nCb8pz8nkf'),
      _link(context, Icons.camera_alt_rounded, 'Instagram', '@Kremityss', 'https://instagram.com/Kremityss'),
      _link(context, Icons.music_note_rounded, 'TikTok', '@kremitys', 'https://tiktok.com/@kremitys'),
      _link(context, Icons.play_circle_fill_rounded, 'YouTube', '@kremitys', 'https://youtube.com/@kremitys'),
    ]),
  );
  Widget _link(BuildContext context, IconData icon, String title, String subtitle, String url) => Card(
    color: context.bgPanel, child: ListTile(leading: Icon(icon, color: AppColors.accent), title: Text(title, style: TextStyle(color: context.text, fontWeight: FontWeight.w700)), subtitle: Text(subtitle, style: TextStyle(color: context.textM)), trailing: Icon(Icons.open_in_new, color: context.textM), onTap: () => _open(url)));
}
