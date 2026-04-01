import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:app/features/home/presentation/widgets/dashboards/pharmacy_dashboard.dart';
import 'package:app/features/home/presentation/widgets/dashboards/lab_dashboard.dart';

class HospitalDashboard extends ConsumerStatefulWidget {
  final User user;
  const HospitalDashboard({super.key, required this.user});

  @override
  ConsumerState<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends ConsumerState<HospitalDashboard> with SingleTickerProviderStateMixin {
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
                labelColor: Colors.cyan.shade700,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.cyan.shade700,
                tabs: const [Tab(text: 'Clinical / Doctors'), Tab(text: 'Pharmacy Wing'), Tab(text: 'Laboratory Wing')],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [ _buildClinicalTab(), _buildPharmacyWingTab(), _buildLabWingTab() ],
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
        gradient: LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF06B6D4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                  Text('Hospital Superintendent', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${widget.user.fullName} Medical Center', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const CircleAvatar(radius: 25, backgroundColor: Colors.white24, child: Icon(Icons.business, color: Colors.white, size: 28))
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernStat('Admissions', '45'),
              _buildModernStat('Active Staff', '12'),
              _buildModernStat('Rating', '4.9 ★'),
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

  // --- 1. Clinical Tab (Merged from Doctor) ---
  Widget _buildClinicalTab() {
     final apptsAsync = ref.watch(doctorAppointmentsProvider);

     return apptsAsync.when(
       data: (appts) {
          if (appts.isEmpty) return const Center(child: Text('No active clinical schedules.'));
          return ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: appts.length,
             itemBuilder: (ctx, i) {
                final a = appts[i];
                final dateFormat = DateFormat('MMM d • h:mm a');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.cyan.shade50, child: const Icon(Icons.person, color: Colors.cyan)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.patientName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Assigned to: Dr. ${a.doctorName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                           Text(dateFormat.format(a.date), style: TextStyle(color: Colors.cyan.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                           const SizedBox(height: 4),
                           Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(a.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)))
                        ],
                      )
                    ],
                  ),
                );
             }
          );
       },
       loading: () => const Center(child: CircularProgressIndicator()),
       error: (e, s) => const Center(child: Text('Error loading clinical operations')),
     );
  }

  // --- 2. Pharmacy Tab (Merged from Pharmacy) ---
  Widget _buildPharmacyWingTab() {
      final orders = ref.watch(pharmacyOrdersProvider);
      if (orders.isEmpty) return const Center(child: Text('No orders waiting in retail pharmacy.'));

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
                   Text('Handling Pharmacist: Central Desk', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                   const SizedBox(height: 8),
                   Text(itemsStr, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
           );
        }
      );
  }

  // --- 3. Lab Tab (Merged from Lab) ---
  Widget _buildLabWingTab() {
      final refs = ref.watch(labReferralsProvider);
      if (refs.isEmpty) return const Center(child: Text('No tests lined up at diagnostics center.'));

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
                        const Icon(Icons.biotech, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Laboratory Request', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                     ],
                   ),
                   const Divider(),
                   Text('Target Patient File: ${r.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.all(12),
                     width: double.infinity,
                     decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                     child: Text(r.specialization, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple)), // holds requested tests mock string
                   ),
                ],
              ),
           );
        }
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
