import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/cart/presentation/pages/order_success_page.dart';
import 'package:app/features/cart/presentation/providers/cart_provider.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Delivery Address'),
            const SizedBox(height: 12),
            _buildAddressCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Payment Method'),
            const SizedBox(height: 12),
            _buildPaymentCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Order Summary'),
            const SizedBox(height: 12),
            _buildOrderSummary(cartState, symbol),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cartState.items.isEmpty ? null : () => _placeOrder(context, ref),
                child: const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildAddressCard() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showAddressPicker(context),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryTeal),
            title: const Text('Home Address'),
            subtitle: const Text('123 Health Street, Dar es Salaam, Tanzania'),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryTeal),
        title: const Text('Mobile Money (M-Pesa)'),
        subtitle: const Text('**** **** **** 4567'),
        trailing: TextButton(onPressed: () {}, child: const Text('Edit')),
      ),
    );
  }

  Widget _buildOrderSummary(cartState, String symbol) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...cartState.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('${item.quantity}x ${item.name}', style: const TextStyle(color: AppTheme.textSecondary)),
                  Text('$symbol ${(item.price * item.quantity).toStringAsFixed(0)}'),
                ],
              ),
            )).toList(),
            const Divider(height: 24),
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
                const Text('Delivery', style: TextStyle(color: AppTheme.textSecondary)),
                Text('$symbol ${cartState.deliveryFee.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$symbol ${cartState.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context, WidgetRef ref) {
    // Simulate API call
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Future.delayed(const Duration(seconds: 2), () {
      ref.read(cartProvider.notifier).clear();
      Navigator.pop(context); // Pop loading
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessPage(orderId: 'DWF-789234')),
      );
    });
  }

  void _showAddressPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Delivery Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home Address'),
              subtitle: const Text('123 Health Street, Dar es Salaam'),
              trailing: const Icon(Icons.check_circle, color: AppTheme.primaryTeal),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('Office'),
              subtitle: const Text('Tower A, 4th Floor, Posta'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: AppTheme.primaryTeal),
              title: const Text('Add New Address', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
