/// Home tab — soft update banner + featured products.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(appGateProvider).valueOrNull;
    final productsAsync = ref.watch(productsProvider(null));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(productsProvider),
      color: LuenColors.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (gate?.isSoftUpdate ?? false) _SoftUpdateBanner(gate: gate!),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('NEW COLLECTION 2026', style: TextStyle(color: LuenColors.primary, fontSize: 10, letterSpacing: 6.0)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('LUÉN', style: GoogleFonts.playfairDisplay(fontSize: 56, letterSpacing: 4.0, color: LuenColors.foreground)),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Where luxury meets artistry. Pieces crafted for those who demand the exceptional.',
              style: TextStyle(color: LuenColors.mutedFg, fontSize: 13, height: 1.6)),
          ),
          const LuenSectionTitle('Featured', subtitle: 'New arrivals'),
          productsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: LuenColors.primary))),
            error: (e, _) => Padding(padding: const EdgeInsets.all(32), child: Text('Could not load products.\n$e', style: const TextStyle(color: LuenColors.mutedFg))),
            data: (items) => items.isEmpty
                ? const LuenEmpty(icon: Icons.shopping_bag_outlined, label: 'New pieces arriving soon.')
                : GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 24, childAspectRatio: 0.55),
                    itemCount: items.length > 6 ? 6 : items.length,
                    itemBuilder: (_, i) => ProductCard(product: items[i], onTap: () => context.push('/product/${items[i].slug}')),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SoftUpdateBanner extends StatelessWidget {
  const _SoftUpdateBanner({required this.gate});
  final AppGateState gate;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: LuenColors.primary.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        const Icon(Icons.system_update_alt, color: LuenColors.primary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(gate.config.updateBannerTitle, style: const TextStyle(color: LuenColors.foreground, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(gate.config.updateBannerMessage, style: const TextStyle(color: LuenColors.mutedFg, fontSize: 11, height: 1.4)),
          ]),
        ),
        TextButton(
          onPressed: () => launchUrl(Uri.parse(gate.storeUrl), mode: LaunchMode.externalApplication),
          child: const Text('UPDATE', style: TextStyle(color: LuenColors.primary, fontSize: 10, letterSpacing: 2)),
        ),
      ]),
    );
  }
}
