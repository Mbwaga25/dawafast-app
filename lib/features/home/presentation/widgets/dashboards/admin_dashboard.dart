import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/orders/data/repositories/order_repository.dart';

class AdminDashboard extends ConsumerWidget {
  final User user;
  const AdminDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider(null));

    return SingleChildScrollView(
      child: Column(
        children: [
          // Admin Hero Banner
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E2A3A), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Admin Portal', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold)),
                Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Super Admin', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Platform Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Stats Grid
                Row(children: [
                  _statCard('Total Orders', ordersAsync.value?.length.toString() ?? '—', Icons.receipt_long_outlined, Colors.blue),
                  const SizedBox(width: 12),
                  _statCard('Pending', ordersAsync.value?.where((o) => o.status.toLowerCase() == 'pending').length.toString() ?? '—', Icons.hourglass_top_outlined, Colors.orange),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _statCard('Delivered', ordersAsync.value?.where((o) => o.status.toLowerCase() == 'delivered').length.toString() ?? '—', Icons.check_circle_outline, Colors.green),
                  const SizedBox(width: 12),
                  _statCard('Cancelled', ordersAsync.value?.where((o) => o.status.toLowerCase() == 'cancelled').length.toString() ?? '—', Icons.cancel_outlined, Colors.red),
                ]),

                const SizedBox(height: 32),
                const Text('All Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                ordersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('No orders found.', style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                      );
                    }
                    return Column(
                      children: orders.take(10).map((order) => _orderTile(order)).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, __) => Text('Error: $err'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(order) {
    final status = order.status.toLowerCase();
    Color statusColor = Colors.grey;
    if (status == 'pending') statusColor = Colors.orange;
    if (status == 'delivered') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'processing') statusColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ORD-${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(order.clientName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(order.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text('Tsh ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
