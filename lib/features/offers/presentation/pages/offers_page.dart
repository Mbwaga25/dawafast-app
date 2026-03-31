import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/offers/data/models/product_model.dart';
import 'package:app/features/offers/data/repositories/marketplace_repository.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/home/presentation/pages/product_detail_page.dart';
import 'package:app/features/cart/presentation/providers/cart_provider.dart';
import 'package:app/features/cart/data/models/cart_model.dart';
import 'package:app/features/profile/presentation/providers/wishlist_provider.dart';

class OffersPage extends ConsumerWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Promotional Banner
            Container(
              margin: const EdgeInsets.all(16),
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF1CB5AC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(Icons.local_offer, size: 150, color: Colors.white.withOpacity(0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NEW USER OFFER',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Flat 25% OFF\non Medicines',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use Code: DAWA25',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Categories
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shop by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('View All', style: TextStyle(color: AppTheme.primaryBlue)),
                ],
              ),
            ),
            
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                children: [
                  _buildCategoryCircle('Vitamins', Icons.health_and_safety, Colors.orange),
                  _buildCategoryCircle('Skincare', Icons.face, Colors.pink),
                  _buildCategoryCircle('Fitness', Icons.fitness_center, Colors.blue),
                  _buildCategoryCircle('Baby Care', Icons.child_care, Colors.green),
                  _buildCategoryCircle('Personal', Icons.person, Colors.purple),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Deals Grid
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Top Deals on Health & Wellness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) return _buildMockGrid(context, ref);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildDealItem(context, ref, product);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildMockGrid(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockGrid(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return _buildDealItem(context, ref, Product(
          id: 'mock_$index',
          name: 'Wellness Product ${index + 1}',
          slug: 'mock-product',
          price: 299,
          originalPrice: 499,
          images: [],
        ));
      },
    );
  }

  Widget _buildCategoryCircle(String label, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDealItem(BuildContext context, WidgetRef ref, Product product) {
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(idOrSlug: product.slug)));
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundWhite,
                      ),
                      child: product.images.isNotEmpty
                          ? Image.network(product.images.first, fit: BoxFit.cover, width: double.infinity)
                          : Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isFavorite = ref.watch(wishlistProvider.notifier).isFavorite(product.id);
                        return Container(
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                          child: IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: AppTheme.accentBlue,
                            ),
                            onPressed: () => ref.read(wishlistProvider.notifier).toggle(product),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.discountPercentage > 0)
                            Text('${product.discountPercentage.toInt()}% OFF', 
                              style: const TextStyle(fontSize: 12, color: AppTheme.accentBlue, fontWeight: FontWeight.bold),
                            ),
                          Text('$symbol ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryBlue, size: 20),
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
          ],
        ),
      ),
    );
  }
}
