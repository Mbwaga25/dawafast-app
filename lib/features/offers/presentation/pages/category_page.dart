import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/offers/data/models/product_model.dart';
import 'package:app/features/offers/data/repositories/marketplace_repository.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/home/presentation/pages/product_detail_page.dart';

class CategoryPage extends ConsumerWidget {
  final Category category;

  const CategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, we reuse the productsProvider but filter by category
    // In a real app, you'd have a specific query for productsByCategoryId
    final productsAsync = ref.watch(productsProvider);
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: productsAsync.when(
        data: (products) {
          final categoryProducts = products.where((p) => p.categoryName == category.name).toList();
          
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
                  color: AppTheme.backgroundGray,
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
