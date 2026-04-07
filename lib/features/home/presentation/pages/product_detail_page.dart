import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/offers/data/repositories/marketplace_repository.dart';
import 'package:afyalink/features/offers/data/models/product_model.dart';
import 'package:afyalink/features/profile/data/repositories/settings_repository.dart';
import 'package:afyalink/features/cart/presentation/providers/cart_provider.dart';
import 'package:afyalink/features/cart/presentation/pages/cart_page.dart';
import 'package:afyalink/features/cart/presentation/pages/checkout_page.dart';
import 'package:afyalink/features/cart/data/models/cart_model.dart';
import 'package:afyalink/features/profile/presentation/providers/wishlist_provider.dart';
import 'package:afyalink/features/offers/presentation/providers/compare_provider.dart';
import 'package:afyalink/features/offers/presentation/pages/compare_page.dart';

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
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: AppTheme.accentTeal),
              );
            },
          ),
          IconButton(
            onPressed: () {
              final product = ref.read(productDetailProvider(idOrSlug)).value;
              if (product != null) {
                ref.read(compareProvider.notifier).addProduct(product, context);
              }
            },
            icon: const Icon(Icons.compare_arrows_outlined),
          ),
          Consumer(
            builder: (context, ref, child) {
              final compareCount = ref.watch(compareProvider).length;
              if (compareCount > 0) {
                 return IconButton(
                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparePage())),
                   icon: const Icon(Icons.layers_outlined, color: AppTheme.primaryTeal),
                 );
              }
              return const SizedBox();
            }
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
                          color: AppTheme.accentTeal,
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
                      placeholder: (context, url) => Container(color: AppTheme.backgroundWhite),
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
                const SizedBox(height: 16),

                if (product.categorySlug != null)
                  _buildRelatedProducts(context, ref, product.categorySlug!, product.id),

                if (product.brandSlug != null)
                  _buildSimilarBrands(context, ref, product.brandSlug!, product.id),
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
    final CartItem cartItem = CartItem(
      productId: product.id,
      name: product.name,
      price: product.price,
      image: product.images.isNotEmpty ? product.images.first : null,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(cartItem);
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
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      side: const BorderSide(color: AppTheme.primaryTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(cartItem);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedProducts(BuildContext context, WidgetRef ref, String categorySlug, String currentProductId) {
    final asyncProducts = ref.watch(relatedProductsProvider(categorySlug));
    return _buildHorizontalList(context, 'Related Products', asyncProducts, currentProductId);
  }

  Widget _buildSimilarBrands(BuildContext context, WidgetRef ref, String brandSlug, String currentProductId) {
    final asyncProducts = ref.watch(similarBrandsProvider(brandSlug));
    return _buildHorizontalList(context, 'More from this Brand', asyncProducts, currentProductId);
  }

  Widget _buildHorizontalList(BuildContext context, String title, AsyncValue<List<Product>> asyncProducts, String currentProductId) {
    return asyncProducts.when(
      data: (products) {
        final filtered = products.where((p) => p.id != currentProductId).toList();
        if (filtered.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(context, filtered[index]);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(idOrSlug: product.slug)));
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: product.images.isNotEmpty 
                      ? CachedNetworkImage(
                          imageUrl: product.images.first, 
                          fit: BoxFit.cover,
                          errorWidget: (context, url, err) => Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover),
                        )
                      : Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('Tsh ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryTeal)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
