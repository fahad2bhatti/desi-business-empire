import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/strings.dart';
import '../features/businesses/businesses_screen.dart';
import '../features/empire/empire_screen.dart';
import '../features/more/more_screen.dart';
import '../features/more/wallet_screen.dart';
import '../features/property/property_screen.dart';
import 'game_shell.dart';
import 'theme.dart';

/// Tabs: Empire, Businesses, Property, More.
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
              builder: (context, state) => const PropertyScreen(),
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
    title: S.appName,
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    routerConfig: _router,
  );
}
