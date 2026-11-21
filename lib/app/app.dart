import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/business/business_screen.dart';
import '../features/expansion/expansion_screen.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/more/wallet_screen.dart';
import '../features/staff/staff_screen.dart';
import '../features/upgrades/upgrades_screen.dart';
import 'game_shell.dart';
import 'theme.dart';

/// Tabs: Home, Karobar, Aur. Goals joins in batch 7.
final _router = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => GameShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                // Opened from Home, so Back returns there.
                GoRoute(
                  path: 'expand/:stageId',
                  builder: (context, state) => ExpansionScreen(
                    stageId: state.pathParameters['stageId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: '/business/stall',
          routes: [
            GoRoute(
              path: '/business/:stageId',
              builder: (context, state) =>
                  BusinessScreen(stageId: state.pathParameters['stageId']!),
              routes: [
                GoRoute(
                  path: 'upgrades',
                  builder: (context, state) =>
                      UpgradesScreen(stageId: state.pathParameters['stageId']!),
                ),
                GoRoute(
                  path: 'staff',
                  builder: (context, state) =>
                      StaffScreen(stageId: state.pathParameters['stageId']!),
                ),
              ],
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
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class DesiBusinessEmpireApp extends StatelessWidget {
  const DesiBusinessEmpireApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Desi Business Empire',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    routerConfig: _router,
  );
}
