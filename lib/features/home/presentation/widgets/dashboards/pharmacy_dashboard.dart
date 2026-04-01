import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/orders/data/models/order_model.dart';

// --- Local Providers for Pharmacy Workflow ---

final pharmacyNotificationsProvider = StateProvider<List<String>>((ref) => []);

class PharmacyOrdersNotifier extends StateNotifier<List<Order>> {
  PharmacyOrdersNotifier() : super([]) { _initMock(); }
  void _initMock() {
    state = [
      Order(id: 'MK-991', clientName: 'Alice Walker', status: 'Pending', totalAmount: 45.0, orderDate: DateTime.now().subtract(const Duration(minutes: 10)), items: [OrderItem(productName: 'Panadol Extra', quantity: 2, price: 12.5), OrderItem(productName: 'Vitamin C', quantity: 1, price: 20.0)]),
      Order(id: 'MK-992', clientName: 'Bob Builder', status: 'Pending', totalAmount: 120.0, orderDate: DateTime.now().subtract(const Duration(minutes: 45)), items: [OrderItem(productName: 'Amoxicillin', quantity: 1, price: 120.0)]),
      Order(id: 'MK-880', clientName: 'Charlie', status: 'Out for Delivery', totalAmount: 25.0, orderDate: DateTime.now().subtract(const Duration(hours: 2)), items: [OrderItem(productName: 'Cough Syrup', quantity: 1, price: 25.0)]),
    ];
  }
  void updateStatus(String id, String newStatus) {
    state = state.map((o) => o.id == id ? Order(id: o.id, clientName: o.clientName, status: newStatus, totalAmount: o.totalAmount, orderDate: o.orderDate, items: o.items) : o).toList();
  }
}

final pharmacyOrdersProvider = StateNotifierProvider<PharmacyOrdersNotifier, List<Order>>((ref) => PharmacyOrdersNotifier());

class PharmacyReferralsNotifier extends StateNotifier<List<Appointment>> {
  PharmacyReferralsNotifier() : super([]) { _initMock(); }
  void _initMock() {
    state = [
      Appointment(id: 'REF-01', doctorName: 'Dr. Sarah Johnson', patientName: 'Jane Doe', specialization: 'Prescribed: Amoxicillin 500mg, 1x3', date: DateTime.now().subtract(const Duration(minutes: 15)), status: 'awaiting_pharmacy', type: 'Transfer', isTransferred: true, transferredFrom: 'Dr. Sarah Johnson'),
    ];
  }
  void resolveReferral(String id) {
    state = state.map((a) => a.id == id ? Appointment(id: a.id, doctorName: a.doctorName, patientName: a.patientName, specialization: a.specialization, date: a.date, status: 'resolved', type: a.type, isTransferred: a.isTransferred, transferredFrom: a.transferredFrom) : a).toList();
  }
}

final pharmacyReferralsProvider = StateNotifierProvider<PharmacyReferralsNotifier, List<Appointment>>((ref) => PharmacyReferralsNotifier());

// --- Inventory Mutator ---
class PharmacyInventoryNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  PharmacyInventoryNotifier() : super([]) { _initMock(); }
  void _initMock() {
    state = [
      {'id': '1', 'name': 'Paracetamol 500mg', 'price': 5.0, 'stock': 120, 'inStock': true},
      {'id': '2', 'name': 'Ibuprofen 400mg', 'price': 8.5, 'stock': 45, 'inStock': true},
      {'id': '3', 'name': 'Amoxicillin Syrup', 'price': 15.0, 'stock': 0, 'inStock': false},
    ];
  }
  void toggleStock(String id, bool val) {
    state = state.map((p) => p['id'] == id ? {...p, 'inStock': val} : p).toList();
  }
  void cloneProduct(String name, double price, int stock) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    state = [...state, {'id': newId, 'name': name, 'price': price, 'stock': stock, 'inStock': stock > 0}];
  }
}

final pharmacyInventoryProvider = StateNotifierProvider<PharmacyInventoryNotifier, List<Map<String, dynamic>>>((ref) => PharmacyInventoryNotifier());

