import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'design.dart';
import 'sentence_deck.dart';
import 'tatoeba_client.dart';

void main() => runApp(const SpeakingApp());

class SpeakingApp extends StatelessWidget {
  const SpeakingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Speaking',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
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
    final s = _deck.current;
    return Scaffold(
      appBar: AppBar(title: const Text('English Speaking')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<Map<String, String>>(
              initialValue: _voice,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '음성 모델'),
              items: [
                for (final v in _voices)
                  DropdownMenuItem(
                    value: v,
                    child: Text(v == _recording ? v['name']! : '${v['name']}  (${v['locale']})'),
                  ),
              ],
              onChanged: _selectVoice,
            ),
            const SizedBox(height: 16),
            Expanded(child: _sentenceCard(s)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Chip(
                icon: _showTranslation ? Icons.visibility_off_outlined : Icons.translate,
                label: _showTranslation ? '번역 가리기' : '번역 보기',
                onTap: () => setState(() => _showTranslation = !_showTranslation),
              ),
              _Chip(
                icon: _showSentence ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                label: _showSentence ? '문장 가리기' : '문장 보기',
                onTap: () => setState(() => _showSentence = !_showSentence),
              ),
            ]),
            const SizedBox(height: 12),
            _PressButton(
              height: 240,
              color: Palette.primary,
              pressedColor: Palette.primaryActive,
              onTap: _loading ? null : _speak,
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.replay_rounded, size: 36, color: Colors.white),
                SizedBox(width: 12),
                Text('Replay',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.625,
                        color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 12),
            _PressButton(
              height: 72,
              color: Palette.canvas,
              pressedColor: Palette.canvasSoft,
              border: Palette.hairline,
              onTap: _loading ? null : _next,
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Next',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.125,
                        color: Palette.ink)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 22, color: Palette.ink),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// White card holding the counter, sentence and translation.
  Widget _sentenceCard(Sentence s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Palette.canvas,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: Palette.hairline),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Palette.primary))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SENTENCE ${_deck.index + 1}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.125,
                      color: Palette.primary)),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      _Hideable(
                        visible: _showSentence,
                        text: s.text,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.23,
                            letterSpacing: -0.625,
                            color: Palette.ink),
                      ),
                      const SizedBox(height: 16),
                      _Hideable(
                        visible: _showTranslation,
                        text: s.translation ?? '(번역 없음)',
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Palette.inkMuted),
                      ),
                    ]),
                  ),
                ),
              ),
              if (_showSentence && s.credit != null)
                Text(s.credit!, style: const TextStyle(fontSize: 12, color: Palette.inkFaint)),
            ]),
    );
  }
}

/// Shows [text], or a soft placeholder bar of similar height while hidden.
class _Hideable extends StatelessWidget {
  const _Hideable({required this.visible, required this.text, required this.style});

  final bool visible;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (visible) return Text(text, textAlign: TextAlign.center, style: style);
    return Container(
      width: 160,
      height: (style.fontSize ?? 16) * 1.1,
      decoration: BoxDecoration(
        color: Palette.canvasSoft,
        borderRadius: BorderRadius.circular(Radii.xs),
      ),
    );
  }
}

/// Small utility toggle: white, hairline border, 8px corners.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: const BorderSide(color: Palette.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: Palette.inkSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: Palette.inkSecondary)),
          ]),
        ),
      ),
    );
  }
}

/// Full-width button with 12px corners, a pressed colour and a slight scale-down on press.
class _PressButton extends StatefulWidget {
  const _PressButton({
    required this.height,
    required this.color,
    required this.pressedColor,
    required this.onTap,
    required this.child,
    this.border,
  });

  final double height;
  final Color color;
  final Color pressedColor;
  final Color? border;
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _down ? widget.pressedColor : widget.color,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: widget.border == null ? null : Border.all(color: widget.border!),
            boxShadow: softShadow,
          ),
          child: Opacity(opacity: widget.onTap != null ? 1 : 0.5, child: widget.child),
        ),
      ),
    );
  }
}
