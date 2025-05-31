import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../i18n/strings.g.dart';
import '../../../domain/entities/word.dart';

class CollapsibleActionButton extends HookWidget {
  const CollapsibleActionButton({
    required this.word,
    super.key,
  });

  final Word word;

  @override
  Widget build(final BuildContext context) {
    final isExpanded = useState(false);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    useEffect(() {
      if (isExpanded.value) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [isExpanded.value]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: animationController,
          builder:
              (final context, final child) => Transform.scale(
                scale: animationController.value,
                child: Opacity(
                  opacity: animationController.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.extended(
                        onPressed: () async {
                          // TODO(dev): Implement save/bookmark action
                        },
                        icon: const Icon(Symbols.bookmark),
                        label: Text(context.t.common.save),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.9),
                        heroTag: 'save',
                      ),
                      const SizedBox(height: 16),
                      FloatingActionButton.extended(
                        onPressed: () async {
                          // TODO(dev): Implement learn action
                        },
                        icon: const Icon(Symbols.school),
                        label: Text(context.t.common.learn),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.9),
                        heroTag: 'learn',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
        ),
        FloatingActionButton(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.9),
          onPressed: () async {
            isExpanded.value = !isExpanded.value;
          },
          heroTag: 'main',
          child: AnimatedRotation(
            turns: isExpanded.value ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(isExpanded.value ? Symbols.close : Symbols.add),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Word>('word', word));
  }
}
