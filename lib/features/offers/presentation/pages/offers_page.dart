import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/offers/data/models/product_model.dart';
import 'package:app/features/offers/data/repositories/marketplace_repository.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/home/presentation/pages/product_detail_page.dart';
import 'package:app/features/offers/presentation/pages/category_page.dart';

class OffersPage extends ConsumerWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider(null));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('All Medicines', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (cats) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.take(8).map((c) => ActionChip(
                label: Text(c.name, style: const TextStyle(fontSize: 12)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryPage(category: c))),
              )).toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 16),
          productsAsync.when(
            data: (products) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(idOrSlug: p.slug))),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: p.images.isNotEmpty
                                ? Image.network(p.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover))
                                : Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Tsh ${p.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

