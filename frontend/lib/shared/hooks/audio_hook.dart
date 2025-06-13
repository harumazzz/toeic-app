import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class _AudioPlayerHook extends Hook<AudioPlayer> {
  const _AudioPlayerHook();

  @override
  _AudioPlayerHookState createState() => _AudioPlayerHookState();
}

class _AudioPlayerHookState extends HookState<AudioPlayer, _AudioPlayerHook> {
  late AudioPlayer _audioPlayer;

  @override
  void initHook() {
    _audioPlayer = AudioPlayer();
    super.initHook();
  }

  @override
  AudioPlayer build(final BuildContext context) => _audioPlayer;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

AudioPlayer useAudioPlayer() => use(
  const _AudioPlayerHook(),
);
