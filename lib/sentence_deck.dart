/// One English sentence, optionally with a recorded mp3.
class Sentence {
  const Sentence(this.text, {this.translation, this.audioUrl, this.credit});

  final String text;

  /// Korean translation, if known.
  final String? translation;
  final String? audioUrl;

  /// Who wrote/recorded it, shown for CC BY attribution.
  final String? credit;
}

/// English conversation sentences, served one at a time.
class SentenceDeck {
  SentenceDeck([List<Sentence>? sentences])
      : sentences = [...(sentences ?? defaultSentences)] {
    if (this.sentences.isEmpty) throw ArgumentError('sentences must not be empty');
  }

  /// Offline fallback when Tatoeba can't be reached.
  static const defaultSentences = [
    Sentence('Hi, how are you doing today?', translation: '안녕하세요, 오늘 어떻게 지내세요?'),
    Sentence('Could you tell me how to get to the subway station?',
        translation: '지하철역에 어떻게 가는지 알려 주시겠어요?'),
    Sentence("I'd like a cup of coffee, please.", translation: '커피 한 잔 주세요.'),
    Sentence('What do you do for a living?', translation: '무슨 일을 하세요?'),
    Sentence('Sorry, could you say that again more slowly?',
        translation: '죄송한데, 좀 더 천천히 다시 말씀해 주시겠어요?'),
  ];

  final List<Sentence> sentences;
  int _index = 0;

  int get index => _index;
  Sentence get current => sentences[_index];

  /// How many sentences are left after the current one.
  int get remaining => sentences.length - 1 - _index;

  /// Swaps the whole deck (e.g. offline list → fetched list) and starts over.
  void replaceAll(List<Sentence> items) {
    if (items.isEmpty) return;
    sentences
      ..clear()
      ..addAll(items);
    _index = 0;
  }

  void addAll(List<Sentence> items) => sentences.addAll(items);

  /// Moves to the next sentence, wrapping back to the first after the last.
  Sentence next() {
    _index = (_index + 1) % sentences.length;
    return current;
  }
}
