import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/healthcare/data/models/hospital_model.dart';
import 'package:afyalink/features/healthcare/data/repositories/healthcare_repository.dart';
import 'package:afyalink/features/healthcare/presentation/pages/hospital_detail_page.dart';
import 'package:afyalink/features/healthcare/presentation/widgets/hospital_card.dart';
import 'package:afyalink/features/healthcare/presentation/pages/doctors_page.dart';
import 'package:afyalink/features/healthcare/presentation/pages/pharmacies_page.dart';
import 'package:afyalink/features/healthcare/presentation/pages/labs_page.dart';
import 'package:afyalink/features/healthcare/presentation/pages/telemedicine_page.dart';
import 'package:afyalink/features/cart/presentation/providers/cart_provider.dart';
import 'package:afyalink/features/cart/presentation/pages/cart_page.dart';

final selectedHealthcareFilterProvider = StateProvider<String>((ref) => 'All');

class HealthcarePage extends ConsumerStatefulWidget {
  const HealthcarePage({super.key});

  @override
  ConsumerState<HealthcarePage> createState() => _HealthcarePageState();
}

class _HealthcarePageState extends ConsumerState<HealthcarePage> {
  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(selectedHealthcareFilterProvider);
    final hospitalsAsyncValue = ref.watch(hospitalsProvider((type: selectedFilter == 'All' ? null : selectedFilter, search: null)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthcare Services'),
        centerTitle: false,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final cartCount = ref.watch(cartProvider).items.length;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentTeal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search hospitals, clinics, etc.',
                      prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', selectedFilter == 'All'),
                      _buildFilterChip('Hospital', selectedFilter == 'Hospital'),
                      _buildFilterChip('Doctor', selectedFilter == 'Doctor'),
                      _buildFilterChip('Clinic', selectedFilter == 'Clinic'),
                      _buildFilterChip('Health Services', selectedFilter == 'Lab'),
                      _buildFilterChip('Pharmacy', selectedFilter == 'Pharmacy'),
                      _buildFilterChip('Telemedicine', selectedFilter == 'Telemedicine'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: hospitalsAsyncValue.when(
              data: (hospitals) {
                if (hospitals.isEmpty) {
                  return _buildMockResults();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = hospitals[index];
                    return HospitalCard(hospital: hospital);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildMockResults(), // Fallback to mock on error
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockResults() {
    final List<Hospital> mockHospitals = [
      Hospital(
        id: '1',
        name: 'Muhimbili National Hospital',
        slug: 'muhimbili',
        description: 'The largest and oldest referral hospital in Tanzania',
        city: 'Dar es Salaam',
        isActive: true,
      ),
      Hospital(
        id: '2',
        name: 'Aga Khan Hospital',
        slug: 'aga-khan',
        description: 'Private hospital with world-class facilities',
        city: 'Dar es Salaam',
        isActive: true,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: mockHospitals.length,
      itemBuilder: (context, index) {
        final hospital = mockHospitals[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => HospitalDetailPage(idOrSlug: hospital.slug)));
          },
          child: HospitalCard(hospital: hospital),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            if (label == 'Doctor') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsPage()));
            } else if (label == 'Pharmacy') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmaciesPage()));
            } else if (label == 'Health Services') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LabsPage()));
            } else if (label == 'Telemedicine') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage()));
            } else {
              ref.read(selectedHealthcareFilterProvider.notifier).state = label;
            }
          }
        },
        backgroundColor: AppTheme.surfaceWhite,
        selectedColor: AppTheme.primaryTeal.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryTeal,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryTeal : AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppTheme.primaryTeal : AppTheme.borderColor),
        ),
      ),
    );
  }
}
