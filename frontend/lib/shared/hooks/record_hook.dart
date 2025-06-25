import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:record/record.dart';

class _AudioRecorderHook extends Hook<AudioRecorder> {
  const _AudioRecorderHook();

  @override
  _AudioRecorderHookState createState() => _AudioRecorderHookState();
}

class _AudioRecorderHookState
    extends HookState<AudioRecorder, _AudioRecorderHook> {
  late AudioRecorder _audioRecorder;

  @override
  void initHook() {
    _audioRecorder = AudioRecorder();
    super.initHook();
  }

  @override
  AudioRecorder build(final BuildContext context) => _audioRecorder;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}

AudioRecorder useAudioRecorder() => use(
  const _AudioRecorderHook(),
);
