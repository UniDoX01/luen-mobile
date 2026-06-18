/// Root shell with bottom navigation: Home · Shop · Concierge · Cart · Account
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home_screen.dart';
import 'shop_screen.dart';
import 'cart_screen.dart';
import 'account_screen.dart';
import 'concierge_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});
  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(appConfigProvider).valueOrNull;
    final conciergeEnabled = cfg?.isEnabled('concierge_enabled') ?? true;

    final tabs = <Widget>[
      const HomeTab(),
      const ShopTab(),
      if (conciergeEnabled) const ConciergeTab(),
      const CartTab(),
      const AccountTab(),
    ];
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'HOME'),
      const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'SHOP'),
      if (conciergeEnabled) const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'CONCIERGE'),
      const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'CART'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'ACCOUNT'),
    ];

    return Scaffold(
      appBar: AppBar(title: const LuenWordmark()),
      body: IndexedStack(index: _idx, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        items: items,
        currentIndex: _idx >= items.length ? 0 : _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}
