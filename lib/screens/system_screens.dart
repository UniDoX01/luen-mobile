/// System screens — splash, maintenance, force update.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LuenColors.background,
      body: Center(child: LuenWordmark()),
    );
  }
}

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appConfigProvider).valueOrNull;
    return Scaffold(
      backgroundColor: LuenColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            const LuenWordmark(),
            const SizedBox(height: 48),
            const Icon(Icons.coffee_outlined, color: LuenColors.primary, size: 40),
            const SizedBox(height: 24),
            Text(cfg?.maintenanceTitle ?? 'We will be right back',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: GoogleFonts.playfairDisplay().fontFamily, fontSize: 26, color: LuenColors.foreground)),
            const SizedBox(height: 12),
            Text(cfg?.maintenanceMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: LuenColors.mutedFg, fontSize: 13, height: 1.6)),
          ]),
        ),
      ),
    );
  }
}

class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(appGateProvider).valueOrNull;
    return Scaffold(
      backgroundColor: LuenColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const LuenWordmark(),
            const SizedBox(height: 48),
            const Icon(Icons.system_update_alt, color: LuenColors.primary, size: 40),
            const SizedBox(height: 24),
            const Text('A new edition is required',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: GoogleFonts.playfairDisplay().fontFamily, fontSize: 26, color: LuenColors.foreground)),
            const SizedBox(height: 12),
            const Text(
              'Please update LUÉN to continue. This release contains required improvements.',
              textAlign: TextAlign.center,
              style: TextStyle(color: LuenColors.mutedFg, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final url = gate?.storeUrl;
                if (url != null && url.isNotEmpty) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('UPDATE NOW'),
            ),
          ]),
        ),
      ),
    );
  }
}
