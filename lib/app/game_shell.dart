import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/common/load_error.dart';
import '../features/common/widgets.dart';
import '../features/offline/offline_summary_sheet.dart';
import '../features/onboarding/tutorial.dart';
import '../features/onboarding/welcome_screen.dart';
import 'game_controller.dart';
import 'prefs.dart';

/// Loads the game once for every tab, shows the welcome screen on first
/// launch, the offline summary and the save-error banner, moves the
/// tutorial forward, and holds the bottom navigation.
class GameShell extends ConsumerWidget {
  const GameShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(gameControllerProvider.select((a) => a.value?.offline), (
      prev,
      next,
    ) {
      if (next == null || identical(prev, next)) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showOfflineSummary(context, next);
        }
      });
    });

    ref.listen(gameControllerProvider.select((a) => a.value?.state.revision), (
      before,
      after,
    ) {
      final prefs = ref.read(prefsProvider).value;
      final game = ref.read(gameControllerProvider).value;
      if (prefs == null || game == null) {
        return;
      }
      final step = prefs.tutorialStep;
      if (step == Tutorial.welcome || step == Tutorial.done) {
        return;
      }
      final starter = ref
          .read(gameControllerProvider.notifier)
          .engine
          .config
          .stages
          .first
          .id;
      final next = advanceTutorial(step, game.state, starter);
      if (next != step) {
        ref.read(prefsProvider.notifier).setTutorialStep(next);
        if (next == Tutorial.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Shabaash! Tutorial mukammal. Ab apna karobar barhayein.',
              ),
            ),
          );
        }
      }
    });

    final prefs = ref.watch(prefsProvider);
    final game = ref.watch(gameControllerProvider);
    if (game.hasError) {
      return LoadErrorScreen(error: game.error!);
    }
    if (prefs.hasError) {
      return LoadErrorScreen(error: prefs.error!);
    }
    final session = game.value;
    final settings = prefs.value;
    if (session == null || settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (settings.businessName == null) {
      return WelcomeScreen(onDone: () => shell.goBranch(1));
    }

    return Scaffold(
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
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_open),
            label: 'Aur',
          ),
        ],
      ),
    );
  }
}
