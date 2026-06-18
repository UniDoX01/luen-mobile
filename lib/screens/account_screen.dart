/// Account tab — profile, orders, VIP badge, sign out, security links.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final flags = ref.watch(appConfigProvider).valueOrNull;

    if (!auth.isSignedIn) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const LuenWordmark(),
          const SizedBox(height: 24),
          const Text('Sign in to your LUÉN account',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(color: LuenColors.foreground, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.push('/login'), child: const Text('SIGN IN')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => context.push('/signup'), child: const Text('CREATE ACCOUNT')),
        ]),
      );
    }

    final user = auth.user!;
    final orders = ref.watch(ordersProvider);
    final vipEnabled     = flags?.isEnabled('vip_section_enabled') ?? true;
    final loyaltyEnabled = flags?.isEnabled('loyalty_enabled') ?? true;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ordersProvider);
        await ref.read(authProvider.notifier)._bootstrap();
      },
      color: LuenColors.primary,
      child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), children: [
        _ProfileCard(user: user, isVipVisible: vipEnabled),
        const SizedBox(height: 24),
        _SectionHeader('Orders'),
        orders.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: LuenColors.primary))),
          error: (e, _) => Text('Could not load orders: $e', style: const TextStyle(color: LuenColors.mutedFg)),
          data: (list) => list.isEmpty
              ? const LuenEmpty(icon: Icons.receipt_long_outlined, label: 'No orders yet.')
              : Column(children: list.take(5).map((o) => _OrderRow(order: o)).toList()),
        ),
        const SizedBox(height: 12),
        if (vipEnabled && user.isVip) ...[
          _SectionHeader('VIP Private Access'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('You have private-client access to LUÉN. Concierge appointments and members-only releases are available here.',
              style: TextStyle(color: LuenColors.mutedFg, fontSize: 12, height: 1.6)),
          ),
        ],
        if (loyaltyEnabled) ...[
          _SectionHeader('Loyalty'),
          _ActionRow(icon: Icons.workspace_premium_outlined, label: 'Rewards & tier', onTap: () => launchUrl(Uri.parse('https://houseofluen.com/dashboard/loyalty'), mode: LaunchMode.externalApplication)),
        ],
        _SectionHeader('Security'),
        _ActionRow(icon: Icons.shield_outlined, label: 'Two-factor authentication',
          onTap: () => launchUrl(Uri.parse('https://houseofluen.com/dashboard/settings'), mode: LaunchMode.externalApplication)),
        _ActionRow(icon: Icons.person_outline, label: 'Profile & addresses',
          onTap: () => launchUrl(Uri.parse('https://houseofluen.com/dashboard/profile'), mode: LaunchMode.externalApplication)),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) context.go('/');
          },
          child: const Text('SIGN OUT'),
        ),
      ]),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.isVipVisible});
  final User user;
  final bool isVipVisible;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: LuenColors.surface, border: Border.all(color: LuenColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isVipVisible && user.isVip) Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: LuenColors.primary.withOpacity(0.12), border: Border.all(color: LuenColors.primary.withOpacity(0.5))),
          child: const Text('VIP MEMBER', style: TextStyle(color: LuenColors.primary, fontSize: 9, letterSpacing: 3)),
        ),
        if (isVipVisible && user.isVip) const SizedBox(height: 12),
        Text(user.name ?? user.email, style: GoogleFonts.playfairDisplay(fontSize: 22, color: LuenColors.foreground)),
        const SizedBox(height: 4),
        Text(user.email, style: const TextStyle(color: LuenColors.mutedFg, fontSize: 12)),
        if (user.totalSpent > 0) ...[
          const SizedBox(height: 12),
          Text('Lifetime spend  €${user.totalSpent.toStringAsFixed(0)}', style: const TextStyle(color: LuenColors.primary, fontSize: 12)),
        ],
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(color: LuenColors.primary, fontSize: 10, letterSpacing: 4)),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: LuenColors.surface, border: Border.all(color: LuenColors.border)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('#${order.orderNumber}', style: const TextStyle(color: LuenColors.foreground, fontSize: 13)),
          const SizedBox(height: 2),
          Text(order.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: order.isPickup ? LuenColors.primary : LuenColors.mutedFg, fontSize: 10, letterSpacing: 2)),
        ])),
        Text('€${order.total.toStringAsFixed(0)}', style: const TextStyle(color: LuenColors.primary, fontSize: 13)),
      ]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: LuenColors.border, width: 0.5))),
        child: Row(children: [
          Icon(icon, color: LuenColors.mutedFg, size: 18),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: LuenColors.foreground, fontSize: 13))),
          const Icon(Icons.chevron_right, color: LuenColors.mutedFg, size: 18),
        ]),
      ),
    );
  }
}
