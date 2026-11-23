import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/strings.dart';
import '../features/common/load_error.dart';
import '../features/common/widgets.dart';
import '../features/offline/offline_summary_sheet.dart';
import '../features/onboarding/tutorial.dart';
import '../features/onboarding/welcome_screen.dart';
import '../domain/economy/goals.dart';
import 'game_controller.dart';
import 'leaderboard.dart';
import 'prefs.dart';
import 'theme.dart';

/// Empire sits in the middle of the five tabs.
const _empireTab = 2;

/// Loads the game once for every tab, shows the welcome screen on first
/// launch, the money header, the offline summary and the save-error
/// banner, moves the tutorial forward, and holds the bottom navigation.
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

    // Once a day, send the score on the first launch of that day.
    ref.listen(gameControllerProvider.select((a) => a.hasValue), (
      before,
      loaded,
    ) {
      if (loaded) {
        ref.read(leaderboardSyncProvider).send(manual: false);
      }
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
      final next = advanceTutorial(step, game.state);
      if (next != step) {
        ref.read(prefsProvider.notifier).setTutorialStep(next);
        if (next == Tutorial.done) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text(S.tutorialDone)));
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
      return WelcomeScreen(onDone: () => shell.goBranch(_empireTab));
    }
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final ready = engine.claimableGoals(session.state);

    final overlay = context.palette.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Column(
          children: [
            // Net worth and income live on the Empire tab only.
            const SafeArea(
              bottom: false,
              child: SizedBox(height: AppSpacing.s8),
            ),
            if (session.saveFailed)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s8,
                  AppSpacing.s16,
                  0,
                ),
                child: NoticeBanner(
                  text: S.saveProblem,
                  action: S.tryAgain,
                  onPressed: ref
                      .read(gameControllerProvider.notifier)
                      .retrySave,
                ),
              ),
            if (session.restoredFromBackup)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s8,
                  AppSpacing.s16,
                  0,
                ),
                child: NoticeBanner(text: S.restoredFromBackup),
              ),
            Expanded(child: shell),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: S.tabBusinesses,
            ),
            const NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment),
              label: S.tabProperty,
            ),
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: S.tabEmpire,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: ready > 0,
                label: Text('$ready'),
                child: const Icon(Icons.emoji_events_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: ready > 0,
                label: Text('$ready'),
                child: const Icon(Icons.emoji_events),
              ),
              label: S.tabGoals,
              tooltip: ready > 0 ? S.goalsReady(ready) : null,
            ),
            const NavigationDestination(
              icon: Icon(Icons.menu),
              selectedIcon: Icon(Icons.menu_open),
              label: S.tabMore,
            ),
          ],
        ),
      ),
    );
  }
}
