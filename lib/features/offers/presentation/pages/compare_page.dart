import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compare_provider.dart';
import '../../../../core/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ComparePage extends ConsumerWidget {
  const ComparePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compareList = ref.watch(compareProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
        actions: [
          if (compareList.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(compareProvider.notifier).clearList();
              },
              child: const Text('Clear All', style: TextStyle(color: AppTheme.primaryBlue)),
            )
        ],
      ),
      body: compareList.isEmpty
          ? const Center(
              child: Text(
                'Add products to compare',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed Feature Column
                      _buildFeatureColumn(),
                      const SizedBox(width: 16),
                      // Dynamic Product Columns
                      ...compareList.map((product) => Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: _buildProductColumn(product, ref),
                          ))
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 120), // Spacer for Image
        _buildRowHeader('Product Name'),
        _buildRowHeader('Price'),
        _buildRowHeader('Brand'),
        _buildRowHeader('Category'),
        _buildRowHeader('Rating'),
        _buildRowHeader('Description'),
      ],
    );
  }

  Widget _buildRowHeader(String title) {
    return Container(
      height: 60,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProductColumn(product, WidgetRef ref) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 160,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        )
                      : const Icon(Icons.image, size: 40, color: AppTheme.textSecondary),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    ref.read(compareProvider.notifier).removeProduct(product.id);
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.black, size: 20),
                  ),
                ),
              )
            ],
          ),
          _buildRowValue(product.name, maxLines: 2),
          _buildRowValue('Tsh ${product.price.toStringAsFixed(0)}', color: AppTheme.primaryBlue, isBold: true),
          _buildRowValue(product.brandName ?? 'N/A'),
          _buildRowValue(product.categoryName ?? 'N/A'),
          _buildRowValue(product.rating?.toString() ?? 'No rating'),
          _buildRowValue(product.description ?? 'No description', maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildRowValue(String value, {int maxLines = 1, Color? color, bool isBold = false}) {
    return Container(
      height: 60,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? AppTheme.textSecondary,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
