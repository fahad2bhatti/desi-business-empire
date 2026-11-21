import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/stall/stall_screen.dart';
import 'theme.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StallScreen()),
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
