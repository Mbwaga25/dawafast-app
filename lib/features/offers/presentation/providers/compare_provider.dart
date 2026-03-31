import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import 'package:flutter/material.dart';

class CompareListNotifier extends StateNotifier<List<Product>> {
  CompareListNotifier() : super([]);

  void addProduct(Product product, BuildContext context) {
    if (state.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only compare up to 3 products at a time.')),
      );
      return;
    }

    if (state.any((p) => p.id == product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product is already in the compare list.')),
      );
      return;
    }

    state = [...state, product];
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to compare list.')),
    );
  }

  void removeProduct(String productId) {
    state = state.where((p) => p.id != productId).toList();
  }

  void clearList() {
    state = [];
  }

  bool isInCompareList(String productId) {
    return state.any((p) => p.id == productId);
  }
}

final compareProvider = StateNotifierProvider<CompareListNotifier, List<Product>>((ref) {
  return CompareListNotifier();
});
