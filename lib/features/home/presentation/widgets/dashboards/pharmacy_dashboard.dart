import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/orders/data/models/order_model.dart';
import 'package:app/features/healthcare/data/repositories/pharmacy_repository.dart';
import 'package:app/features/orders/data/repositories/order_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io' as io;

// --- Local State Notifiers for UI Refresh ---

final pharmacyOrdersProvider = FutureProvider.family<List<Order>, String>((ref, storeId) async {
  return ref.watch(orderRepositoryProvider).fetchMyOrders(); // Adjust backend to allow filtering by storeId if needed
});

final pharmacyReferralsProvider = FutureProvider.family<List<dynamic>, String>((ref, storeId) async {
  return ref.watch(pharmacyRepositoryProvider).getPrescriptions(storeId);
});

final pharmacyInventoryProvider = FutureProvider.family<List<dynamic>, String>((ref, storeId) async {
  return ref.watch(pharmacyRepositoryProvider).getStoreProducts(storeId);
});

final pharmacyReportProvider = FutureProvider.family<PharmacyReport, String>((ref, userId) async {
  return ref.watch(pharmacyRepositoryProvider).getPharmacyReport(userId);
});

// --- Main Pharmacy Dashboard ---

class PharmacyDashboard extends ConsumerStatefulWidget {
  final User user;
  const PharmacyDashboard({super.key, required this.user});

  @override
  ConsumerState<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends ConsumerState<PharmacyDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _OverviewTab(user: widget.user),
      _OrdersTab(user: widget.user),
      _InventoryTab(user: widget.user),
      _ReportsTab(user: widget.user),
      _ProfileTab(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryTeal,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Inventory'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.store_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// --- 1. Overview Tab ---
class _OverviewTab extends ConsumerWidget {
  final User user;
  const _OverviewTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(pharmacyReportProvider(user.id.toString()));
    final currencyAsync = ref.watch(activeCurrencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Overview'),
        actions: [
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pharmacyReportProvider(user.id.toString()).future),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user),
              const SizedBox(height: 24),
              reportAsync.when(
                data: (report) => _buildStatsGrid(context, report, currencyAsync.value?.symbol ?? '/='),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 24),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                   _buildQuickAction(context, 'New Referral', Icons.medical_services, Colors.purple, () => _showReferralDialog(context)),
                   const SizedBox(width: 16),
                   _buildQuickAction(context, 'Add Stock', Icons.add_box, Colors.blue, () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReferralDialog(BuildContext context) {
    // This could just switch to the Orders tab or open a specific dialog
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a patient from an order or search below')));
  }

  Widget _buildHeader(User user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
          child: const Icon(Icons.store, color: AppTheme.primaryTeal),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: AppTheme.headingStyle.copyWith(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey)),
            Text(user.username, style: AppTheme.headingStyle.copyWith(fontSize: 18)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, PharmacyReport report, String currency) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Pending', '${report.pendingCount}', Icons.hourglass_empty, Colors.orange),
        _buildStatCard('Delivered', '${report.accomplishedCount}', Icons.check_circle, Colors.green),
        _buildStatCard('Revenue', '$currency${report.totalRevenue.toStringAsFixed(0)}', Icons.payments, AppTheme.primaryTeal),
        _buildStatCard('Missed', '${report.missedCount}', Icons.cancel, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(0.05), border: Border.all(color: color.withOpacity(0.1)), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [Icon(icon, color: color), const SizedBox(height: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))]),
        ),
      ),
    );
  }
}

// --- 2. Orders Tab ---

class _OrdersTab extends ConsumerWidget {
  final User user;
  const _OrdersTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders & Referrals'),
          bottom: const TabBar(
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryTeal,
            tabs: [Tab(text: 'Customer Orders'), Tab(text: 'Doctor Referrals')],
          ),
        ),
        body: TabBarView(
          children: [_DirectOrdersView(user: user), _ReferralsView(user: user)],
        ),
      ),
    );
  }
}

