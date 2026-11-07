import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sentence_deck.dart';

/// Fetches random English sentences that have native-speaker recordings
/// from Tatoeba (https://tatoeba.org, sentences licensed CC BY 2.0 FR).
class TatoebaClient {
  static const _api = 'https://api.tatoeba.org/unstable/sentences';

  static String audioUrl(int id) => 'https://audio.tatoeba.org/sentences/eng/$id.mp3';

  /// Fetches a large random batch; [parse] keeps only the conversational ones.
  Future<List<Sentence>> fetchRandom({int limit = 100, int maxWords = 12}) async {
    final uri = Uri.parse(_api).replace(queryParameters: {
      'lang': 'eng',
      'has_audio': 'yes',
      'sort': 'random',
      'limit': '$limit',
      // Only sentences with a Korean translation, and return just that translation.
      'trans:lang': 'kor',
      'showtrans': 'matching',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Tatoeba error ${res.statusCode}');
    return parse(utf8.decode(res.bodyBytes), maxWords: maxWords);
  }

  // Tatoeba is full of "Tom"/"Mary" narration; these names mark non-dialogue lines.
  static final _names = RegExp(r"\b(Tom|Mary|John|Alice|Mennad|Baya|Ziri|Sami|Layla|Dan|Linda|Ken)\b");
  // Words people use when talking *to* someone.
  static final _dialogue = RegExp(
      r"\b(I|I'm|I'd|I'll|I've|you|you're|your|we|we're|let's|please|thanks|thank|sorry|excuse)\b",
      caseSensitive: false);

  /// True for short sentences that sound like something said in a conversation.
  static bool isConversational(String text, {int maxWords = 12}) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    if (words < 3 || words > maxWords) return false;
    if (_names.hasMatch(text)) return false;
    return text.trim().endsWith('?') || _dialogue.hasMatch(text);
  }

  static String? _korean(dynamic translations) {
    if (translations is! List) return null;
    for (final t in translations) {
      if (t is Map && t['lang'] == 'kor') return '${t['text']}';
    }
    return null;
  }

  /// Parses an API response, keeping only conversational sentences.
  static List<Sentence> parse(String body, {int maxWords = 12}) {
    final data = (jsonDecode(body)['data'] as List?) ?? [];
    return [
      for (final s in data)
        if (isConversational('${s['text']}', maxWords: maxWords))
          Sentence('${s['text']}',
              translation: _korean(s['translations']),
              audioUrl: audioUrl(s['id'] as int), credit: 'Tatoeba #${s['id']} · ${s['owner']}'),
    ];
  }
}
