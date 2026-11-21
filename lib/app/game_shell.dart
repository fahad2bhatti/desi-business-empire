import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/strings.dart';
import '../features/common/load_error.dart';
import '../features/common/money_header.dart';
import '../features/common/widgets.dart';
import '../features/offline/offline_summary_sheet.dart';
import '../features/onboarding/tutorial.dart';
import '../features/onboarding/welcome_screen.dart';
import 'game_controller.dart';
import 'prefs.dart';
import 'theme.dart';

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
      return WelcomeScreen(onDone: () => shell.goBranch(0));
    }
    final engine = ref.read(gameControllerProvider.notifier).engine;

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: MoneyHeader(
              empireName: settings.businessName ?? S.defaultName,
              cashPaisa: session.state.cashPaisa,
              incomePaisaPerSec: engine.incomePerSec(session.state),
              netWorthPaisa: engine.netWorth(session.state),
            ),
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
                onPressed: ref.read(gameControllerProvider.notifier).retrySave,
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: S.tabEmpire,
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: S.tabBusinesses,
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: S.tabProperty,
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_open),
            label: S.tabMore,
          ),
        ],
      ),
    );
  }
}
