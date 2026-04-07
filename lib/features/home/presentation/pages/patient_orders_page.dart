import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/orders/data/repositories/order_repository.dart';
import 'package:afyalink/features/orders/data/models/order_model.dart';
import 'package:afyalink/features/appointments/data/repositories/appointment_repository.dart';
import 'package:afyalink/features/appointments/presentation/pages/chat_page.dart';

class PatientOrdersPage extends ConsumerWidget {
  const PatientOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No orders yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final itemsSummary = order.items.map((i) => "${i.quantity}x ${i.productName}").join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(itemsSummary, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(dateFormat.format(order.orderDate), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            
            const Divider(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text('Tsh ${NumberFormat('#,###').format(order.totalAmount)}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryTeal)),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _chatWithPharmacy(context, ref, order),
                      icon: const Icon(Icons.support_agent, size: 18),
                      label: const Text('Contact Pharmacy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                        foregroundColor: AppTheme.primaryTeal,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            if (order.status.toLowerCase() == 'shipped' || order.status.toLowerCase() == 'processing') ...[
               const SizedBox(height: 12),
               _buildTrackingBar(order.status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed') color = Colors.green;
    if (s == 'shipped' || s == 'dispatched') color = Colors.blue;
    if (s == 'pending' || s == 'processing') color = Colors.orange;
    if (s == 'cancelled' || s == 'failed') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTrackingBar(String status) {
    final s = status.toLowerCase();
    double progress = 0.2;
    if (s == 'processing') progress = 0.4;
    if (s == 'shipped') progress = 0.7;
    if (s == 'delivered') progress = 1.0;

    return Column(
      children: [
        LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation(AppTheme.primaryTeal)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Placed', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(s.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
            const Text('Arrived', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  void _chatWithPharmacy(BuildContext context, WidgetRef ref, Order order) async {
     // Ideally get the pharmacy user ID. Fallback to constant for demo or search
     // We'll search for pharmacists associated with the store or use a general help ID
     try {
       // In a real app, 'order.store.owner.id' would be used
       // For now, let's notify the user we're connecting
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to Pharmacy support...')));
       
       // If we don't have a direct target, we can start a chat with the system support or first pharmacist
       // For this task, we assume we can start a chat with the order's pharmacy ID (mocking it if needed)
       final targetId = "pharmacy_support_${order.id}"; // Example mock ID
       // await ref.read(appointmentRepositoryProvider).startDirectChat(targetId);
       
       // If we don't have real IDs yet, show a placeholder
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat started! (Demo Mode)')));
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
     }
  }
}
