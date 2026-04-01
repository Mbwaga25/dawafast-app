import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/orders/data/repositories/order_repository.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  final User user;
  const AdminDashboard({super.key, required this.user});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPlatformSettingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text('Platform Diagnostics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                 IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            ListTile(leading: const Icon(Icons.cloud_done, color: Colors.green), title: const Text('GraphQL API Status'), trailing: const Text('ONLINE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
            ListTile(leading: const Icon(Icons.payment, color: Colors.blue), title: const Text('Payment Gateways'), trailing: const Text('OK', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
            ListTile(leading: const Icon(Icons.storage, color: Colors.orange), title: const Text('Database Load'), trailing: const Text('42%', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.all(16)),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Flush Caches', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            )
          ],
        )
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
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.indigo,
                tabs: const [Tab(text: 'DawaFast Orders'), Tab(text: 'Registered Entities'), Tab(text: 'Infrastructure')],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [ _buildOrdersTab(), _buildEntitiesTab(), _buildInfrastructureTab() ],
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
        color: Color(0xFF1E2A3A),
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
                  Text('Super Admin Control', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${widget.user.fullName} (Root)', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const CircleAvatar(radius: 25, backgroundColor: Colors.white24, child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28))
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernStat('Revenue', '\$4.2k'),
              _buildModernStat('Users', '8,421'),
              _buildModernStat('Uptime', '99.9%'),
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
    final ordersAsync = ref.watch(myOrdersProvider(null));

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) return const Center(child: Text('No orders recorded in Database.'));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
             Row(children: [
                _statCard('Total Orders', orders.length.toString(), Icons.receipt_long_outlined, Colors.blue),
                const SizedBox(width: 12),
                _statCard('Pending', orders.where((o) => o.status.toLowerCase() == 'pending').length.toString(), Icons.hourglass_top_outlined, Colors.orange),
             ]),
             const SizedBox(height: 12),
             Row(children: [
                _statCard('Delivered', orders.where((o) => o.status.toLowerCase() == 'delivered').length.toString(), Icons.check_circle_outline, Colors.green),
                const SizedBox(width: 12),
                _statCard('Cancelled', orders.where((o) => o.status.toLowerCase() == 'cancelled').length.toString(), Icons.cancel_outlined, Colors.red),
             ]),
             const SizedBox(height: 24),
             const Text('Global Feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             ...orders.take(20).map((order) => _orderTile(order))
          ]
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,s) => const Center(child: Text('GraphQL Error loading orders')),
    );
  }

  Widget _buildEntitiesTab() {
    return ListView(
       padding: const EdgeInsets.all(16),
       children: [
          _buildEntityConfig('Active Doctors', '245 registered', Icons.medical_services, Colors.blue),
          _buildEntityConfig('Pharmacies', '42 registered', Icons.local_pharmacy, Colors.pink),
          _buildEntityConfig('Laboratories', '12 registered', Icons.science, Colors.deepPurple),
          _buildEntityConfig('Hospitals', '8 registered', Icons.business, Colors.cyan),
          _buildEntityConfig('Standard Users', '8,114 registered', Icons.people, Colors.grey),
       ],
    );
  }

  Widget _buildEntityConfig(String title, String subtitle, IconData icon, Color color) {
    return Container(
       margin: const EdgeInsets.only(bottom: 12),
       decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12), color: Colors.white),
       child: ListTile(
         leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
         subtitle: Text(subtitle),
         trailing: const Icon(Icons.chevron_right),
         onTap: () {},
       ),
    );
  }

  Widget _buildInfrastructureTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            const Text('System Operations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _showPlatformSettingsSheet,
              icon: const Icon(Icons.settings_system_daydream, color: Colors.white),
              label: const Text('Open Diagnostic Terminal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            )
         ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
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

  Widget _orderTile(dynamic order) {
    final status = order.status.toLowerCase();
    Color statusColor = Colors.grey;
    if (status == 'pending') statusColor = Colors.orange;
    if (status == 'delivered') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'processing') statusColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
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
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(order.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text('Tsh ${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ],
      ),
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
