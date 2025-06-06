import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../i18n/strings.g.dart';
import '../routes/app_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(final BuildContext context) => Drawer(
    child: Column(
      children: [
        DrawerHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.school,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 8),
              Text(
                context.t.app.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t.app.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _DrawerItem(
                icon: Symbols.home,
                title: context.t.page.home,
                onTap: () async {
                  Navigator.pop(context);
                  const HomeRoute().go(context);
                },
              ),
              _DrawerItem(
                icon: Symbols.quiz,
                title: context.t.drawer.practice,
                onTap: () async {
                  Navigator.pop(context);
                  // Navigate to practice page
                },
              ),
              _DrawerItem(
                icon: Symbols.library_books,
                title: context.t.drawer.vocabulary,
                onTap: () async {
                  Navigator.pop(context);
                  await const VocabularyRoute().push(context);
                },
              ),
              _DrawerItem(
                icon: Symbols.record_voice_over,
                title: context.t.drawer.speaking,
                onTap: () async {
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Symbols.edit,
                title: context.t.drawer.writing,
                onTap: () async {
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Symbols.timeline,
                title: context.t.drawer.progress,
                onTap: () async {
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Symbols.book,
                title: context.t.drawer.grammar,
                onTap: () async {
                  Navigator.pop(context);
                  await const GrammarRoute().push(context);
                },
              ),
              const Divider(),
              _DrawerItem(
                icon: Symbols.settings,
                title: context.t.drawer.settings,
                onTap: () async {
                  Navigator.pop(context);
                  await const SettingsRoute().push(context);
                },
              ),
              _DrawerItem(
                icon: Symbols.help,
                title: context.t.drawer.help,
                onTap: () async {
                  Navigator.pop(context);
                  await const HelpRoute().push(context);
                },
              ),
            ],
          ),
        ),
        const Divider(),
        Consumer(
          builder:
              (final context, final ref, final child) => _DrawerItem(
                icon: Symbols.logout,
                title: context.t.common.logout,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    const LoginRoute().go(context);
                  }
                },
              ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;

  final String title;

  final void Function() onTap;

  @override
  Widget build(final BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: onTap,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('title', title))
      ..add(ObjectFlagProperty<void Function()>.has('onTap', onTap));
  }
}

class DrawerButton extends StatelessWidget {
  const DrawerButton({super.key});

  @override
  Widget build(final BuildContext context) => Builder(
    builder:
        (final BuildContext context) => IconButton(
          icon: const Icon(Symbols.menu),
          onPressed: () async => Scaffold.of(context).openDrawer(),
        ),
  );
}
