import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/word.dart';

class FlashcardWidget extends HookWidget {
  const FlashcardWidget({
    required this.word,
    this.onNext,
    this.onPrevious,
    super.key,
  });

  final Word word;
  final void Function()? onNext;
  final void Function()? onPrevious;

  @override
  Widget build(final BuildContext context) {
    final isShowingFrontSide = useState(true);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );
    void toggleCard() {
      if (isShowingFrontSide.value) {
        controller.forward();
        Future.delayed(const Duration(milliseconds: 250), () {
          isShowingFrontSide.value = false;
        });
      } else {
        controller.reverse();
        Future.delayed(const Duration(milliseconds: 250), () {
          isShowingFrontSide.value = true;
        });
      }
    }

    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.4,
          child: GestureDetector(
            onTap: toggleCard,
            child: AnimatedBuilder(
              animation: controller,
              builder: (final context, final child) {
                final angle = controller.value * pi;
                final transform =
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle);
                if (angle >= pi / 2) {
                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: BackSideCard(word: word),
                  );
                } else {
                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: FrontSideCard(word: word),
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        FlashcardControls(
          onPrevious: onPrevious,
          onNext: onNext,
          onFlip: toggleCard,
          showFrontSide: isShowingFrontSide.value,
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Word>('word', word))
      ..add(ObjectFlagProperty<void Function()?>.has('onNext', onNext))
      ..add(
        ObjectFlagProperty<void Function()?>.has('onPrevious', onPrevious),
      );
  }
}

class FrontSideCard extends StatelessWidget {
  const FrontSideCard({
    required this.word,
    super.key,
  });

  final Word word;

  @override
  Widget build(final BuildContext context) => Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.4,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word.word,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          WordPronunciation(pronunciation: word.pronounce),
          const SizedBox(height: 40),
          Text(
            'Tap to flip',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Word>('word', word));
  }
}

class WordPronunciation extends StatelessWidget {
  const WordPronunciation({
    required this.pronunciation,
    super.key,
  });

  final String pronunciation;

  @override
  Widget build(final BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Symbols.volume_up, size: 24),
      const SizedBox(width: 8),
      Text(
        '/$pronunciation/',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('pronunciation', pronunciation));
  }
}

class BackSideCard extends StatelessWidget {
  const BackSideCard({
    required this.word,
    super.key,
  });

  final Word word;

  @override
  Widget build(final BuildContext context) => Transform(
    transform: Matrix4.identity()..rotateY(pi),
    alignment: Alignment.center,
    child: Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word.word,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            LevelIndicator(level: word.level),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meaning:',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word.shortMean,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (word.means != null && word.means!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Types:',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...word.means!.map(
                        (final meaning) => MeaningItem(meaning: meaning),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tap to flip back',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Word>('word', word));
  }
}

Color _getLevelColor(final int level) {
  switch (level) {
    case 1:
    case 2:
      return Colors.green;
    case 3:
    case 4:
      return Colors.blue;
    case 5:
    case 6:
      return Colors.orange;
    case 7:
    case 8:
      return Colors.deepPurple;
    default:
      return Colors.red;
  }
}

class LevelIndicator extends StatelessWidget {
  const LevelIndicator({
    required this.level,
    super.key,
  });

  final int level;

  @override
  Widget build(final BuildContext context) {
    final Color levelColor = _getLevelColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: levelColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Level $level',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('level', level));
  }
}

class MeaningItem extends StatelessWidget {
  const MeaningItem({
    required this.meaning,
    super.key,
  });

  final Meaning meaning;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meaning.kind ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (meaning.means != null && meaning.means!.isNotEmpty)
          ...meaning.means!.map(
            (final mean) => MeaningText(text: mean.mean ?? ''),
          ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Meaning>('meaning', meaning));
  }
}

class MeaningText extends StatelessWidget {
  const MeaningText({
    required this.text,
    super.key,
  });

  final String text;

  @override
  Widget build(final BuildContext context) => Text(
    '• $text',
    style: Theme.of(context).textTheme.bodyMedium,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}

class FlashcardControls extends StatelessWidget {
  const FlashcardControls({
    required this.showFrontSide,
    required this.onFlip,
    this.onPrevious,
    this.onNext,
    super.key,
  });

  final bool showFrontSide;
  final void Function() onFlip;
  final void Function()? onPrevious;
  final void Function()? onNext;

  @override
  Widget build(final BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        onPressed: onPrevious,
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Previous card',
      ),
      const SizedBox(width: 16),
      ElevatedButton.icon(
        onPressed: onFlip,
        icon: const Icon(Icons.flip),
        label: Text(showFrontSide ? 'Show Meaning' : 'Show Word'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      const SizedBox(width: 16),
      IconButton(
        onPressed: onNext,
        icon: const Icon(Icons.arrow_forward_rounded),
        tooltip: 'Next card',
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('showFrontSide', showFrontSide))
      ..add(ObjectFlagProperty<void Function()>.has('onFlip', onFlip))
      ..add(
        ObjectFlagProperty<void Function()?>.has('onPrevious', onPrevious),
      )
      ..add(ObjectFlagProperty<void Function()?>.has('onNext', onNext));
  }
}
