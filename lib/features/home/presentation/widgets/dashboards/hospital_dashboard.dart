import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/orders/data/repositories/order_repository.dart';

class HospitalDashboard extends ConsumerWidget {
  final User user;
  const HospitalDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider(null));

    return SingleChildScrollView(
      child: Column(
        children: [
          // Hospital Hero
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Hospital Admin', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold)),
                Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    const Text('Verified Institution', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  _actionCard('Active Orders', ordersAsync.value?.where((o) => o.status.toLowerCase() == 'pending' || o.status.toLowerCase() == 'processing').length.toString() ?? '—', Icons.pending_actions_outlined, Colors.orange),
                  const SizedBox(width: 12),
                  _actionCard('Delivered', ordersAsync.value?.where((o) => o.status.toLowerCase() == 'delivered').length.toString() ?? '—', Icons.done_all_outlined, Colors.green),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _actionCard('Doctors', '—', Icons.medical_services_outlined, Colors.blue),
                  const SizedBox(width: 12),
                  _actionCard('Services', '—', Icons.list_alt_outlined, Colors.purple),
                ]),

                const SizedBox(height: 32),
                const Text('Order Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      children: orders.take(6).map((order) {
                        final items = order.items.map((i) => '${i.quantity}x ${i.productName}').join(', ');
                        return _orderTile('ORD-${order.id}', order.clientName, items, order.status);
                      }).toList(),
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

  Widget _actionCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(String id, String client, String items, String status) {
    final lower = status.toLowerCase();
    Color statusColor = status.toLowerCase() == 'pending' ? Colors.orange : Colors.green;
    if (lower == 'cancelled') statusColor = Colors.red;
    if (lower == 'processing') statusColor = Colors.blue;

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
                Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(client, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text(items, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
