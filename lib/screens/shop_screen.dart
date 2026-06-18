/// Shop tab + product detail screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

const _categories = ['all', 'outerwear', 'knitwear', 'shirts', 'denim', 'accessories'];

class ShopTab extends ConsumerStatefulWidget {
  const ShopTab({super.key});
  @override
  ConsumerState<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends ConsumerState<ShopTab> {
  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(_category == 'all' ? null : _category));

    return Column(children: [
      SizedBox(
        height: 50,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = _categories[i];
            final selected = _category == c;
            return GestureDetector(
              onTap: () => setState(() => _category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: selected ? LuenColors.primary : LuenColors.border),
                  color: selected ? LuenColors.primary.withOpacity(0.08) : LuenColors.surface,
                ),
                alignment: Alignment.center,
                child: Text(c.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 2, color: selected ? LuenColors.primary : LuenColors.mutedFg)),
              ),
            );
          },
        ),
      ),
      Expanded(child: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: LuenColors.primary)),
        error: (e, _) => Center(child: Text('Could not load products: $e', style: const TextStyle(color: LuenColors.mutedFg))),
        data: (items) => items.isEmpty
            ? const LuenEmpty(icon: Icons.search_off, label: 'No pieces in this category yet.')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(productsProvider),
                color: LuenColors.primary,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 24, childAspectRatio: 0.55),
                  itemCount: items.length,
                  itemBuilder: (_, i) => ProductCard(product: items[i], onTap: () => context.push('/product/${items[i].slug}')),
                ),
              ),
      )),
    ]);
  }
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});
  final String slug;
  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _size;
  String? _color;
  bool _adding = false;

  Future<void> _addToCart(Product p) async {
    setState(() => _adding = true);
    try {
      await ref.read(cartProvider.notifier).add(p.id, size: _size, color: _color);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to your bag'), backgroundColor: LuenColors.surface));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add: $e'), backgroundColor: LuenColors.danger));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProd = ref.watch(productDetailProvider(widget.slug));
    return Scaffold(
      appBar: AppBar(title: const LuenWordmark()),
      body: asyncProd.when(
        loading: () => const Center(child: CircularProgressIndicator(color: LuenColors.primary)),
        error: (e, _) => Center(child: Text('Unable to load product.\n$e', textAlign: TextAlign.center, style: const TextStyle(color: LuenColors.mutedFg))),
        data: (p) {
          _size  ??= p.sizes.isNotEmpty ? p.sizes.first : null;
          _color ??= p.colors.isNotEmpty ? p.colors.first : null;
          return SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(
                aspectRatio: 3/4,
                child: Container(color: LuenColors.surface, child: p.mainImage == null
                    ? const Icon(Icons.image_outlined, color: LuenColors.mutedFg, size: 48)
                    : CachedNetworkImage(imageUrl: p.mainImage!, fit: BoxFit.cover)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (p.category != null)
                    Text(p.category!.toUpperCase(), style: const TextStyle(color: LuenColors.primary, fontSize: 10, letterSpacing: 4.0)),
                  const SizedBox(height: 8),
                  Text(p.name, style: const TextStyle(fontFamily: GoogleFonts.playfairDisplay().fontFamily, fontSize: 28, color: LuenColors.foreground)),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (p.salePrice != null) ...[
                      Text('€${p.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: LuenColors.mutedFg, decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 12),
                    ],
                    Text('€${p.displayPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, color: LuenColors.primary, letterSpacing: 1.5)),
                  ]),
                  if (p.shortDescription != null) ...[
                    const SizedBox(height: 24),
                    Text(p.shortDescription!, style: const TextStyle(color: LuenColors.foreground, height: 1.7, fontSize: 14)),
                  ],
                  if (p.sizes.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text('SIZE', style: TextStyle(color: LuenColors.mutedFg, fontSize: 10, letterSpacing: 4)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: p.sizes.map((s) => _Chip(label: s, selected: s == _size, onTap: () => setState(() => _size = s))).toList()),
                  ],
                  if (p.colors.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('COLOUR', style: TextStyle(color: LuenColors.mutedFg, fontSize: 10, letterSpacing: 4)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: p.colors.map((c) => _Chip(label: c, selected: c == _color, onTap: () => setState(() => _color = c))).toList()),
                  ],
                  const SizedBox(height: 36),
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    onPressed: _adding ? null : () => _addToCart(p),
                    child: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ADD TO BAG'),
                  )),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? LuenColors.primary.withOpacity(0.12) : LuenColors.surface,
          border: Border.all(color: selected ? LuenColors.primary : LuenColors.border),
        ),
        child: Text(label.toUpperCase(), style: TextStyle(color: selected ? LuenColors.primary : LuenColors.foreground, fontSize: 11, letterSpacing: 2)),
      ),
    );
  }
}
