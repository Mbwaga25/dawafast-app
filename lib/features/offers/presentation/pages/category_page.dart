import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/offers/data/models/product_model.dart';
import 'package:afyalink/features/offers/data/repositories/marketplace_repository.dart';
import 'package:afyalink/features/profile/data/repositories/settings_repository.dart';
import 'package:afyalink/features/home/presentation/pages/product_detail_page.dart';

class CategoryPage extends ConsumerWidget {
  final Category category;

  const CategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(relatedProductsProvider(category.slug));
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category.children != null && category.children!.isNotEmpty)
            Container(
              height: 110,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppTheme.backgroundWhite,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: category.children!.length,
                itemBuilder: (context, index) {
                  final childCat = category.children![index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CategoryPage(category: childCat)));
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: const Icon(Icons.category_outlined, color: AppTheme.primaryTeal),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            childCat.name,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          Expanded(
            child: productsAsync.when(
              data: (categoryProducts) {
                if (categoryProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text('No products found in ${category.name}', style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: categoryProducts.length,
                  itemBuilder: (context, index) {
                    final product = categoryProducts[index];
                    return _buildProductCard(context, product, symbol);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, String symbol) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(idOrSlug: product.slug)));
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                  Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('$symbol ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
