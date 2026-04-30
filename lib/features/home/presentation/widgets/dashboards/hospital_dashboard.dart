import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:afyalink/features/auth/data/models/user_model.dart';
import 'package:afyalink/features/appointments/data/repositories/appointment_repository.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/pharmacy_dashboard.dart' as pharmacy;
import 'package:afyalink/features/home/presentation/widgets/dashboards/lab_dashboard.dart' as lab;

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
                labelColor: AppTheme.primaryTeal,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: AppTheme.primaryTeal,
                tabs: const [
                  Tab(text: 'Clinical Ops'),
                  Tab(text: 'Pharmacy Wing'),
                  Tab(text: 'Lab Diagnostics'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClinicalTab(),
                _buildPharmacyWingTab(),
                _buildLabWingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryTeal, Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
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
                  Text('Hospital Administration', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(widget.user.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.apartment_rounded, color: Colors.white, size: 32))
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip('Active Doctors', '24', Icons.people_alt),
              _buildStatChip('Bed Capacity', '85%', Icons.bed_rounded),
              _buildStatChip('Daily Income', '120k', Icons.payments_rounded),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildClinicalTab() {
     final apptsAsync = ref.watch(doctorAppointmentsProvider);
     return apptsAsync.when(
       data: (appts) => ListView.builder(
         padding: const EdgeInsets.all(20),
         itemCount: appts.length,
         itemBuilder: (ctx, i) {
           final a = appts[i];
           return Container(
             margin: const EdgeInsets.only(bottom: 16),
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5))),
             child: Row(
               children: [
                 CircleAvatar(backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1), child: const Icon(Icons.person, color: AppTheme.primaryTeal)),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(a.patientName ?? 'Unknown Patient', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                       Text('Physician: Dr. ${a.doctorName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                     ],
                   ),
                 ),
                 Text(DateFormat('HH:mm').format(a.date), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
               ],
             ),
           );
         },
       ),
       loading: () => const Center(child: CircularProgressIndicator()),
       error: (e, s) => Center(child: Text('Error: $e')),
     );
  }

  Widget _buildPharmacyWingTab() {
      final ordersAsync = ref.watch(pharmacy.pharmacyOrdersProvider(widget.user.id.toString()));
      return ordersAsync.when(
        data: (orders) => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            final o = orders[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RX Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                      _buildStatusTag(o.status),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(o.clientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(o.items.map((it) => it.productName).join(', '), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      );
  }

  Widget _buildLabWingTab() {
      final refs = ref.watch(lab.labReferralsProvider);
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: refs.length,
        itemBuilder: (ctx, i) {
          final r = refs[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.biotech_rounded, color: AppTheme.primaryTeal, size: 20),
                    const SizedBox(width: 8),
                    Text('Diagnostic Request', style: TextStyle(color: AppTheme.primaryTeal.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(r.patientName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(r.specialization, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          );
        },
      );
  }

  Widget _buildStatusTag(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase().contains('proc') || status.toLowerCase().contains('ready')) color = Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppTheme.surfaceWhite, child: tabBar);
  }
  @override bool shouldRebuild(_StickyTabBarDelegate oldDelegate) { return tabBar != oldDelegate.tabBar; }
}
