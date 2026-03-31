import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/offers/data/repositories/marketplace_repository.dart';
import 'package:app/features/offers/data/models/product_model.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/cart/presentation/providers/cart_provider.dart';
import 'package:app/features/cart/presentation/pages/cart_page.dart';
import 'package:app/features/cart/data/models/cart_model.dart';
import 'package:app/features/profile/presentation/providers/wishlist_provider.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';

class ProductDetailPage extends ConsumerWidget {
  final String idOrSlug;

  const ProductDetailPage({super.key, required this.idOrSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(idOrSlug));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isFav = ref.watch(wishlistProvider.notifier).isFavorite(idOrSlug); // Using idOrSlug as ID here for simplicity
              return IconButton(
                onPressed: () {
                  final product = ref.read(productDetailProvider(idOrSlug)).value;
                  if (product != null) {
                    ref.read(wishlistProvider.notifier).toggle(product);
                  }
                },
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: AppTheme.accentPink),
              );
            },
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
          Consumer(
            builder: (context, ref, child) {
              final cartCount = ref.watch(cartProvider).items.length;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) return const Center(child: Text('Product not found'));
          return _buildProductContent(context, ref, product);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: productAsync.value != null 
        ? _buildBottomAction(context, ref, productAsync.value!)
        : null,
    );
  }

  Widget _buildProductContent(BuildContext context, WidgetRef ref, Product product) {
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          SizedBox(
            height: 300,
            width: double.infinity,
            child: product.images.isEmpty
              ? Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover)
              : PageView.builder(
                  itemCount: product.images.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: product.images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppTheme.backgroundGray),
                      errorWidget: (context, url, error) => Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover),
                    );
                  },
                ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.categoryName ?? 'Health',
                    style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                // Name and Price
                Text(product.name, style: AppTheme.headingStyle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$symbol ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                    ),
                    const SizedBox(width: 12),
                    if ((product.rating ?? 0) > 0) ...[
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${product.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),

                const SizedBox(height: 24),
                const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  product.description ?? 'No description available for this product.',
                  style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
                ),

                const SizedBox(height: 32),
                
                // Extra info section
                _buildInfoTile(Icons.verified_user_outlined, '100% Genuine Product'),
                _buildInfoTile(Icons.local_shipping_outlined, 'Fast Delivery within 24 hours'),
                _buildInfoTile(Icons.assignment_return_outlined, 'Easy 7-day returns'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryTeal),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, WidgetRef ref, Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.backgroundGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryTeal),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
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
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      action: SnackBarAction(
                        label: 'VIEW CART',
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
