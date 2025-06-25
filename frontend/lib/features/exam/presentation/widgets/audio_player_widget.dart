import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/hooks/audio_hook.dart';

class AudioHeaderWidget extends StatelessWidget {
  const AudioHeaderWidget({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(final BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Symbols.audiotrack,
          color: Colors.blue,
          size: 20,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            Text(
              context.t.exam.audio.audioFile,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

class AudioProgressWidget extends StatelessWidget {
  const AudioProgressWidget({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<double> onSeek;

  String _formatDuration(final Duration duration) {
    String twoDigits(final int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(final BuildContext context) => Column(
    children: [
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Colors.blue,
          inactiveTrackColor: Colors.blue.withValues(alpha: 0.2),
          thumbColor: Colors.blue,
          overlayColor: Colors.blue.withValues(alpha: 0.2),
          trackHeight: 4,
        ),
        child: Slider(
          value:
              duration.inMilliseconds > 0
                  ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                    0.0,
                    1.0,
                  )
                  : 0.0,
          onChanged: duration.inMilliseconds > 0 ? onSeek : null,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(position),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _formatDuration(duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Duration>('position', position))
      ..add(DiagnosticsProperty<Duration>('duration', duration))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has('onSeek', onSeek),
      );
  }
}

class AudioControlsWidget extends StatelessWidget {
  const AudioControlsWidget({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.canStop,
    required this.onPlayPause,
    required this.onStop,
    required this.onSpeedChange,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool canStop;
  final void Function() onPlayPause;
  final void Function() onStop;
  final ValueChanged<double> onSpeedChange;

  @override
  Widget build(final BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        onPressed: canStop ? onStop : null,
        icon: Icon(
          Symbols.stop,
          color: canStop ? Colors.blue : Colors.grey,
        ),
        tooltip: context.t.exam.audio.stop,
      ),
      const SizedBox(width: 8),
      DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IconButton(
          onPressed: isLoading ? null : onPlayPause,
          icon:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Icon(
                    isPlaying ? Symbols.pause : Symbols.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
          tooltip:
              isPlaying
                  ? context.t.exam.audio.pause
                  : context.t.exam.audio.play,
        ),
      ),
      const SizedBox(width: 8),
      PopupMenuButton<double>(
        icon: const Icon(
          Symbols.speed,
          color: Colors.blue,
        ),
        tooltip: context.t.exam.audio.playbackSpeed,
        onSelected: onSpeedChange,
        itemBuilder:
            (final context) => [
              const PopupMenuItem(value: 0.5, child: Text('0.5x')),
              const PopupMenuItem(value: 1, child: Text('1.0x')),
              const PopupMenuItem(value: 1.25, child: Text('1.25x')),
              const PopupMenuItem(value: 1.5, child: Text('1.5x')),
              const PopupMenuItem(value: 2, child: Text('2.0x')),
            ],
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('isPlaying', isPlaying))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(DiagnosticsProperty<bool>('canStop', canStop))
      ..add(
        ObjectFlagProperty<void Function()>.has('onPlayPause', onPlayPause),
      )
      ..add(ObjectFlagProperty<void Function()>.has('onStop', onStop))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has(
          'onSpeedChange',
          onSpeedChange,
        ),
      );
  }
}

class AudioPlayerWidget extends HookConsumerWidget {
  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.title,
  });

  final String audioUrl;
  final String title;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final audioPlayer = useAudioPlayer();

    final isPlaying = useState(false);
    final position = useState(Duration.zero);
    final duration = useState(Duration.zero);
    final isLoading = useState(false);
    final hasLoaded = useState(false);

    Future<void> playPause() async {
      if (isLoading.value) {
        return;
      }
      isLoading.value = true;

      try {
        if (isPlaying.value) {
          await audioPlayer.pause();
          isPlaying.value = false;
        } else {
          if (!hasLoaded.value) {
            await audioPlayer.setSource(UrlSource(audioUrl));
            hasLoaded.value = true;
          }
          await audioPlayer.resume();
          isPlaying.value = true;
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: '${context.t.exam.audio.errorPlaying}: $e',
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> stop() async {
      await audioPlayer.stop();
      isPlaying.value = false;
      position.value = Duration.zero;
    }

    Future<void> seek(final double value) async {
      final newPosition = Duration(
        milliseconds: (value * duration.value.inMilliseconds).round(),
      );
      await audioPlayer.seek(newPosition);
      position.value = newPosition;
    }

    Future<void> changeSpeed(final double speed) async {
      try {
        await audioPlayer.setPlaybackRate(speed);
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: '${context.t.exam.audio.errorChangingSpeed}: $e',
          );
        }
      }
    }

    useEffect(() {
      final playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((
        final state,
      ) {
        isPlaying.value = state == PlayerState.playing;
      });

      final positionSubscription = audioPlayer.onPositionChanged.listen((
        final pos,
      ) {
        position.value = pos;
      });

      final durationSubscription = audioPlayer.onDurationChanged.listen((
        final dur,
      ) {
        duration.value = dur;
      });

      final completionSubscription = audioPlayer.onPlayerComplete.listen((_) {
        isPlaying.value = false;
        position.value = Duration.zero;
      });

      return () {
        playerStateSubscription.cancel();
        positionSubscription.cancel();
        durationSubscription.cancel();
        completionSubscription.cancel();
      };
    }, [audioPlayer]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AudioHeaderWidget(title: title),
          const SizedBox(height: 16),
          AudioProgressWidget(
            position: position.value,
            duration: duration.value,
            onSeek: seek,
          ),
          const SizedBox(height: 16),
          AudioControlsWidget(
            isPlaying: isPlaying.value,
            isLoading: isLoading.value,
            canStop: position.value > Duration.zero,
            onPlayPause: playPause,
            onStop: stop,
            onSpeedChange: changeSpeed,
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('audioUrl', audioUrl))
      ..add(StringProperty('title', title));
  }
}
