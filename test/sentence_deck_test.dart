import 'package:flutter_test/flutter_test.dart';
import 'package:voice_chat_app/sentence_deck.dart';
import 'package:voice_chat_app/tatoeba_client.dart';

void main() {
  const a = Sentence('A'), b = Sentence('B'), c = Sentence('C');

  test('starts at the first sentence', () {
    final deck = SentenceDeck([a, b]);
    expect(deck.index, 0);
    expect(deck.current.text, 'A');
  });

  test('next moves forward and wraps around', () {
    final deck = SentenceDeck([a, b, c]);
    expect(deck.next().text, 'B');
    expect(deck.next().text, 'C');
    expect(deck.next().text, 'A');
  });

  test('replaceAll restarts, addAll extends', () {
    final deck = SentenceDeck([a])..next();
    deck.replaceAll([b, c]);
    expect(deck.current.text, 'B');
    deck.addAll([a]);
    expect(deck.remaining, 2);
  });

  test('empty list is rejected', () {
    expect(() => SentenceDeck([]), throwsArgumentError);
  });

  test('parses Tatoeba response into sentences with mp3 urls', () {
    const body = '{"data":['
        '{"id":3222952,"text":"You have to sit down.","owner":"CK"},'
        '{"id":1,"text":"one two three four five six seven eight nine ten eleven twelve thirteen","owner":"x"}'
        ']}';
    final list = TatoebaClient.parse(body);
    expect(list, hasLength(1)); // long sentence filtered out
    expect(list.first.text, 'You have to sit down.');
    expect(list.first.audioUrl, 'https://audio.tatoeba.org/sentences/eng/3222952.mp3');
    expect(list.first.credit, contains('CK'));
  });

  test('keeps conversational sentences, drops narration', () {
    expect(TatoebaClient.isConversational('How is it going?'), isTrue);
    expect(TatoebaClient.isConversational("I'd like a cup of coffee."), isTrue);
    expect(TatoebaClient.isConversational('Thank you for coming.'), isTrue);
    expect(TatoebaClient.isConversational("Tom didn't die right away."), isFalse);
    expect(TatoebaClient.isConversational('The house could do with paint.'), isFalse);
    expect(TatoebaClient.isConversational('Hi!'), isFalse); // too short
  });
}
