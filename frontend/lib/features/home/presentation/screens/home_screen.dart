import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/widgets/app_drawer.dart' hide DrawerButton;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/home_loading.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is AuthInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authControllerProvider.notifier).getCurrentUser();
      });
    }
    final isDrawerEnabled =
        authState is! AuthLoading && authState is! AuthInitial;
    return Scaffold(
      drawer: isDrawerEnabled ? const AppDrawer() : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: isDrawerEnabled ? const DrawerButton() : null,
            title: Text(context.t.page.home),
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverFillRemaining(
              child: Center(
                child: switch (authState) {
                  AuthInitial() || AuthLoading() => const HomeLoading(),
                  AuthAuthenticated() ||
                  AuthUnauthenticated() ||
                  AuthError() => const _CustomModuleOpener(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomModuleOpener extends StatelessWidget {
  const _CustomModuleOpener();

  @override
  Widget build(final BuildContext context) => Builder(
    builder:
        (
          final BuildContext context,
        ) => FilledButton.tonal(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width * 0.1,
            ),
          ),
          child: Icon(
            Symbols.category,
            size: MediaQuery.sizeOf(context).width * 0.25,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(
              alpha: 0.84,
            ),
          ),
          onPressed: () async {
            Scaffold.of(context).openDrawer();
          },
        ),
  );
}
