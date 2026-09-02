import 'dart:convert';

import 'package:http/http.dart' as http;

/// Lightweight, user-triggered web context for local models.
/// Search results are treated as untrusted reference text, never as instructions.
class WebSearchService {
  Future<String> search(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return '';
    final uri = Uri.https('api.duckduckgo.com', '/', {
      'q': cleaned.length > 240 ? cleaned.substring(0, 240) : cleaned,
      'format': 'json',
      'no_html': '1',
      'no_redirect': '1',
      'skip_disambig': '1',
    });
    try {
      final response = await http.get(uri, headers: {'accept': 'application/json'}).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return '';
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final lines = <String>[];
      final abstract = data['AbstractText'] as String?;
      final abstractUrl = data['AbstractURL'] as String?;
      if (abstract != null && abstract.isNotEmpty) lines.add('- $abstract${abstractUrl?.isNotEmpty == true ? ' ($abstractUrl)' : ''}');
      void collect(List<dynamic>? topics) {
        if (topics == null) return;
        for (final item in topics.take(5)) {
          if (item is Map<String, dynamic>) {
            final text = item['Text'] as String?;
            final url = item['FirstURL'] as String?;
            if (text != null && text.isNotEmpty) lines.add('- $text${url?.isNotEmpty == true ? ' ($url)' : ''}');
            collect(item['Topics'] as List<dynamic>?);
          }
        }
      }
      collect(data['RelatedTopics'] as List<dynamic>?);
      if (lines.isEmpty) return '';
      return 'WEB CONTEXT (retrieved now; verify important claims):\n${lines.join('\n')}';
    } catch (_) {
      return '';
    }
  }
}