class _DirectOrdersView extends ConsumerWidget {
  final User user;
  const _DirectOrdersView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(pharmacyOrdersProvider(user.id.toString()));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(pharmacyOrdersProvider(user.id.toString()).future),
      child: ordersAsync.when(
        data: (orders) => orders.isEmpty 
          ? const Center(child: Text('No active orders'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (ctx, i) {
                final order = orders[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${order.clientName} • ${DateFormat('HH:mm').format(order.orderDate)}'),
                    trailing: _buildStatusBadge(order.status),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ...order.items.map((item) => ListTile(
                              title: Text(item.productName),
                              trailing: Text('x${item.quantity}'),
                            )),
                            const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (order.clientName.contains('Ref')) // Check if it's a doctor referral
                                      ElevatedButton.icon(
                                        onPressed: () => _showReferralToDoctorDialog(context, order.id), // Simplified for order context
                                        icon: const Icon(Icons.medical_services, size: 16),
                                        label: const Text('Refer to Doctor'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                                      ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _showReportDialog(ref, context, order.id),
                                      icon: const Icon(Icons.note_add_rounded, size: 16),
                                      label: const Text('Add Report'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _updateStatus(ref, context, order.id, 'cancelled'),
                                      child: const Text('Reject', style: TextStyle(color: Colors.red)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _updateStatus(ref, context, order.id, (order.status == 'Pending' ? 'processing' : 'delivered')),
                                      child: Text(order.status == 'Pending' ? 'Confirm' : 'Mark Delivered'),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _showPatientHistoryDialog(ref, context, order.patientId),
                                      icon: const Icon(Icons.history_edu_rounded, color: AppTheme.primaryTeal),
                                      tooltip: 'View Patient History',
                                    ),
                                  ],
                                )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status.toLowerCase() == 'pending' ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _updateStatus(WidgetRef ref, BuildContext context, String id, String status) async {
    try {
      final success = await ref.read(orderRepositoryProvider).updateOrderStatus(id, status);
      if (success) {
        ref.refresh(pharmacyOrdersProvider(user.id.toString()));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to $status')));
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _showReferralToDoctorDialog(BuildContext context, String patientName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ReferToDoctorSheet(patientId: patientName),
    );
  }

  void _showReportDialog(WidgetRef ref, BuildContext context, String orderId) {
    // ... code already there
  }

  void _showPatientHistoryDialog(WidgetRef ref, BuildContext context, String patientId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Patient Clinical History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: FutureBuilder<Map<String, List<dynamic>>>(
            future: ref.read(pharmacyRepositoryProvider).getPatientHistory(patientId),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              final appts = snapshot.data?['appointments'] ?? [];
              final refs = snapshot.data?['referrals'] ?? [];
              return ListView(
                children: [
                   const Text('Past Consultations', style: TextStyle(fontWeight: FontWeight.bold)),
                   ...appts.map((a) => ListTile(title: Text(a['specialization'] ?? 'General'), subtitle: Text(a['scheduledTime'] ?? ''))),
                   const Divider(),
                   const Text('Previous Referrals', style: TextStyle(fontWeight: FontWeight.bold)),
                   ...refs.map((r) => ListTile(title: Text(r['reason'] ?? 'Routine'), subtitle: Text(r['status'] ?? ''))),
                ],
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

class _ReferralsView extends ConsumerWidget {
  final User user;
  const _ReferralsView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralsAsync = ref.watch(pharmacyReferralsProvider(user.id.toString()));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(pharmacyReferralsProvider(user.id.toString()).future),
      child: referralsAsync.when(
        data: (prescriptions) => prescriptions.isEmpty 
          ? const Center(child: Text('No active prescriptions from doctors'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prescriptions.length,
              itemBuilder: (ctx, i) {
                final presc = prescriptions[i];
                final consultation = presc['consultation'];
                final patient = consultation['patient'];
                final doctor = consultation['doctor']['user'];
                final items = (presc['items'] as List<dynamic>);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text('${patient['firstName']} ${patient['lastName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: #${presc['id']} • From: Dr. ${doctor['firstName']}'),
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (presc['notes'] != null) ...[
                              const Text('Doctor Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(presc['notes'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 12),
                            ],
                            const Text('Prescribed Medicines:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ...items.map((m) => ListTile(
                              dense: true,
                              title: Text(m['medicineName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${m['dosage']} - ${m['duration']}\n${m['instructions'] ?? ""}'),
                            )),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {}, // Future chat implementation
                                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                  label: const Text('Chat'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _showDispenseDialog(context, ref, presc['id']),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                                  child: const Text('Dispense & Complete'),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDispenseDialog(BuildContext context, WidgetRef ref, String id) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispense Prescription'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(labelText: 'Pharmacist Advice/Notes', hintText: 'e.g. Take after meals, side effects...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final result = await ref.read(pharmacyRepositoryProvider).dispensePrescription(id, notesController.text);
              if (result.success) {
                Navigator.pop(ctx);
                ref.refresh(pharmacyReferralsProvider(user.id.toString()));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription marked as FILLED')));
              } else if (result.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
              }
            },
            child: const Text('Confirm Dispense'),
          ),
        ],
      ),
    );
  }
}

// --- 3. Inventory Tab ---
class _InventoryTab extends ConsumerStatefulWidget {
  final User user;
  const _InventoryTab({required this.user});

  @override
  ConsumerState<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<_InventoryTab> {
  String _searchQuery = '';
  List<dynamic> _searchResults = [];
  bool _isSearching = false; // Default to false

  void _onSearch(String val) async {
    setState(() { _searchQuery = val; _isSearching = true; });
    if (val.isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    try {
      final results = await ref.read(pharmacyRepositoryProvider).searchProducts(val);
      setState(() { _searchResults = results; _isSearching = false; });
    } catch (e) {
      setState(() { _isSearching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded), 
            onPressed: () => _showAddProductOptions(context),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search global products to clone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(),
          Expanded(
            child: _searchQuery.isNotEmpty 
              ? ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (ctx, i) {
                    final p = _searchResults[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: p['image'] != null && p['image']['imageUrl'] != null
                            ? Image.network(p['image']['imageUrl'], width: 50, height: 50, errorBuilder: (c, e, s) => const Icon(Icons.medication))
                            : const Icon(Icons.medication),
                        title: Text(p['name']),
                        subtitle: Text('Brand: ${p['brand'] ?? 'Generic'} • Price: ${p['price']}'),
                        trailing: ElevatedButton(
                          onPressed: () => _showCloneWizard(context, p),
                          child: const Text('Clone'),
                        ),
                      ),
                    );
                  },
                )
              : _buildMyProductsList(),
          ),
        ],
      ),
    );
  }

  void _showAddProductOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Add Product to Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.search, color: AppTheme.primaryTeal),
            title: const Text('Clone from Global Catalog'),
            subtitle: const Text('Search thousands of approved products'),
            onTap: () {
              Navigator.pop(ctx);
              setState(() { _isSearching = true; });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use search bar above to find products to clone')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined, color: AppTheme.primaryTeal),
            title: const Text('Submit New Product'),
            subtitle: const Text('Suggest a new item to administrators'),
            onTap: () {
              Navigator.pop(ctx);
              _showSubmitProductForm(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMyProductsList() {
    final inventoryAsync = ref.watch(pharmacyInventoryProvider(widget.user.id.toString()));
    return inventoryAsync.when(
      data: (items) => items.isEmpty 
        ? const Center(child: Text('No products in your store. Search above to add some!'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final product = item['product'];
              return _buildInventoryItem(
                id: item['id'],
                productId: product['id'],
                name: product['name'],
                price: item['price'].toString(),
                available: item['isAvailable'],
                quantity: item['quantity'] ?? 0,
              );
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildInventoryItem({
    required String id, 
    required String productId,
    required String name, 
    required String price, 
    required bool available, 
    required int quantity
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name),
        subtitle: Text('Price: /= $price • Stock: $quantity'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryTeal),
              onPressed: () => _showUpdateStockDialog(context, productId, name, price, quantity),
            ),
            Switch(
              value: available,
              onChanged: (val) async {
                final result = await ref.read(pharmacyRepositoryProvider).toggleAvailability(id, val);
                if (result.success) {
                  ref.invalidate(pharmacyInventoryProvider(widget.user.id.toString()));
                } else if (result.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
                }
              },
              activeColor: AppTheme.primaryTeal,
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context, String id, String name, String currentPrice, int currentQuantity) {
    final priceController = TextEditingController(text: currentPrice);
    final stockController = TextEditingController(text: currentQuantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock Quantity'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final result = await ref.read(pharmacyRepositoryProvider).updateStock(
                storeId: widget.user.id.toString(),
                productId: id,
                stock: int.parse(stockController.text),
                price: double.parse(priceController.text),
              );
              if (result.success) {
                Navigator.pop(ctx);
                ref.invalidate(pharmacyInventoryProvider(widget.user.id.toString()));
              } else if (result.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCloneWizard(BuildContext context, dynamic product) {
    final priceController = TextEditingController(text: product['price'].toString());
    final stockController = TextEditingController(text: '10');
    final variants = (product['variants'] as List<dynamic>?) ?? [];
    String? selectedVariantId = variants.isNotEmpty ? variants[0]['id'] : null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clone: ${product['name']}', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              if (variants.isNotEmpty) ...[
                const Text('Select Variation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedVariantId,
                  items: variants.map((v) => DropdownMenuItem<String>(
                    value: v['id'],
                    child: Text('${v['name']} (${v['price']})'),
                  )).toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedVariantId = val;
                      final selected = variants.firstWhere((v) => v['id'] == val);
                      priceController.text = selected['price'].toString();
                    });
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
              ],
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Your Price', prefixText: '/= '), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Initial Stock'), keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await ref.read(pharmacyRepositoryProvider).cloneProduct(
                      storeId: widget.user.id.toString(),
                      productId: product['id'],
                      variantId: selectedVariantId,
                      price: double.parse(priceController.text),
                      stock: int.parse(stockController.text),
                    );
                    if (success) {
                      Navigator.pop(ctx);
                      ref.invalidate(pharmacyInventoryProvider(widget.user.id.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added to inventory')));
                    }
                  },
                  child: const Text('Clone to Store'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitProductForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SubmitProductSheet(storeId: widget.user.id.toString()),
    );
  }
}

// --- New Feature Components ---

class _SubmitProductSheet extends ConsumerStatefulWidget {
  final String storeId;
  const _SubmitProductSheet({required this.storeId});
  @override
  ConsumerState<_SubmitProductSheet> createState() => _SubmitProductSheetState();
}

class _SubmitProductSheetState extends ConsumerState<_SubmitProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _categoryId;
  String? _brandId;
  List<dynamic> _categories = [];
  List<dynamic> _brands = [];
  bool _isLoadingLists = true;

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    try {
      final cats = await ref.read(pharmacyRepositoryProvider).getCategories();
      final brs = await ref.read(pharmacyRepositoryProvider).getBrands();
      setState(() {
        _categories = cats;
        _brands = brs;
        _isLoadingLists = false;
      });
    } catch (e) {
      setState(() => _isLoadingLists = false);
    }
  }

  String? _imagePath;
  String? _imageBase64;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imagePath = image.path;
        _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Clinical Product Feed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
              const Text('Submit detailed product info for administrative review', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              
              _buildFieldTitle('Product Visual'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: _imagePath != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(io.File(_imagePath!), fit: BoxFit.cover))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: AppTheme.primaryTeal), Text('Upload Product Photo')]),
                ),
              ),
              const SizedBox(height: 20),

              _buildFieldTitle('Basic Information'),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Scientific/Product Name', hintText: 'e.g. Paracetamol BP 500mg')),
              const SizedBox(height: 12),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Clinical Description/Indications'), maxLines: 3),
              const SizedBox(height: 20),
              _buildFieldTitle('Categorization'),
              if (_isLoadingLists) 
                const LinearProgressIndicator()
              else
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _categoryId,
                        items: _categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                        decoration: const InputDecoration(labelText: 'Category'),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _brandId,
                        items: _brands.map((b) => DropdownMenuItem(value: b['id'].toString(), child: Text(b['name']))).toList(),
                        onChanged: (v) => setState(() => _brandId = v),
                        decoration: const InputDecoration(labelText: 'Brand'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _buildFieldTitle('Pricing & Logistics'),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _skuController, decoration: const InputDecoration(labelText: 'Internal SKU'))),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await ref.read(pharmacyRepositoryProvider).submitProductToAdmin(
                      name: _nameController.text,
                      description: _descController.text,
                      price: double.tryParse(_priceController.text) ?? 100.0,
                      categoryId: _categoryId,
                    );
                    if (result.success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product submitted for clinical review')));
                    } else if (result.message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('Submit to Admin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal)));
  }

  Widget _buildDropdown(String label, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}

class _ReferToDoctorSheet extends ConsumerStatefulWidget {
  final String patientId;
  const _ReferToDoctorSheet({required this.patientId});
  @override
  ConsumerState<_ReferToDoctorSheet> createState() => _ReferToDoctorSheetState();
}

class _ReferToDoctorSheetState extends ConsumerState<_ReferToDoctorSheet> {
  String _search = '';
  List<dynamic> _doctors = [];
  bool _loading = false;
  bool _isSensitive = false;

  void _onSearch(String val) async {
    if (val.length < 2) return;
    setState(() => _loading = true);
    final results = await ref.read(pharmacyRepositoryProvider).searchDoctors(val);
    setState(() { _doctors = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Refer Case to Doctor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Transfer sensitive issues for expert clinical evaluation', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Mark as Sensitive Case', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: const Text('Flag for immediate priority doctor review'),
            value: _isSensitive,
            onChanged: (val) => setState(() => _isSensitive = val),
            activeColor: Colors.red,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search specialists...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _doctors.length,
              itemBuilder: (ctx, i) {
                final d = _doctors[i]['node'];
                final profile = d['doctorProfile'];
                final user = profile['user'];
                return ListTile(
                  title: Text('Dr. ${user['firstName']} ${user['lastName']}'),
                  subtitle: Text(profile['specialization'] ?? 'General Physician'),
                  trailing: ElevatedButton(
                    onPressed: () => _confirmReferral(d['id']),
                    child: const Text('Refer'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReferral(String doctorId) async {
    // Show reason dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Referral Reason'),
        content: const TextField(decoration: InputDecoration(hintText: 'e.g., Clinical evaluation required')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'Clinical consult required'), child: const Text('Confirm')),
        ],
      ),
    );

    if (reason != null) {
      final success = await ref.read(pharmacyRepositoryProvider).referToDoctor(
        patientId: widget.patientId, // In real app, use patient ID
        doctorId: doctorId,
        reason: reason,
      );
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient referred successfully')));
      }
    }
  }
}

// --- 4. Reports Tab ---
class _ReportsTab extends ConsumerWidget {
  final User user;
  const _ReportsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(pharmacyReportProvider(user.id.toString()));
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy Reports')),
      body: reportAsync.when(
        data: (report) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildReportCard(context, 'Pending', '${report.pendingCount}', Colors.orange, report.pendingItems),
            _buildReportCard(context, 'Delivered', '${report.accomplishedCount}', Colors.green, report.accomplishedItems),
            _buildReportCard(context, 'Transferred', '${report.transferredCount}', Colors.blue, report.transferredItems),
            _buildReportCard(context, 'Cancelled', '${report.missedCount}', Colors.red, report.missedItems),
            const Divider(height: 40),
            Text('Financials', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Live Revenue'),
                trailing: Text('TZS ${report.totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryTeal)),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String label, String value, Color color, List<dynamic> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(Icons.list_alt, color: color)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showDrillDown(context, label, items),
              child: const Text('View List'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrillDown(BuildContext context, String title, List<dynamic> items) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: AppTheme.headingStyle.copyWith(fontSize: 18)),
            const Divider(),
            Expanded(
              child: items.isEmpty 
                ? const Center(child: Text('No orders found'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return ListTile(
                        title: Text('Order #${item['id']}'),
                        subtitle: Text(item['clientName'] ?? 'Unknown'),
                        trailing: Text('${item['totalAmount']}'),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends ConsumerStatefulWidget {
  final User user;
  const _ProfileTab({required this.user});

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final _bioController = TextEditingController(text: 'Trusted community pharmacy providing high-quality medications.');
  bool _isSmart = true;
  String _hours = '08:00 - 22:00';
  String? _imagePath;
  String? _imageBase64;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imagePath = image.path;
        _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          const Text('Profile Bio', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
          const SizedBox(height: 8),
          TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Tell customers about your store...')),
          const SizedBox(height: 24),
          _buildSettingsTile(Icons.auto_awesome, 'Smart Pharmacy Status', 'Automated ordering & 24/7 priority', trailing: Switch(value: _isSmart, onChanged: (v) => setState(() => _isSmart = v), activeColor: AppTheme.primaryTeal)),
          _buildSettingsTile(Icons.access_time_rounded, 'Operating Hours', 'Current: $_hours', onTap: _editHours),
          _buildSettingsTile(Icons.lock_reset_rounded, 'Change Password', 'Update your account security', onTap: _changePassword),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(pharmacyRepositoryProvider).updateProfile(
                widget.user.id.toString(),
                description: _bioController.text,
                isSmart: _isSmart,
                imageBase64: _imageBase64,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('Save Profile Changes'),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: () {}, child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50, 
                backgroundColor: AppTheme.primaryTeal.withOpacity(0.1), 
                backgroundImage: _imagePath != null ? FileImage(io.File(_imagePath!)) : null,
                child: _imagePath == null ? const Icon(Icons.store, size: 40, color: AppTheme.primaryTeal) : null,
              ),
              Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 16, backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.camera_alt, size: 14), onPressed: _pickImage))),
            ],
          ),
          const SizedBox(height: 16),
          Text(widget.user.username, style: AppTheme.headingStyle.copyWith(fontSize: 22)),
          const Text('Verified Pharmacy Partner', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryTeal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  void _editHours() {
    final controller = TextEditingController(text: _hours);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Hours'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. 24 Hours or 09:00-18:00')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { setState(() => _hours = controller.text); Navigator.pop(ctx); }, child: const Text('Update')),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'New Password')),
            SizedBox(height: 12),
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'Confirm Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Update Security')),
        ],
      ),
    );
  }
}
