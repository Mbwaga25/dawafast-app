import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import '../providers/wishlist_provider.dart';
import 'package:afyalink/features/home/presentation/pages/product_detail_page.dart';
import 'package:afyalink/features/cart/presentation/providers/cart_provider.dart';
import 'package:afyalink/features/cart/data/models/cart_model.dart';
import 'package:afyalink/features/offers/data/models/product_model.dart';
import 'package:afyalink/features/profile/data/repositories/settings_repository.dart';

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
      ),
      body: wishlist.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final product = wishlist[index];
                return _buildWishlistItem(context, ref, product);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline, size: 80, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text('Your wishlist is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Save your favorite health products here.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Shop'),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(BuildContext context, WidgetRef ref, Product product) {
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(idOrSlug: product.slug))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: product.images.isNotEmpty
                      ? Image.network(product.images.first, fit: BoxFit.cover)
                      : Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('$symbol ${product.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite, color: AppTheme.accentTeal),
                    onPressed: () => ref.read(wishlistProvider.notifier).toggle(product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryTeal),
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(
                            CartItem(
                              productId: product.id,
                              name: product.name,
                              price: product.price,
                              image: product.images.isNotEmpty ? product.images.first : null,
                            ),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
