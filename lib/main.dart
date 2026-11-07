import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'sentence_deck.dart';
import 'tatoeba_client.dart';

void main() => runApp(const SpeakingApp());

class SpeakingApp extends StatelessWidget {
  const SpeakingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Speaking',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo, brightness: Brightness.dark, useMaterial3: true),
      home: const SpeakingScreen(),
    );
  }
}

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  /// Dropdown value meaning "play the Tatoeba recording".
  static const _recording = {'name': '원어민 녹음 (Tatoeba)', 'locale': 'mp3'};

  final _tts = FlutterTts();
  final _player = AudioPlayer();
  final _tatoeba = TatoebaClient();
  final _deck = SentenceDeck();

  /// Recording option first, then English TTS voices on the device.
  List<Map<String, String>> _voices = [_recording];
  Map<String, String> _voice = _recording;
  // Both start hidden and go back to hidden on every new sentence.
  bool _showSentence = false;
  bool _showTranslation = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);

    final raw = (await _tts.getVoices as List?) ?? [];
    final ttsVoices = [
      for (final v in raw)
        if (v is Map && '${v['locale']}'.toLowerCase().startsWith('en'))
          {'name': '${v['name']}', 'locale': '${v['locale']}'},
    ]..sort((a, b) => '${a['locale']}${a['name']}'.compareTo('${b['locale']}${b['name']}'));

    try {
      _deck.replaceAll(await _tatoeba.fetchRandom());
    } catch (e) {
      _toast('Tatoeba에 연결하지 못해 기본 문장을 사용합니다.');
    }
    if (!mounted) return;
    setState(() {
      _voices = [_recording, ...ttsVoices];
      _loading = false;
    });
    await _speak();
  }

  Future<void> _speak() async {
    await _player.stop();
    await _tts.stop();
    final s = _deck.current;
    if (_voice == _recording && s.audioUrl != null) {
      try {
        await _player.play(UrlSource(s.audioUrl!));
        return;
      } catch (_) {
        // Fall through to TTS if the mp3 can't be played.
      }
    }
    await _tts.speak(s.text);
  }

  Future<void> _next() async {
    setState(() {
      _deck.next();
      _showSentence = false;
      _showTranslation = false;
    });
    _speak();
    // Keep a buffer of fetched sentences so Next never runs dry.
    if (_deck.remaining < 5) {
      try {
        final more = await _tatoeba.fetchRandom();
        if (mounted) setState(() => _deck.addAll(more));
      } catch (_) {}
    }
  }

  Future<void> _selectVoice(Map<String, String>? v) async {
    if (v == null) return;
    setState(() => _voice = v);
    if (v != _recording) await _tts.setVoice(v);
    await _speak();
  }

  void _toast(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = _deck.current;
    return Scaffold(
      appBar: AppBar(title: const Text('English Speaking')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<Map<String, String>>(
              initialValue: _voice,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '음성 모델', border: OutlineInputBorder()),
              items: [
                for (final v in _voices)
                  DropdownMenuItem(
                    value: v,
                    child: Text(v == _recording ? v['name']! : '${v['name']}  (${v['locale']})'),
                  ),
              ],
              onChanged: _selectVoice,
            ),
            Expanded(
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${_deck.index + 1}', style: text.labelLarge),
                        const SizedBox(height: 12),
                        Text(_showSentence ? s.text : '• • •',
                            textAlign: TextAlign.center, style: text.headlineMedium),
                        const SizedBox(height: 16),
                        Text(_showTranslation ? (s.translation ?? '(번역 없음)') : '• • •',
                            textAlign: TextAlign.center,
                            style: text.titleMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        if (_showSentence && s.credit != null) ...[
                          const SizedBox(height: 8),
                          Text(s.credit!, style: text.bodySmall),
                        ],
                      ]),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton.icon(
                onPressed: () => setState(() => _showTranslation = !_showTranslation),
                icon: Icon(_showTranslation ? Icons.visibility_off : Icons.translate, size: 18),
                label: Text(_showTranslation ? '번역 가리기' : '번역 보기'),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showSentence = !_showSentence),
                icon: Icon(_showSentence ? Icons.visibility_off : Icons.visibility, size: 18),
                label: Text(_showSentence ? '문장 가리기' : '문장 보기'),
              ),
            ]),
            SizedBox(
              height: 240,
              child: FilledButton.icon(
                onPressed: _loading ? null : _speak,
                icon: const Icon(Icons.replay, size: 40),
                label: Text('Replay', style: text.headlineMedium?.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: FilledButton.tonalIcon(
                onPressed: _loading ? null : _next,
                icon: const Icon(Icons.arrow_forward, size: 28),
                label: Text('Next', style: text.titleLarge),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
