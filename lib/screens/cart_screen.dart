/// Cart tab — line items + checkout action.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class CartTab extends ConsumerWidget {
  const CartTab({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref, List<CartItem> items) async {
    if (items.isEmpty) return;
    // The mobile checkout flow opens a web hosted-checkout page. The Order is
    // created by the same /api/orders pipeline as the web — until the native
    // payment SDKs (Stripe Mobile + Vipps native) are wired we send the user
    // to the trusted https://houseofluen.com/checkout page where the session
    // they're already authenticated on can complete the order.
    final url = Uri.parse('https://houseofluen.com/checkout');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final auth = ref.watch(authProvider);

    if (!auth.isSignedIn) {
      return const LuenEmpty(icon: Icons.lock_outline, label: 'Sign in to view your bag.');
    }

    return cart.when(
      loading: () => const Center(child: CircularProgressIndicator(color: LuenColors.primary)),
      error: (e, _) => LuenEmpty(icon: Icons.error_outline, label: 'Could not load your bag.\n$e'),
      data: (items) {
        if (items.isEmpty) return const LuenEmpty(icon: Icons.shopping_bag_outlined, label: 'Your bag is empty.');
        final total = items.fold<double>(0, (sum, it) => sum + (it.product?.displayPrice ?? 0) * it.quantity);
        return Column(children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(cartProvider.notifier).refresh(),
              color: LuenColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final it = items[i];
                  final p = it.product;
                  return Row(children: [
                    SizedBox(width: 64, height: 80,
                      child: p?.mainImage == null
                          ? Container(color: LuenColors.surface, child: const Icon(Icons.image_outlined, color: LuenColors.mutedFg))
                          : CachedNetworkImage(imageUrl: p!.mainImage!, fit: BoxFit.cover)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p?.name ?? 'Item', style: const TextStyle(color: LuenColors.foreground, fontSize: 13, fontFamily: GoogleFonts.playfairDisplay().fontFamily)),
                      const SizedBox(height: 4),
                      Text('Qty ${it.quantity}${it.size != null ? '  ·  Size ${it.size}' : ''}', style: const TextStyle(color: LuenColors.mutedFg, fontSize: 11)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('€${((p?.displayPrice ?? 0) * it.quantity).toStringAsFixed(0)}', style: const TextStyle(color: LuenColors.primary, fontSize: 12)),
                      const SizedBox(height: 4),
                      IconButton(onPressed: () => ref.read(cartProvider.notifier).remove(it.id), icon: const Icon(Icons.close, color: LuenColors.mutedFg, size: 16), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ]),
                  ]);
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(color: LuenColors.surface, border: Border(top: BorderSide(color: LuenColors.border))),
            child: SafeArea(
              top: false,
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('TOTAL', style: TextStyle(color: LuenColors.mutedFg, fontSize: 11, letterSpacing: 4)),
                  Text('€${total.toStringAsFixed(0)}', style: const TextStyle(color: LuenColors.primary, fontSize: 18, letterSpacing: 1.5)),
                ]),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _checkout(context, ref, items), child: const Text('CHECKOUT'))),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}
