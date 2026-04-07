import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/healthcare/data/repositories/healthcare_repository.dart';
import 'package:app/features/healthcare/presentation/widgets/hospital_card.dart';
import 'package:app/features/healthcare/presentation/pages/hospital_detail_page.dart';

class PharmaciesPage extends ConsumerStatefulWidget {
  const PharmaciesPage({super.key});

  @override
  ConsumerState<PharmaciesPage> createState() => _PharmaciesPageState();
}

class _PharmaciesPageState extends ConsumerState<PharmaciesPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final pharmaciesAsyncValue = ref.watch(hospitalsProvider((type: 'PHARMACY', search: null)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacies'),
      ),
      body: Column(
        children: [
          // Premium Header similar to Web
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryTeal, AppTheme.primaryTeal.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_pharmacy, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Find a Pharmacy',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Locate trusted pharmacies near you for all your medication needs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or city...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                filled: true,
                fillColor: AppTheme.surfaceWhite,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Results
          Expanded(
            child: pharmaciesAsyncValue.when(
              data: (pharmacies) {
                final filtered = pharmacies.where((p) => 
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (p.city?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                ).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No pharmacies found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final pharmacy = filtered[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => HospitalDetailPage(idOrSlug: pharmacy.slug)
                        ));
                      },
                      child: HospitalCard(hospital: pharmacy),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
