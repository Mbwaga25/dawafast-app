import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme.dart';
import '../../data/repositories/marketplace_repository.dart';

class BrandsPage extends ConsumerWidget {
  const BrandsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Brands'),
      ),
      body: brandsAsync.when(
        data: (brands) {
          if (brands.isEmpty) {
            return const Center(child: Text('No brands found.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return InkWell(
                onTap: () {
                  // In the future, navigate to a BrandProductsPage using the brand.slug
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viewing products for ${brand.name}...')),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(10), // Matches dawafast-front 10px radius
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: (brand.logoUrl != null && brand.logoUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: brand.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: AppTheme.textSecondary),
                                )
                              : Container(
                                  color: AppTheme.borderColor,
                                  child: const Icon(Icons.branding_watermark, size: 40, color: AppTheme.textSecondary),
                                ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                brand.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (brand.description != null && brand.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  brand.description!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
