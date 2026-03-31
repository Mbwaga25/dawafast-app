import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/cart/presentation/providers/cart_provider.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/cart/data/models/cart_model.dart';
import 'package:app/features/cart/presentation/pages/checkout_page.dart';


class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (cartState.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(cartProvider.notifier).clear(),
            ),
        ],
      ),
      body: cartState.items.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return _CartItemTile(item: item);
                    },
                  ),
                ),
                _buildSummary(context, ref, cartState),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Looks like you haven\'t added anything yet.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WidgetRef ref, cartState) {
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary)),
                Text('$symbol ${cartState.subtotal.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee', style: TextStyle(color: AppTheme.textSecondary)),
                Text('$symbol ${cartState.deliveryFee.toStringAsFixed(0)}'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('$symbol ${cartState.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage()));
                },
                child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 70,
              height: 70,
              color: AppTheme.backgroundWhite,
              child: item.image != null
                  ? Image.network(item.image!, fit: BoxFit.cover)
                  : const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$symbol ${item.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryBlue)),
              ],
            ),
          ),
          // Quantity Controls
          Row(
            children: [
              _qtyButton(Icons.remove, () {
                ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity - 1);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _qtyButton(Icons.add, () {
                ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity + 1);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }
}
