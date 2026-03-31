import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/offers/data/models/product_model.dart';
import 'package:app/features/offers/data/repositories/marketplace_repository.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/offers/presentation/pages/category_page.dart';
import 'package:app/features/home/presentation/pages/product_detail_page.dart';
import 'package:app/features/auth/data/models/user_model.dart';

class PatientDashboard extends ConsumerWidget {
  final User user;
  const PatientDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(null));
    final productsAsync = ref.watch(productsProvider);
    final segmentsAsync = ref.watch(allSegmentsProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppTheme.textSecondary),
                  SizedBox(width: 8),
                  Text('Search medicine/healthcare products', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),

          // Welcome Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryTeal, Color(0xFF1CB5AC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${user.firstName ?? user.username}!', 
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 8),
                        const Text('Get your medicines delivered\nin 60 minutes.', 
                          style: TextStyle(color: Colors.white70, fontSize: 14)
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryTeal,
                            minimumSize: const Size(100, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Shop Now'),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.medication_liquid, size: 80, color: Colors.white24),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Category Grid
          categoriesAsync.when(
            data: (categories) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: categories.length > 8 ? 8 : categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  String assetPath = 'lib/assets/images/category_placeholder.png';
                  if (cat.name.toLowerCase().contains('medicine')) assetPath = 'lib/assets/images/medicine_category.png';
                  if (cat.name.toLowerCase().contains('lab')) assetPath = 'lib/assets/images/lab_test_category.png';
                  if (cat.name.toLowerCase().contains('wellness')) assetPath = 'lib/assets/images/wellness_category.png';
                  if (cat.name.toLowerCase().contains('healthcare')) assetPath = 'lib/assets/images/healthcare_category.png';
                  
                  return _buildCategoryItem(context, assetPath, cat.name, category: cat);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Product Segments
          segmentsAsync.when(
            data: (segments) {
              return Column(
                children: segments.map((segment) {
                  if (segment.products.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(segment.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: AppTheme.primaryTeal))),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 16),
                          itemCount: segment.products.length,
                          itemBuilder: (context, index) {
                            return _buildDealCard(context, ref, segment.products[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          // Fallback Deals
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recommend For You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: AppTheme.primaryTeal))),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: productsAsync.when(
              data: (products) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildDealCard(context, ref, products[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String assetPath, String label, {Category? category}) {
    return GestureDetector(
      onTap: () {
        if (category != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryPage(category: category)));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(assetPath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), 
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, WidgetRef ref, Product product) {
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';
    
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
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: product.images.isNotEmpty 
                    ? Image.network(product.images.first, fit: BoxFit.cover)
                    : Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover),
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
                    Text('$symbol ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryTeal)),
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
