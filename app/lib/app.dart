import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/countries/presentation/countries_screen.dart';
import 'features/home/presentation/home_screen.dart';

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/countries', builder: (_, _) => const CountriesScreen()),
  ],
);

class VpnApp extends StatelessWidget {
  const VpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VPN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
