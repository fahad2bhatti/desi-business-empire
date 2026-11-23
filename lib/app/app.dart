import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/strings.dart';
import '../features/businesses/businesses_screen.dart';
import '../features/empire/empire_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/more/more_screen.dart';
import '../features/more/leaderboard_screen.dart';
import '../features/more/wallet_screen.dart';
import '../features/property/property_screen.dart';
import 'game_shell.dart';
import 'prefs.dart';
import 'theme.dart';

/// Tabs: Empire, Businesses, Assets, Goals, More.
final _router = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => GameShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const EmpireScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/businesses',
              builder: (context, state) => const BusinessesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/property',
              builder: (context, state) {
                final tab = state.uri.queryParameters['tab'];
                return PropertyScreen(key: ValueKey(tab), initialTab: tab);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/goals',
              builder: (context, state) => const GoalsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              builder: (context, state) => const MoreScreen(),
              routes: [
                GoRoute(
                  path: 'wallet',
                  builder: (context, state) => const WalletScreen(),
                ),
                GoRoute(
                  path: 'leaderboard',
                  builder: (context, state) => const LeaderboardScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

final _light = buildAppTheme(AppPalette.light);
final _dark = buildAppTheme(AppPalette.dark);

class DesiBusinessEmpireApp extends ConsumerWidget {
  const DesiBusinessEmpireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: S.appName,
    debugShowCheckedModeBanner: false,
    theme: _light,
    darkTheme: _dark,
    themeMode: ref.watch(
      prefsProvider.select((a) => a.value?.themeMode ?? ThemeMode.dark),
    ),
    routerConfig: _router,
  );
}