// --- Main Widget ---

class PharmacyDashboard extends ConsumerStatefulWidget {
  final User user;
  const PharmacyDashboard({super.key, required this.user});

  @override
  ConsumerState<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends ConsumerState<PharmacyDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Added 4th Tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRejectSheet(Order order) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Reject Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                   IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Text('Why are you rejecting Order #${order.id}?', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Rejection Reason', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(16)),
                  onPressed: () {
                     if (reasonController.text.isEmpty) return;
                     ref.read(pharmacyOrdersProvider.notifier).updateStatus(order.id, 'Rejected');
                     Navigator.pop(ctx);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Cancelled. Reason routed to Customer.'), backgroundColor: Colors.red));
                  },
                  child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              )
            ],
          )
        ),
      )
    );
  }

  void _showDispatchSheet(Order order) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text('Dispatch Delivery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                 IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            ListTile(leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.two_wheeler, color: Colors.white)), title: const Text('DawaFast Internal Fleet'), subtitle: const Text('Driver arriving in 5 mins'), trailing: const Icon(Icons.check_circle, color: Colors.blue), onTap: () {}),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
                onPressed: () {
                   ref.read(pharmacyOrdersProvider.notifier).updateStatus(order.id, 'Out for Delivery');
                   Navigator.pop(ctx);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order dispatched!'), backgroundColor: Colors.green));
                },
                child: const Text('Hand off to Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            )
          ],
        )
      )
    );
  }

  void _showCloneProductSheet() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Clone Global Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink)),
                   IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              TextField(
                onChanged: (v) => setSheetState(() => searchQuery = v),
                decoration: const InputDecoration(labelText: 'Search Global Supply (e.g. Cough)', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: searchQuery.isEmpty 
                  ? const Center(child: Text('Type to search global marketplace...'))
                  : ListView(
                     children: [
                        _buildGlobalProductResult(ctx, 'Cough Syrup (Night)', 'GSK Pharmaceuticals'),
                        _buildGlobalProductResult(ctx, 'Cough Lozenges', 'Strepsils'),
                     ],
                  ),
              )
            ],
          )
        )
      )
    );
  }

  Widget _buildGlobalProductResult(BuildContext ctx, String name, String brand) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.medication, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(brand, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
               // Clone logic popup
               Navigator.pop(ctx);
               _showImportConfigSheet(name);
            },
            child: const Text('Import', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showImportConfigSheet(String name) {
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Set Pricing & Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink)),
              const SizedBox(height: 8),
              Text('Importing: $name', style: const TextStyle(color: Colors.grey)),
              const Divider(height: 32),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price (\$)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Quantity (Stock)', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, padding: const EdgeInsets.all(16)),
                  onPressed: () {
                     final price = double.tryParse(priceController.text) ?? 0.0;
                     final stock = int.tryParse(stockController.text) ?? 0;
                     ref.read(pharmacyInventoryProvider.notifier).cloneProduct(name, price, stock);
                     Navigator.pop(ctx);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product Cloned Successfully!'), backgroundColor: Colors.green));
                  },
                  child: const Text('Add to Local Inventory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              )
            ],
          )
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.pink,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.pink,
                tabs: const [Tab(text: 'Orders'), Tab(text: 'Clinical Transfers'), Tab(text: 'Deliveries'), Tab(text: 'Inventory')],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [ _buildOrdersTab(), _buildTransfersTab(), _buildDeliveriesTab(), _buildInventoryTab() ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pharmacist Panel', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(widget.user.pharmacistProfile?.pharmacyName ?? 'My Pharmacy Hub', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const CircleAvatar(radius: 25, backgroundColor: Colors.white24, child: Icon(Icons.storefront, color: Colors.white, size: 28))
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernStat('Market Orders', '12'),
              _buildModernStat('Transfers', '3'),
              _buildModernStat('Rating', '4.8 ★'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildModernStat(String label, String value) {
    return Column(
      children: [
         Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
         const SizedBox(height: 4),
         Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildOrdersTab() {
    final orders = ref.watch(pharmacyOrdersProvider).where((o) => o.status == 'Pending').toList();
    if (orders.isEmpty) return const Center(child: Text('No orders waiting.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
         final o = orders[i];
         final itemsStr = o.items.map((it) => '${it.quantity}x ${it.productName}').join('\n');
         
         return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.pink.shade100)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Text('Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child: Text(o.status, style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))),
                   ],
                 ),
                 const Divider(),
                 Text('Customer: ${o.clientName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                 const SizedBox(height: 8),
                 Text(itemsStr, style: const TextStyle(fontWeight: FontWeight.w500)),
                 const SizedBox(height: 12),
                 Text('Total: \$${o.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
                 Row(
                   children: [
                     Expanded(child: OutlinedButton(onPressed: () => _showRejectSheet(o), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Reject'))),
                     const SizedBox(width: 12),
                     Expanded(child: ElevatedButton(onPressed: () => _showDispatchSheet(o), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Dispatch', style: TextStyle(color: Colors.white)))),
                   ],
                 )
              ],
            ),
         );
      }
    );
  }

  Widget _buildTransfersTab() {
    final refs = ref.watch(pharmacyReferralsProvider).where((r) => r.status == 'awaiting_pharmacy').toList();
    if (refs.isEmpty) return const Center(child: Text('No clinical transfers waiting.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: refs.length,
      itemBuilder: (ctx, i) {
         final r = refs[i];
         return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: [
                      const Icon(Icons.transfer_within_a_station, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text('Clinical Transfer from ${r.transferredFrom}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 13)),
                   ],
                 ),
                 const Divider(),
                 Text('Patient: ${r.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                 const SizedBox(height: 8),
                 Container(
                   padding: const EdgeInsets.all(12),
                   width: double.infinity,
                   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                   child: Text(r.specialization, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.teal)),
                 ),
                 const SizedBox(height: 16),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                     onPressed: () {
                         ref.read(pharmacyReferralsProvider.notifier).resolveReferral(r.id);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription dispensed. Doctor notified.')));
                     },
                     child: const Text('Mark Dispensed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   ),
                 )
              ],
            ),
         );
      }
    );
  }

  Widget _buildDeliveriesTab() {
    final orders = ref.watch(pharmacyOrdersProvider).where((o) => o.status == 'Out for Delivery').toList();
    if (orders.isEmpty) return const Center(child: Text('No active deliveries.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
         final o = orders[i];
         return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
            tileColor: Colors.white,
            leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.delivery_dining, color: Colors.white)),
            title: Text('Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('En Route to ${o.clientName}'),
            trailing: const Text('Live Tracking', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
         );
      }
    );
  }

  Widget _buildInventoryTab() {
     final inv = ref.watch(pharmacyInventoryProvider);
     
     return ListView(
       padding: const EdgeInsets.all(16),
       children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _showCloneProductSheet,
            icon: const Icon(Icons.cloud_download, color: Colors.white),
            label: const Text('Clone Product from Global System', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          const Text('Local Assigned Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (inv.isEmpty) const Center(child: Text('No inventory configured.')) else ...inv.map((item) {
             return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.medication, color: Colors.pink)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                           const SizedBox(height: 4),
                           Text('\$${item['price'].toStringAsFixed(2)} • Qty: ${item['stock']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                        ],
                      )
                    ),
                    Column(
                      children: [
                         Switch(
                           value: item['inStock'],
                           activeColor: Colors.green,
                           onChanged: (val) {
                              ref.read(pharmacyInventoryProvider.notifier).toggleStock(item['id'], val);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item["name"]} is now ${val ? "Available" : "Out of Stock"}')));
                           }
                         ),
                         Text(item['inStock'] ? 'Available' : 'Unavail', style: TextStyle(fontSize: 10, color: item['inStock'] ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                      ]
                    )
                  ],
                ),
             );
          })
       ],
     );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;

  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) { return Container(color: AppTheme.surfaceWhite, child: tabBar); }
  @override bool shouldRebuild(_StickyTabBarDelegate oldDelegate) { return tabBar != oldDelegate.tabBar; }
}
