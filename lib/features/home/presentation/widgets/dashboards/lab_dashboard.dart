import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/auth/data/models/user_model.dart';
import 'package:afyalink/features/appointments/data/models/appointment_model.dart';

// --- Local Providers for Lab Workflow ---

class LabReferralsNotifier extends StateNotifier<List<Appointment>> {
  LabReferralsNotifier() : super([]) { _initMock(); }
  void _initMock() {
    state = [
      Appointment(
        id: 'LAB-REF-01', 
        doctorName: 'Dr. Sarah Johnson', 
        patientName: 'Jane Doe', 
        specialization: 'Requested: Complete Blood Count (CBC)', 
        date: DateTime.now().subtract(const Duration(minutes: 5)), 
        status: 'awaiting_lab', 
        type: 'Transfer', 
        isTransferred: true, 
        transferredFrom: 'Dr. Sarah Johnson'
      ),
      Appointment(
        id: 'LAB-REF-02', 
        doctorName: 'Dr. Michael Ross', 
        patientName: 'John Smith', 
        specialization: 'Requested: Lipid Panel', 
        date: DateTime.now().subtract(const Duration(minutes: 50)), 
        status: 'awaiting_lab', 
        type: 'Transfer', 
        isTransferred: true, 
        transferredFrom: 'Dr. Michael Ross'
      ),
    ];
  }
  void resolveReferral(String id) {
    state = state.map((a) => a.id == id ? Appointment(
      id: a.id, 
      doctorName: a.doctorName, 
      patientName: a.patientName, 
      specialization: a.specialization, 
      date: a.date, 
      status: 'resolved', 
      type: a.type, 
      isTransferred: a.isTransferred, 
      transferredFrom: a.transferredFrom,
      notes: a.notes,
    ) : a).toList();
  }
}

final labReferralsProvider = StateNotifierProvider<LabReferralsNotifier, List<Appointment>>((ref) => LabReferralsNotifier());

class LabInventoryNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  LabInventoryNotifier() : super([]) { _initMock(); }
  void _initMock() {
    state = [
      {'id': 'L1', 'name': 'Complete Blood Count (CBC)', 'price': 25.0, 'stock': 999, 'inStock': true},
      {'id': 'L2', 'name': 'MRI Scan (Head)', 'price': 450.0, 'stock': 1, 'inStock': true},
      {'id': 'L3', 'name': 'Lipid Panel', 'price': 30.0, 'stock': 0, 'inStock': false},
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

final labInventoryProvider = StateNotifierProvider<LabInventoryNotifier, List<Map<String, dynamic>>>((ref) => LabInventoryNotifier());

// --- Main Widget ---

class LabDashboard extends ConsumerStatefulWidget {
  final User user;
  const LabDashboard({super.key, required this.user});

  @override
  ConsumerState<LabDashboard> createState() => _LabDashboardState();
}

class _LabDashboardState extends ConsumerState<LabDashboard> with SingleTickerProviderStateMixin {
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

  void _showCloneTestSheet() {
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
                   const Text('Clone Global Test', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                   IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              TextField(
                onChanged: (v) => setSheetState(() => searchQuery = v),
                decoration: const InputDecoration(labelText: 'Search Global Medical Tests (e.g. PCR)', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: searchQuery.isEmpty 
                  ? const Center(child: Text('Type to search global lab directory...'))
                  : ListView(
                     children: [
                        _buildGlobalTestResult(ctx, 'COVID-19 RT-PCR', 'DawaFast Diagnostics'),
                        _buildGlobalTestResult(ctx, 'Malaria Antigen Test', 'DawaFast Diagnostics'),
                     ],
                  ),
              )
            ],
          )
        )
      )
    );
  }

  Widget _buildGlobalTestResult(BuildContext ctx, String name, String brand) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.biotech, color: Colors.deepPurple)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
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
              const Text('Set Pricing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 8),
              Text('Importing Test: $name', style: const TextStyle(color: Colors.grey)),
              const Divider(height: 32),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pricing (\$) per test', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.all(16)),
                  onPressed: () {
                     final price = double.tryParse(priceController.text) ?? 0.0;
                     ref.read(labInventoryProvider.notifier).cloneProduct(name, price, 999); // Labs usually have unlimited stock for normal tests
                     Navigator.pop(ctx);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Configuration imported successfully!'), backgroundColor: Colors.green));
                  },
                  child: const Text('Add to Local Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                labelColor: Colors.deepPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepPurple,
                tabs: const [Tab(text: 'Clinical Transfers'), Tab(text: 'Queue'), Tab(text: 'Inventory')], // Inventory acts as tests directory
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [ _buildTransfersTab(), _buildQueueTab(), _buildInventoryTab() ],
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
        color: Color(0xFF673AB7),
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
                  const Text('Diagnostic Lab Panel', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(widget.user.labProfile?.labName ?? 'Advanced Diagnostics', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const CircleAvatar(radius: 25, backgroundColor: Colors.white24, child: Icon(Icons.science, color: Colors.white, size: 28))
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernStat('Pending Tests', '14'),
              _buildModernStat('Reports', '125'),
              _buildModernStat('Equip', 'Normal'),
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

  Widget _buildTransfersTab() {
    final refs = ref.watch(labReferralsProvider).where((r) => r.status == 'awaiting_lab').toList();
    if (refs.isEmpty) return const Center(child: Text('No clinical transfers waiting.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: refs.length,
      itemBuilder: (ctx, i) {
         final r = refs[i];
         return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: [
                      const Icon(Icons.transfer_within_a_station, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Lab Request from ${r.transferredFrom}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                   ],
                 ),
                 const Divider(),
                 Text('Patient File: ${r.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                 const SizedBox(height: 8),
                 Container(
                   padding: const EdgeInsets.all(12),
                   width: double.infinity,
                   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                   child: Text(r.specialization, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple)), // holds requested tests mock string
                 ),
                 const SizedBox(height: 16),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                     onPressed: () {
                         ref.read(labReferralsProvider.notifier).resolveReferral(r.id);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tests Recorded. Report sent back to Doctor.')));
                     },
                     child: const Text('Return Tests to Doctor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   ),
                 )
              ],
            ),
         );
      }
    );
  }

  Widget _buildQueueTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
         const Text('Direct Appointments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
         const SizedBox(height: 12),
         _buildTestItem('Blood Work', '09:00 AM', 'Ready for Sample'),
         _buildTestItem('COVID-19 RT-PCR', '10:30 AM', 'Processing'),
      ],
    );
  }

  Widget _buildTestItem(String name, String time, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(status, style: TextStyle(color: status == 'Processing' ? Colors.orange : AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
     final inv = ref.watch(labInventoryProvider);
     
     return ListView(
       padding: const EdgeInsets.all(16),
       children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _showCloneTestSheet,
            icon: const Icon(Icons.cloud_download, color: Colors.white),
            label: const Text('Clone Test from Global System', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          const Text('Available Lab Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (inv.isEmpty) const Center(child: Text('No services configured.')) else ...inv.map((item) {
             return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.biotech, color: Colors.deepPurple)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                           const SizedBox(height: 4),
                           Text('\$${item['price'].toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                        ],
                      )
                    ),
                    Column(
                      children: [
                         Switch(
                           value: item['inStock'],
                           activeColor: Colors.green,
                           onChanged: (val) {
                              ref.read(labInventoryProvider.notifier).toggleStock(item['id'], val);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item["name"]} is now ${val ? "Available" : "Unavailable"}')));
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
