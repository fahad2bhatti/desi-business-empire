import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/common/load_error.dart';
import '../features/common/widgets.dart';
import '../features/offline/offline_summary_sheet.dart';
import 'game_controller.dart';

/// Loads the game once for every tab, shows the offline summary and the
/// save-error banner, and holds the bottom navigation.
class GameShell extends ConsumerWidget {
  const GameShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(gameControllerProvider.select((a) => a.value?.offline), (
      prev,
      next,
    ) {
      if (next == null || identical(prev, next)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showOfflineSummary(context, next);
      });
    });

    return ref
        .watch(gameControllerProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => LoadErrorScreen(error: error),
          data: (session) => Scaffold(
            body: Column(
              children: [
                if (session.saveFailed)
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: NoticeBanner(
                        text: 'Save mein masla aaya. Jab tak theek na ho, khareed o farokht band hai.',
                        action: 'Dobara koshish',
                        onPressed: ref
                            .read(gameControllerProvider.notifier)
                            .retrySave,
                      ),
                    ),
                  ),
                Expanded(child: shell),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: 'Karobar',
                ),
              ],
            ),
          ),
        );
  }
}
