/// LUÉN mobile app entry point. Wires Riverpod + GoRouter + LUÉN theme,
/// runs the app-config gate (force-update / maintenance) before showing any
/// real content.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'state.dart';
import 'theme.dart';
import 'screens/system_screens.dart';
import 'screens/auth_screens.dart';
import 'screens/shell_screen.dart';
import 'screens/shop_screen.dart';

void main() {
  runApp(const ProviderScope(child: LuenApp()));
}

class LuenApp extends ConsumerWidget {
  const LuenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appConfigProvider).valueOrNull;

    // Build theme from server brand overrides when available.
    Color? primary;
    Color? bg;
    if (cfg?.brandPrimaryHex != null) {
      try { primary = Color(int.parse(cfg!.brandPrimaryHex!.replaceFirst('#', '0xFF'))); } catch (_) {}
    }
    if (cfg?.brandBgHex != null) {
      try { bg = Color(int.parse(cfg!.brandBgHex!.replaceFirst('#', '0xFF'))); } catch (_) {}
    }

    return MaterialApp.router(
      title: 'LUÉN',
      debugShowCheckedModeBanner: false,
      theme: buildLuenTheme(primaryOverride: primary, bgOverride: bg),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const _Gate(child: ShellScreen())),
    GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/product/:slug', builder: (_, s) => ProductDetailScreen(slug: s.pathParameters['slug']!)),
  ],
);

/// Intercepts every authenticated route — if the backend says we're in
/// maintenance or the build is below `min_version`, show the relevant takeover.
class _Gate extends ConsumerWidget {
  const _Gate({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateAsync = ref.watch(appGateProvider);
    return gateAsync.when(
      loading: () => const SplashScreen(),
      error: (_, __) => child, // fail-open so we never lock users out on a transient API hiccup
      data: (gate) {
        if (gate.isMaintenance)  return const MaintenanceScreen();
        if (gate.isForceUpdate)  return const ForceUpdateScreen();
        return child;
      },
    );
  }
}
