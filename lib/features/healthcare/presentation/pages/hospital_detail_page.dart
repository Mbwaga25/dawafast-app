import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/healthcare/data/repositories/healthcare_repository.dart';
import 'package:app/features/healthcare/data/models/hospital_model.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/features/cart/presentation/providers/cart_provider.dart';
import 'package:app/features/cart/data/models/cart_model.dart';

class HospitalDetailPage extends ConsumerStatefulWidget {
  final String idOrSlug;

  const HospitalDetailPage({super.key, required this.idOrSlug});

  @override
  ConsumerState<HospitalDetailPage> createState() => _HospitalDetailPageState();
}

class _HospitalDetailPageState extends ConsumerState<HospitalDetailPage> with TickerProviderStateMixin {
  Position? _userPosition;
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (mounted) setState(() => _userPosition = pos);
  }

  @override
  Widget build(BuildContext context) {
    final hospitalAsync = ref.watch(hospitalDetailProvider(widget.idOrSlug));

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
    final bool isPharmacy = hospital.storeType == 'PHARMACY';
    final bool isLab = hospital.storeType == 'LAB';
    
    final List<Tab> tabs = [
      const Tab(text: 'Overview'),
      if (isPharmacy) const Tab(text: 'Medicines') else if (isLab) const Tab(text: 'Lab Tests') else const Tab(text: 'Doctors'),
      if (isLab) const Tab(text: 'Map View'),
      if (!isLab) const Tab(text: 'Units'),
    ];

    final TabController tabController = TabController(length: tabs.length, vsync: this);

    String? distanceStr;
    String? timeStr;
    if (_userPosition != null && hospital.latitude != null && hospital.longitude != null) {
      final dist = _locationService.calculateDistance(_userPosition!.latitude, _userPosition!.longitude, hospital.latitude!, hospital.longitude!);
      distanceStr = '${dist.toStringAsFixed(1)} km away';
      timeStr = _locationService.estimateTravelTime(dist);
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  isPharmacy ? 'lib/assets/images/medicine_category.png' : isLab ? 'lib/assets/images/lab_test_category.png' : 'lib/assets/images/medical_placeholder.png',
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
                    if (distanceStr != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.directions_car, color: AppTheme.accentBlue, size: 12),
                      const SizedBox(width: 4),
                      Text(timeStr!, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          delegate: _SliverAppBarDelegate(
            TabBar(
              controller: tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryBlue,
              tabs: tabs,
            ),
          ),
          pinned: true,
        ),
        SliverFillRemaining(
          child: TabBarView(
            controller: tabController,
            children: [
              _buildOverviewTab(hospital, distanceStr),
              if (isPharmacy) _buildMedicinesTab(hospital) else if (isLab) _buildLabTestsTab(hospital) else _buildDoctorsTab(hospital),
              if (isLab) _buildMapTab(hospital),
              if (!isLab) _buildUnitsTab(context, hospital),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(Hospital hospital, String? distanceStr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (distanceStr != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me, color: AppTheme.accentBlue),
                  const SizedBox(width: 12),
                  Text(distanceStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            hospital.description ?? 'This medical facility provides comprehensive healthcare services, supported by professional staff and modern equipment. We are committed to providing the best patient care in the region.',
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Text('Services Offered', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if ((hospital.services == null || hospital.services!.isEmpty))
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
            child: const Text('Get Directions'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMedicinesTab(Hospital hospital) {
    final products = hospital.products ?? [];
    if (products.isEmpty) {
      return const Center(child: Text('No medicines available in this pharmacy'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Expanded(child: ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(p.images.first, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.medication)))),
               Padding(
                 padding: const EdgeInsets.all(8.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(p.name, style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                     Text('Tsh ${p.price}', style: TextStyle(color: AppTheme.primaryBlue)),
                     IconButton(icon: Icon(Icons.add_shopping_cart, size: 18), onPressed: () {
                         ref.read(cartProvider.notifier).addItem(CartItem(productId: p.id, name: p.name, price: p.price, image: p.images.isNotEmpty ? p.images.first : null));
                     })
                   ],
                 ),
               )
             ],
           ),
        );
      },
    );
  }

  Widget _buildLabTestsTab(Hospital hospital) {
    final tests = hospital.labTests ?? [];
    if (tests.isEmpty) return const Center(child: Text('No lab tests listed'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final t = tests[index];
        return Card(
          child: ListTile(
            title: Text(t.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(t.sampleType ?? 'Sample required'),
            trailing: Text('Tsh ${t.price}', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildMapTab(Hospital hospital) {
    if (hospital.latitude == null || hospital.longitude == null) {
      return const Center(child: Text('Coordinates not available for this lab'));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: LatLng(hospital.latitude!, hospital.longitude!), zoom: 14),
      markers: {
        Marker(markerId: MarkerId('lab'), position: LatLng(hospital.latitude!, hospital.longitude!), infoWindow: InfoWindow(title: hospital.name)),
        if (_userPosition != null) Marker(markerId: MarkerId('me'), position: LatLng(_userPosition!.latitude, _userPosition!.longitude), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
      },
      myLocationEnabled: true,
      zoomControlsEnabled: false,
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
