/// Shared widgets used across screens.
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'api.dart';
import 'theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tiny brand wordmark in the app bar.
class LuenWordmark extends StatelessWidget {
  const LuenWordmark({super.key});
  @override
  Widget build(BuildContext context) {
    return const Text('LUÉN', style: GoogleFonts.playfairDisplay(fontSize: 22, letterSpacing: 8.0, color: LuenColors.foreground));
  }
}

/// Product card used in the home + shop grid.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3/4,
            child: Container(
              decoration: BoxDecoration(color: LuenColors.surface, border: Border.all(color: LuenColors.border)),
              child: product.mainImage == null
                  ? const Icon(Icons.image_outlined, color: LuenColors.mutedFg, size: 32)
                  : CachedNetworkImage(
                      imageUrl: product.mainImage!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(color: LuenColors.surface),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: LuenColors.mutedFg),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(fontSize: 14, color: LuenColors.foreground)),
          const SizedBox(height: 2),
          Row(children: [
            if (product.salePrice != null) ...[
              Text('€${product.price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: LuenColors.mutedFg, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 8),
            ],
            Text('€${product.displayPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: LuenColors.primary, letterSpacing: 1.0)),
          ]),
        ],
      ),
    );
  }
}

class LuenSectionTitle extends StatelessWidget {
  const LuenSectionTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (subtitle != null) Text(subtitle!.toUpperCase(), style: const TextStyle(color: LuenColors.primary, fontSize: 10, letterSpacing: 4.0)),
        if (subtitle != null) const SizedBox(height: 6),
        Text(title, style: GoogleFonts.playfairDisplay(fontSize: 26, color: LuenColors.foreground)),
      ]),
    );
  }
}

class LuenEmpty extends StatelessWidget {
  const LuenEmpty({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: LuenColors.mutedFg, size: 48),
          const SizedBox(height: 16),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: LuenColors.mutedFg, letterSpacing: 2.0, fontSize: 12)),
        ]),
      ),
    );
  }
}
