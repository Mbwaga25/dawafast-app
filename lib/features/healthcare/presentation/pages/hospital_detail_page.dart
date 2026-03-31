import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/healthcare/data/repositories/healthcare_repository.dart';
import 'package:app/features/healthcare/data/models/hospital_model.dart';

class HospitalDetailPage extends ConsumerWidget {
  final String idOrSlug;

  const HospitalDetailPage({super.key, required this.idOrSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalAsync = ref.watch(hospitalDetailProvider(idOrSlug));

    return Scaffold(
      body: hospitalAsync.when(
        data: (hospital) {
          if (hospital == null) return const Center(child: Text('Hospital not found'));
          return _buildHospitalContent(context, hospital);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHospitalContent(BuildContext context, Hospital hospital) {
    return DefaultTabController(
      length: 3,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'lib/assets/images/medical_placeholder.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hospital.name, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.accentBlue, size: 12),
                      const SizedBox(width: 4),
                      Text(hospital.city ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryBlue,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Doctors'),
                  Tab(text: 'Units'),
                ],
              ),
            ),
            pinned: true,
          ),
          SliverFillRemaining(
            child: TabBarView(
              children: [
                _buildOverviewTab(hospital),
                _buildDoctorsTab(hospital),
                _buildUnitsTab(context, hospital),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Hospital hospital) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            hospital.description ?? 'This medical facility provides comprehensive healthcare services, supported by professional staff and modern equipment. We are committed to providing the best patient care in the region.',
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Text('Services Offered', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (hospital.services == null || hospital.services!.isEmpty)
             const Text('Standard Medical Consultations, Emergency Care, Diagnostic Services.', style: TextStyle(color: AppTheme.textSecondary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hospital.services!.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s.name, style: const TextStyle(fontSize: 12)),
              )).toList(),
            ),
          const SizedBox(height: 32),
          const Text('Contact & Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildContactTile(Icons.phone, hospital.phoneNumber ?? 'Not available'),
          _buildContactTile(Icons.access_time, 'Open 24/7'),
          _buildContactTile(Icons.map, hospital.address ?? hospital.city ?? 'Location not specified'),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            child: const Text('Book Appointment'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            child: const Text('Call Facility'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDoctorsTab(Hospital hospital) {
    final doctors = hospital.doctors ?? [];
    if (doctors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: AppTheme.borderColor),
            SizedBox(height: 16),
            Text('No doctors listed for this facility', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.borderColor)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: const Icon(Icons.person, color: AppTheme.primaryBlue),
            ),
            title: Text(doctor.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(doctor.specialty),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildUnitsTab(BuildContext context, Hospital hospital) {
    final units = hospital.children ?? [];
    if (units.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: AppTheme.borderColor),
            SizedBox(height: 16),
            Text('No sub-units (Labs/Pharmacies) available', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.borderColor)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(
                unit.storeType == 'LAB' ? Icons.biotech : Icons.local_pharmacy,
                color: AppTheme.accentBlue,
              ),
            ),
            title: Text(unit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(unit.storeType?.replaceAll('_', ' ') ?? 'Medical Center'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => HospitalDetailPage(idOrSlug: unit.slug)));
            },
          ),
        );
      },
    );
  }

  Widget _buildContactTile(IconData icon, String? text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 16),
          Text(text ?? 'N/A', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
