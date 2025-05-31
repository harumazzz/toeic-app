import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import 'learn_page.dart';
import 'word_page.dart';

class VocabularyPage extends HookWidget {
  const VocabularyPage({super.key});

  @override
  Widget build(final BuildContext context) {
    final pageController = usePageController();
    final currentIndex = useState(0);
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (final index) {
          currentIndex.value = index;
        },
        children: const [
          WordPage(),
          LearnPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 250),
        elevation: 4,
        onDestinationSelected: (final int index) async {
          await pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          currentIndex.value = index;
        },
        indicatorColor: Theme.of(
          context,
        ).colorScheme.secondary.withValues(alpha: 0.2),
        selectedIndex: currentIndex.value,
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Symbols.school),
            label: context.t.page.vocabulary,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.book),
            label: context.t.page.learn,
          ),
        ],
      ),
    );
  }
}
